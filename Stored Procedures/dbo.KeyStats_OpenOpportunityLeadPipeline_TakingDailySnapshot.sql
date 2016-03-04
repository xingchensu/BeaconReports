SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ruonan
-- Create date: 12/2/2015
-- Description:	sp to taking snap shot of open opportunity, daily
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_OpenOpportunityLeadPipeline_TakingDailySnapshot] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @cbdate as DATETIME
	set @cbdate =DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),  '01/20/2012')  
    
IF OBJECT_ID('TEMPDB..#InsideSales') IS NOT NULL
BEGIN
  DROP TABLE #InsideSales
END

SELECT
  su.SystemUserId AS guid,
  su.fullname INTO #InsideSales
FROM CRMReplication2013.dbo.systemuser su
INNER JOIN CRMReplication2013.dbo.SystemUserRoles sur
  ON su.SystemUserId = sur.SystemUserId
WHERE sur.RoleId = 'ED4FDE05-3337-E111-98DF-78E7D1F817F8'

--oppty
 IF OBJECT_ID('TEMPDB..#otvExcluded') IS NOT NULL
    BEGIN
      DROP TABLE #otvExcluded
    END

    SELECT
      New_opportunitytermid,
      SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(new_equipmentsoftcosts, 0)) AS GrossDueToVendor,
      SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS NetDueToVendor 
      INTO #otvExcluded
    FROM CRMReplication2013.dbo.New_opportunitytermvendor
    WHERE New_isuserselected = 1
    AND New_opportunitytermid IS NOT NULL
    AND (New_AccountIdName IN (SELECT
      ExcludedVendorName COLLATE SQL_Latin1_General_CP1_CI_AS
    FROM CRMReplication2013.dbo.XCelsius_ExcludedVendors)
    )
    GROUP BY New_opportunitytermid
    
    
IF OBJECT_ID('TEMPDB..#ocSoftCosts') IS NOT NULL
BEGIN
  DROP TABLE #ocSoftCosts
END
SELECT
  SUM(Amount) AS Amount,
  OpportunityContactID AS oppcid
  into #ocSoftCosts
FROM CRMReplication2013.dbo.AppBuilder_OpportunityContact_SoftCost
GROUP BY OpportunityContactID

IF OBJECT_ID('TEMPDB..#ocExcluded') IS NOT NULL
BEGIN
  DROP TABLE #ocExcluded
END
SELECT
  New_OppContactId,
  SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(Amount, 0)) AS GrossDueToVendor,
  SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS VendorTotalEquipmentCost
  into #ocExcluded
FROM CRMReplication2013.dbo.New_OpportunityContact noc
LEFT JOIN #ocSoftCosts ocsc
  ON noc.New_OpportunityContactId = ocsc.oppcid
WHERE New_Relationship = 2
AND (New_AccountIdName IN (SELECT
  ExcludedVendorName
FROM CRMReplication2013.dbo.XCelsius_ExcludedVendors)
)
GROUP BY New_OppContactId


IF OBJECT_ID('TEMPDB..#otCTE_temp') IS NOT NULL
BEGIN
  DROP TABLE #otCTE_temp
END;

WITH otCTE
AS (SELECT
  ot.new_opportunityid AS oppid,
  ot.NEW_OPPORTUNITYTERMID,
  ot.NEW_termname,
  ot.new_originatedtermid,
  ot.new_isinlcw,
  0 AS distance
FROM CRMReplication2013.dbo.NEW_OPPORTUNITYTERM ot WITH (NOLOCK)
WHERE ot.new_isinlcw = 1 --and ot.NEW_OPPORTUNITYTERMID=@tid
UNION ALL
SELECT
  oto.new_opportunityid AS oppid,
  oto.NEW_OPPORTUNITYTERMID,
  oto.NEW_termname,
  oto.new_originatedtermid,
  oto.new_isinlcw,
  ott.distance + 1 AS distance
FROM otCTE AS ott
JOIN CRMReplication2013.dbo.NEW_OPPORTUNITYTERM AS oto WITH (NOLOCK)
  ON ott.new_originatedtermid = oto.NEW_OPPORTUNITYTERMID)
SELECT
  * INTO #otCTE_temp
FROM (SELECT
  oppid,

  ROW_NUMBER() OVER (PARTITION BY oppid ORDER BY creditdecisionLevel, distance, createdon DESC) AS rank,
  new_creditmanageridname,new_creditmanagerid
FROM otCTE t
INNER JOIN (SELECT
  NEW_OPPORTUNITYTERMID,
  new_creditdecision,
  createdon,
  CASE
    WHEN new_creditdecision = N'ok to sell' THEN 0
    ELSE 1
  END AS creditdecisionLevel,
  new_creditmanageridname,new_creditmanagerid
FROM CRMReplication2013.dbo.new_opportunitytermcredit
WHERE new_fundingsourceid IS NULL
AND new_creditmanagerid IS NOT NULL
AND new_creditmanageridname NOT IN (N'Baratta, Jon', N'Admin, CRM')) c
  ON t.NEW_OPPORTUNITYTERMID = c.NEW_OPPORTUNITYTERMID) r
WHERE rank = 1;

WITH Docusign
AS (SELECT
  Opp.OPPORTUNITYID
FROM CRMReplication2013.dbo.new_documentation doc
INNER JOIN CRMReplication2013.dbo.new_documentationdocusign dd
  ON doc.new_documentationid = dd.new_documentationid
INNER JOIN CRMReplication2013.dbo.Opportunity opp
  ON opp.OpportunityId = doc.New_OpportunityId
WHERE dd.new_envelopestatuscode = 3
AND dd.new_actionbyid = opp.New_LeaseAdministratorId
AND dd.New_LogType = 1--docusign
),
TitledAsset
AS (SELECT
  o.opportunityid,
  COUNT(otva.New_opportunitytermvendorassetid) AS NoOfTitiledAssets
FROM CRMReplication2013.dbo.opportunity o
INNER JOIN CRMReplication2013.dbo.New_OpportunityTerm ot
  ON o.opportunityid = ot.new_opportunityid
INNER JOIN CRMReplication2013.dbo.New_OpportunityTermVendor otv
  ON otv.New_OpportunityTermId = ot.New_OpportunityTermId
INNER JOIN CRMReplication2013.dbo.New_opportunitytermvendorasset otva
  ON otv.New_opportunitytermvendorId = otva.New_OpportunityTermVendorId
WHERE otv.statecode = 0
AND otv.new_isuserselected = 1
AND otva.New_AssetType = 1
GROUP BY o.opportunityid)

insert into KeyStats_OpenOpportunityPipeline_DailySnapshot
([new_appid]
      ,[OpportunityId]
      ,[SnapshotDate]
      ,[salesstagecode]
      ,[statuscode]
      ,fundingmethodvalue
      ,consultantId
      ,[owneridname]
      ,[CreditManager],CreditManagerID
      ,[LeaseAmount]
      ,[insideSales]
      ,[insideSalesId]
      ,[New_LeaseAdministratorId]
      ,[New_LeaseAdministratorIdName]
      ,[contracttype]
      ,[isDocusigned]
      ,[isTitled]
      ,acceptanceDate)
SELECT
  new_appid,
  o.OpportunityId,
   dateadd(day,-1,getdate()) as [SnapshotDate],
  o.salesstagecode,
  o.statuscode,
  new_fundingmethod,
  ownerid,
  owneridname,
  cm.new_creditmanageridname AS CreditManager,   
    cm.new_creditmanagerid AS CreditManagerID,   
  case when o.createdon>=@cbdate then  ot.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) 
  else  ISNULL(o.CFCLeaseAmount, 0) - ISNULL(ocE.VendorTotalEquipmentCost, 0) 
  end AS LeaseAmount,    
  CASE
    WHEN iso.guid IS NOT NULL THEN iso.fullname
    ELSE CASE
        WHEN issc1.guid IS NOT NULL THEN issc1.fullname
        ELSE CASE
            WHEN issc2.guid IS NOT NULL THEN issc2.fullname
            ELSE CASE
                WHEN issc3.guid IS NOT NULL THEN issc3.fullname
                ELSE CASE
                    WHEN issc4.guid IS NOT NULL THEN issc4.fullname
                    ELSE CASE
                        WHEN issc5.guid IS NOT NULL THEN issc5.fullname
                        ELSE NULL
                      END
                  END
              END
          END
      END
  END
  AS insideSales,
  CASE
    WHEN iso.guid IS NOT NULL THEN iso.guid
    ELSE CASE
        WHEN issc1.guid IS NOT NULL THEN issc1.guid
        ELSE CASE
            WHEN issc2.guid IS NOT NULL THEN issc2.guid
            ELSE CASE
                WHEN issc3.guid IS NOT NULL THEN issc3.guid
                ELSE CASE
                    WHEN issc4.guid IS NOT NULL THEN issc4.guid
                    ELSE CASE
                        WHEN issc5.guid IS NOT NULL THEN issc5.guid
                        ELSE NULL
                      END
                  END
              END
          END
      END
  END
  AS insideSalesId,
  o.New_LeaseAdministratorId,
  o.New_LeaseAdministratorIdName
  ,
  ot.new_contracttype,
  CASE
    WHEN Docusign.OPPORTUNITYID IS NULL THEN 0
    ELSE 1
  END AS isDocusigned,
  CASE
    WHEN TitledAsset.OPPORTUNITYID IS NULL THEN 0
    ELSE 1
  END AS isTitled
  ,
  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),  CFDEquipmentAcceptDate)   as acceptanceDate
FROM CRMReplication2013.dbo.Opportunity o
LEFT JOIN (SELECT
  New_OpportunityId,new_opportunitytermid,
  New_AmountFinanced,
  new_fundingmethod,
  new_contracttype
FROM CRMReplication2013.dbo.New_OpportunityTerm
WHERE New_IsInLCW = 1) ot
  ON o.OpportunityId = ot.New_OpportunityId
LEFT JOIN #otCTE_temp cm
  ON cm.oppid = o.OpportunityId

LEFT JOIN #InsideSales iso
  ON o.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON o.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON o.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON o.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON o.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON o.new_sharecredit5id = issc5.guid
LEFT JOIN Docusign
  ON Docusign.OPPORTUNITYID = o.opportunityid
LEFT JOIN TitledAsset
  ON TitledAsset.OPPORTUNITYID = o.opportunityid
    LEFT JOIN #otvExcluded otvE
      ON otvE.New_opportunitytermid = ot.new_opportunitytermid
      LEFT JOIN #ocExcluded ocE
    ON o.opportunityid = ocE.New_OppContactId
WHERE o.StateCode = 0

--lead
insert into  KeyStats_OpenLeadPipeline_DailySnapshot
([leadid]
      ,[SnapshotDate]
      ,[EquipmentCost]
      ,[consultantid]
      ,[insideSales]
      ,[insideSalesId])
SELECT
 -- createdon,
  leadid,
  dateadd(day,-1,getdate()) as [SnapshotDate],
  CFCEstimatedEquipCost AS [EquipmentCost],
  ownerid,
  CASE
    WHEN iso.guid IS NOT NULL THEN iso.fullname
    ELSE CASE
        WHEN issc1.guid IS NOT NULL THEN issc1.fullname
        ELSE CASE
            WHEN issc2.guid IS NOT NULL THEN issc2.fullname
            ELSE CASE
                WHEN issc3.guid IS NOT NULL THEN issc3.fullname
                ELSE CASE
                    WHEN issc4.guid IS NOT NULL THEN issc4.fullname
                    ELSE CASE
                        WHEN issc5.guid IS NOT NULL THEN issc5.fullname
                        ELSE NULL
                      END
                  END
              END
          END
      END
  END
  AS insideSales,
  CASE
    WHEN iso.guid IS NOT NULL THEN iso.guid
    ELSE CASE
        WHEN issc1.guid IS NOT NULL THEN issc1.guid
        ELSE CASE
            WHEN issc2.guid IS NOT NULL THEN issc2.guid
            ELSE CASE
                WHEN issc3.guid IS NOT NULL THEN issc3.guid
                ELSE CASE
                    WHEN issc4.guid IS NOT NULL THEN issc4.guid
                    ELSE CASE
                        WHEN issc5.guid IS NOT NULL THEN issc5.guid
                        ELSE NULL
                      END
                  END
              END
          END
      END
  END
  AS insideSalesId
   --into KeyStats_OpenLeadPipeline_DailySnapshot
FROM CRMReplication2013.dbo.lead l
LEFT JOIN #InsideSales iso
  ON l.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON l.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON l.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON l.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON l.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON l.new_sharecredit5id = issc5.guid
WHERE StateCode = 0
END

GO
