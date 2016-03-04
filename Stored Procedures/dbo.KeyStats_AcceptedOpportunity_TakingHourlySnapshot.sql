SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:    Ruonan Wen
-- Create date: 11/30/2015
-- Description:  load key sales status details
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_AcceptedOpportunity_TakingHourlySnapshot]
AS
BEGIN
  DECLARE @dateFrom AS datetime
  SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), '1/1/2006')  
  DECLARE @cbdate AS DATETIME
  SET @cbdate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), '01/20/2012')  	
 
 
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


  IF OBJECT_ID('TEMPDB..#LPTABLE') IS NOT NULL
  BEGIN
    DROP TABLE #LPTABLE
  END
  SELECT
    LeaseUser.LeaseUserPercent1,
    LeaseAux.LeaseYield,
    LeaseDatabase.LeaseNum,
    leaseuseramt6 INTO #LPTABLE
  FROM (LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseDatabase LeaseDatabase
  INNER JOIN LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseUser LeaseUser
    ON (LeaseDatabase.LeaseCompanyNum = LeaseUser.LeaseUserCompanyNum)
    AND (LeaseDatabase.LeaseNum = LeaseUser.LeaseUserLeaseNum))
  INNER JOIN LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseAux LeaseAux
    ON (LeaseDatabase.LeaseCompanyNum = LeaseAux.LeaseAuxCompanyNum)
    AND (LeaseDatabase.LeaseNum = LeaseAux.LeaseAuxLeaseNum)
  WHERE LeaseDatabase.LeasePostedSw = 'Y'


  IF OBJECT_ID('TEMPDB..#otv') IS NOT NULL
  BEGIN
    DROP TABLE #otv
  END
  SELECT
    New_opportunitytermid,
    SUM(ISNULL(New_EquipmentCost, 0)) AS EquipmentCost,
    SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(new_equipmentsoftcosts, 0)) AS GrossDueToVendor
    ,sum(case when otva.New_AssetType=1 then 1 else 0 end) as NoOfTitiledAssets
     INTO #otv    
  FROM CRMReplication2013.dbo.New_opportunitytermvendor otv
  left JOIN CRMReplication2013.dbo.New_opportunitytermvendorasset otva
  ON otv.New_opportunitytermvendorId = otva.New_OpportunityTermVendorId  
  WHERE New_isuserselected = 1
  --AND New_opportunitytermid IS NOT NULL
  GROUP BY New_opportunitytermid



  IF OBJECT_ID('TEMPDB..#otvExcluded') IS NOT NULL
  BEGIN
    DROP TABLE #otvExcluded
  END

  SELECT
    New_opportunitytermid,
    SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(new_equipmentsoftcosts, 0)) AS GrossDueToVendor,
    SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS NetDueToVendor INTO #otvExcluded
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
    OpportunityContactID AS oppcid INTO #ocSoftCosts
  FROM CRMReplication2013.dbo.AppBuilder_OpportunityContact_SoftCost
  GROUP BY OpportunityContactID

  IF OBJECT_ID('TEMPDB..#ocExcluded') IS NOT NULL
  BEGIN
    DROP TABLE #ocExcluded
  END
  SELECT
    New_OppContactId,
    SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(Amount, 0)) AS GrossDueToVendor,
    SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS VendorTotalEquipmentCost INTO #ocExcluded
  FROM CRMReplication2013.dbo.New_OpportunityContact noc
  LEFT JOIN #ocSoftCosts ocsc
    ON noc.New_OpportunityContactId = ocsc.oppcid
  WHERE New_Relationship = 2
  AND (New_AccountIdName IN (SELECT
    ExcludedVendorName
  FROM CRMReplication2013.dbo.XCelsius_ExcludedVendors)
  )
  GROUP BY New_OppContactId


  IF OBJECT_ID('TEMPDB..#oc') IS NOT NULL
  BEGIN
    DROP TABLE #oc
  END
  SELECT
    New_OppContactId,
    SUM(ISNULL(New_EquipmentCost, 0)) AS EquipmentCost,
    SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(Amount, 0)) AS GrossDueToVendor,
    SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS NetDueToVendor INTO #oc
  FROM CRMReplication2013.dbo.New_OpportunityContact noc
  LEFT JOIN #ocSoftCosts ocsc
    ON noc.New_OpportunityContactId = ocsc.oppcid
  WHERE New_Relationship = 2
  GROUP BY New_OppContactId

  IF OBJECT_ID('TEMPDB..#rc') IS NOT NULL
  BEGIN
    DROP TABLE #rc
  END
  SELECT
    a.accountid,
    COUNT(leasecustidnum) AS NoOfLeasesWithBeacon INTO #rc
  FROM LINK_LEASEPLUS.LeasePlusv3.dbo.leasedatabase ld
  LEFT JOIN CRMReplication2013.dbo.account a
    ON ld.leasecustidnum = a.accountnumber
  WHERE a.statecode = 0
  GROUP BY leasecustidnum,
           a.accountid
  HAVING COUNT(leasecustidnum) > 1

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
    new_creditmanageridname,
    new_creditmanagerid
  FROM otCTE t
  INNER JOIN (SELECT
    NEW_OPPORTUNITYTERMID,
    new_creditdecision,
    createdon,
    CASE
      WHEN new_creditdecision = N'ok to sell' THEN 0
      ELSE 1
    END AS creditdecisionLevel,
    new_creditmanageridname,
    new_creditmanagerid
  FROM CRMReplication2013.dbo.new_opportunitytermcredit
  WHERE new_fundingsourceid IS NULL
  AND new_creditmanagerid IS NOT NULL
  AND new_creditmanageridname NOT IN (N'Baratta, Jon', N'Admin, CRM')) c
    ON t.NEW_OPPORTUNITYTERMID = c.NEW_OPPORTUNITYTERMID) r
  WHERE rank = 1

 

 IF OBJECT_ID('TEMPDB..#Docusign') IS NOT NULL
  BEGIN
    DROP TABLE #Docusign
  END
SELECT distinct
  Opp.OPPORTUNITYID,sm.value
  into #Docusign
FROM CRMReplication2013.dbo.new_documentation doc
INNER JOIN CRMReplication2013.dbo.new_documentationdocusign dd
  ON doc.new_documentationid = dd.new_documentationid
INNER JOIN CRMReplication2013.dbo.Opportunity opp
  ON opp.OpportunityId = doc.New_OpportunityId
  left JOIN CRMReplication2013.dbo.StringMap sm 
  ON sm.AttributeValue = dd.New_LogType 
  AND ObjectTypeCode=10050 AND AttributeName = 'New_LogType'
  
   IF OBJECT_ID('TEMPDB..#Distributionmethod') IS NOT NULL
  BEGIN
    DROP TABLE #Distributionmethod
  END
  SELECT ds2.opportunityID, STUFF(
(SELECT ', ' + ds1.value
FROM #Docusign ds1
WHERE ds1.opportunityID = ds2.opportunityID
FOR XML PATH('')),1,1,'') AS CSV
into #Distributionmethod
FROM #Docusign AS ds2
GROUP BY ds2.opportunityID 
	
	
	  IF OBJECT_ID('TEMPDB..#Manualdocs') IS NOT NULL
  BEGIN
    DROP TABLE #Manualdocs
  END
  	
				SELECT		d.New_OpportunityId AS OpportunityId,COUNT(CASE WHEN sld.New_AddedByUser = 1 AND sld.New_IsInVisualRules = 1 THEN 1 END) AS NoOfDocsAddedButinVisualRules,
							COUNT(CASE WHEN sld.New_AddedByUser = 1 AND (sld.New_IsInVisualRules IS NULL or sld.New_IsInVisualRules = 0) THEN 1 END) AS NoOfDocsAdded,
							COUNT(CASE WHEN sld.New_IsInPkg IS NULL OR sld.New_IsInPkg  = 0 THEN 1 END) AS NoOfDocsRemoved			
							into #Manualdocs			
				FROM		CRMReplication2013.dbo.New_selectedleasedocument sld
				INNER JOIN	CRMReplication2013.dbo.new_documentation d ON sld.New_DocumentationId = d.New_documentationId
				INNER JOIN	CRMReplication2013.dbo.Opportunity o ON o.OpportunityId = d.New_OpportunityId
				GROUP BY	d.New_OpportunityId
	
		
  
   IF OBJECT_ID('TEMPDB..#DocusignLCW') IS NOT NULL
  BEGIN
    DROP TABLE #DocusignLCW
  END
  
  	SELECT		o.OpportunityId,COUNT(DISTINCT dd.New_documentationdocusignId) AS NoOfEnvelopesSent,MIN(dd.CreatedOn) AS DocsSent
			INTO #DocusignLCW
			FROM		CRMReplication2013.dbo.new_documentation doc
			INNER JOIN	CRMReplication2013.dbo.new_documentationdocusign dd On doc.new_documentationid = dd.new_documentationid
			INNER JOIN	CRMReplication2013.dbo.Opportunity o ON o.OpportunityId = doc.New_OpportunityId
			INNER JOIN	CRMReplication2013.dbo.New_opportunityterm ot ON ot.New_OpportunityId = doc.New_OpportunityId  
							AND ot.New_termname=dd.New_TermName
			Where		dd.new_envelopestatuscode = 3 AND ot.New_IsInLCW=1 
			GROUP BY	o.OpportunityId 
  
   IF OBJECT_ID('TEMPDB..#DocsPendingDate') IS NOT NULL
  BEGIN
    DROP TABLE #DocsPendingDate
  END
  

	SELECT		ot.New_opportunityId, MAX(otc.CreatedOn) AS DocsPendingDate
	INTO #DocsPendingDate
			FROM		CRMReplication2013.dbo.New_opportunitytermcredit otc
			INNER JOIN	CRMReplication2013.dbo.New_OpportunityTerm ot ON ot.New_opportunitytermId = otc.New_OpportunityTermId
			WHERE		otc.New_CreditDecision='Submit To Documentation' 
			
			GROUP BY	ot.New_opportunityId
		
		
		 IF OBJECT_ID('TEMPDB..#InitialPurchaseOrderDate') IS NOT NULL
  BEGIN
    DROP TABLE #InitialPurchaseOrderDate
  END
  
			SELECT		 MIN(dd.CreatedOn) AS InitialPurchaseOrderDate,o.OpportunityId
			INTO #InitialPurchaseOrderDate
			FROM		CRMReplication2013.dbo.Opportunity o 
			INNER JOIN	CRMReplication2013.dbo.new_documentation d ON o.OpportunityId = d.New_OpportunityId
			INNER JOIN	CRMReplication2013.dbo.New_selectedleasedocument sld ON sld.New_DocumentationId = d.New_documentationId
			LEFT JOIN	CRMReplication2013.dbo.new_opportunitytermvendorprefunding otvp ON sld.New_OpportunityTermVendorPrefundingId = otvp.New_opportunitytermvendorprefundingId
			INNER JOIN	CRMReplication2013.dbo.New_documentationdocusign dd ON d.New_documentationId = dd.New_DocumentationId
								AND dd.New_documentationdocusignId = sld.New_DocumentationDocuSignId			
			INNER JOIN	CRMReplication2013.dbo.New_leasedocuments ld ON sld.New_LeaseDocumentsId = ld.New_leasedocumentsId				 
			WHERE		ld.New_documentnameforvisualrules IN (8,21) AND dd.New_EnvelopeStatusCode=3			
			GROUP BY	OpportunityId,o.New_AppID		
	
	
 IF OBJECT_ID('TEMPDB..#tempsalesdetails') IS NOT NULL
  BEGIN
    DROP TABLE #tempsalesdetails
  END
  SELECT
	o.new_appid as Appid,
    o.Name AS name,
    o.OpportunityId AS opid,
    o.OwnerIdName AS consultant,
    o.OwnerId AS consultantId,
    o.AccountIdName AS companyName,
    o.CFDEquipmentAcceptDate AS acceptanceDate,
  
    CASE
      WHEN o.createdon >= @cbdate THEN ISNULL(t.new_amountfinanced, 0) - ISNULL(otvE.NetDueToVendor, 0)
      ELSE ISNULL(o.CFCLeaseAmount, 0) - ISNULL(ocE.VendorTotalEquipmentCost, 0)
    END AS leaseAmt,

    --portfolio/oneoff/inside(%)
    CASE
      WHEN o.createdon >= @cbdate THEN t.new_fundingmethod
      ELSE CASE
          WHEN o.CFPFundingSource IS NULL OR
            o.CFPFundingSource = 2 THEN 1
          ELSE 2
        END
    END AS FundingMethodValue,
    CASE
      WHEN o.createdon >= @cbdate THEN ISNULL(t.new_accountidname, 'Portfolio')
      ELSE CASE
          WHEN o.CFPFundingSource IS NULL OR
            o.CFPFundingSource = 2 THEN 'Portfolio'
          ELSE REPLACE(sm_CFPFundingSource.value, 'One Off - ', '') COLLATE DATABASE_DEFAULT
        END
    END AS FundingMethod,

    --CASE
    --  WHEN t.new_fundingmethod = 1 THEN t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0)
    --  ELSE 0
    --END AS PortfolioleaseAmt,
    --CASE
    --  WHEN t.new_fundingmethod = 2 THEN t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0)
    --  ELSE 0
    --END AS OneOffleaseAmt,

    --initial cash 
    CASE
      WHEN o.createdon >= @cbdate THEN (ISNULL(t.new_bfcdownpayment, 0) + ISNULL(t.new_documentationfee, 0) + ISNULL(t.New_SecurityDeposit, 0)
        + (SELECT TOP 1
          p.new_payment
        FROM CRMReplication2013.dbo.new_opportunitytermpayment p
        WHERE p.new_opportunitytermid = t.new_opportunitytermid
        ORDER BY p.new_term DESC)
        * apts.firstTerm + (SELECT TOP 1
          p.new_payment
        FROM CRMReplication2013.dbo.new_opportunitytermpayment p
        WHERE p.new_opportunitytermid = t.new_opportunitytermid
        ORDER BY p.new_term DESC)
        * apts.lastterm)
      ELSE (ISNULL(o.CFCDownpaymentBFC, 0) + ISNULL(sm_CFPDocFee.docfee, 0) + ISNULL(o.CFCSecurityDeposit, 0)
        + (CASE
          WHEN o.CFCMonthlyPayment IS NULL OR
            o.CFCMonthlyPayment = 0 THEN o.CFCMonthlyPayment2
          ELSE o.CFCMonthlyPayment
        END)
        * sm_CFPAdvancePaymentDesc.firstTerm + (CASE
          WHEN o.CFCMonthlyPayment IS NULL OR
            o.CFCMonthlyPayment = 0 THEN o.CFCMonthlyPayment2
          ELSE o.CFCMonthlyPayment
        END)
        * sm_CFPAdvancePaymentDesc.lastterm)

    END AS initialCash,


    CASE
      WHEN o.createdon >= @cbdate THEN t.new_netduetovendor
      ELSE oc.NetDueToVendor
    END AS NetVendorAmount,

    CASE
      WHEN o.createdon >= @cbdate THEN t.New_SecurityDeposit
      ELSE o.CFCSecurityDeposit
    END AS securityDeposit,
    CASE
      WHEN o.createdon >= @cbdate THEN (SELECT TOP 1
          p.new_payment
        FROM CRMReplication2013.dbo.new_opportunitytermpayment p
        WHERE p.new_opportunitytermid = t.new_opportunitytermid
        ORDER BY p.new_term DESC)

      ELSE (CASE
          WHEN o.CFCMonthlyPayment IS NULL OR
            o.CFCMonthlyPayment = 0 THEN o.CFCMonthlyPayment2
          ELSE o.CFCMonthlyPayment
        END)
    END AS Payment,

    CASE
      WHEN o.createdon >= @cbdate THEN t.New_PurchaseOptionAmount
      ELSE o.CFCOtherPurchaseOption
    END AS purchaseOption,
    --po % = purchaseOption/EquipmentCost 		

    CASE
      WHEN o.createdon >= @cbdate THEN otv.EquipmentCost
      ELSE oc.EquipmentCost
    END AS EquipmentCost,

    CASE
      WHEN o.createdon >= @cbdate THEN t.new_totalreferralfee
      ELSE o.CFCInitialAmountDue
    END AS TotalReferralFee,
    CASE
      WHEN o.createdon >= @cbdate THEN CASE
          WHEN t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) <> 0 THEN (t.new_totalreferralfee / (t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0))) * 100
          ELSE NULL
        END
      ELSE CASE
          WHEN ISNULL(o.CFCLeaseAmount, 0) - ISNULL(ocE.VendorTotalEquipmentCost, 0) <> 0 THEN (o.CFCInitialAmountDue / ISNULL(o.CFCLeaseAmount, 0) - ISNULL(ocE.VendorTotalEquipmentCost, 0)) * 100
          ELSE NULL
        END
    END AS TotalReferralFeePts,


    CASE
      WHEN o.createdon >= @cbdate THEN cm.new_creditmanageridname COLLATE DATABASE_DEFAULT
      ELSE sm_prioritycode.fullname
    END AS CreditManager,
    CASE
      WHEN o.createdon >= @cbdate THEN cm.new_creditmanagerid
      ELSE sm_prioritycode.systemuserid
    END AS CreditManagerid,

    t.new_oneoffprofit AS oneoffProfit,
    CASE
      WHEN t.new_fundingmethod = 2 AND
        t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) <> 0 THEN ISNULL(t.new_oneoffprofit, 0) / t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) * 100
      ELSE NULL
    END AS oneoffProfitPts,


    CASE
      WHEN o.createdon >= @cbdate THEN t.new_irr * 100
      ELSE CASE LP.LeaseUserPercent1
          WHEN 0 THEN LP.LeaseYield
          ELSE LP.LeaseUserPercent1
        END
    END AS IRR,

    AVGBeaconScore,
    AVGFICOScore,
    CASE a.new_businessorigin
      WHEN NULL THEN NULL
      WHEN 2 THEN 0
      WHEN 1 THEN CASE a.New_BusinessStartDate
          WHEN NULL THEN NULL
          ELSE CAST(DATEDIFF(DAY, a.New_BusinessStartDate, GETDATE()) / 365.0 AS decimal(8, 2))
        END

    END AS tib,
    [USDS_12MonthPaydex] AS paydex,
    rc.NoOfLeasesWithBeacon AS repeatclient,

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
    CASE
      WHEN o.createdon >= @cbdate THEN CASE
          WHEN t.new_accountidname IS NULL THEN 1
          ELSE t.new_bfcretainsecuritydeposit
        END
      ELSE 1
    END AS SD_Eligible,
    CASE
      WHEN o.createdon >= @cbdate THEN
        --Ruonan--9/22/2014
        --we need to change our logic so that BFC EFA Portfolio deals are inelighble--per Toby
        --case when t.new_accountidname is null then 1      
        CASE
          WHEN t.new_accountidname IS NULL AND
            t.new_contracttype = 2 THEN 0
          ELSE CASE
              WHEN t.new_accountidname IS NULL THEN 1
              ELSE t.new_bfcretainpurchaseoption
            END
        END
      ELSE 1
    END AS PO_Eligible 
    ,  CASE
    WHEN otv.NoOfTitiledAssets >0 THEN 1
    ELSE 0
  END AS isTitled
  ,  CASE
    WHEN otv.NoOfTitiledAssets >0 THEN 'Title'
    ELSE 'Non-title'
  END AS equipmentType
   ,case when  o.createdon >= @cbdate THEN o.New_LeaseAdministratorId
   else sm_CFPLeaseAdministrator.systemuserid
   end as New_LeaseAdministratorId,
  case when o.createdon >= @cbdate THEN  o.New_LeaseAdministratorIdName
  else sm_CFPLeaseAdministrator.fullname 
  end as New_LeaseAdministratorIdName,
sm_statuscode.value as oppStatus 
   ,dm.CSV as distributionmethod
 
  ,DSLCW.NoOfEnvelopesSent
   ,DP.DocsPendingDate
  ,DSLCW.DocsSent
   ,o.CFDDocumentsReceivedDate
  ,IPOD.InitialPurchaseOrderDate
  ,t.new_contracttype as contracttype
  ,MD.NoOfDocsAdded
  ,MD.NoOfDocsRemoved
  ,otc.OtherIncomeExpense
  INTO #tempsalesdetails
  FROM CRMReplication2013.dbo.Opportunity AS o
  INNER JOIN CRMReplication2013.dbo.account a
    ON a.AccountId = o.AccountID
  INNER JOIN CRMReplication2013.dbo.SystemUser b
    ON o.ownerid = b.SystemUserID
  INNER JOIN intranet_beaconfunding.dbo.tblusers c
    ON (N'ecs\' + c.username = b.domainname)
  --INNER JOIN intranet_beaconfunding.dbo.tbl_users_images d
  --  ON c.userid = d.id
  LEFT OUTER JOIN #LPTABLE LP
    ON o.CFSLeaseNumber = LP.LeaseNum COLLATE DATABASE_DEFAULT

  LEFT JOIN (SELECT
    New_opportunityid,
    new_irr,
    new_fundingmethod,
    new_oneoffprofit,
    New_opportunitytermid,
    new_amountfinanced,
    new_accountidname,
    New_SecurityDeposit,
    New_PurchaseOptionAmount,
    new_totalreferralfee,
    new_programidname,
    new_bfcretainpurchaseoption,
    new_bfcretainsecuritydeposit,
    new_bfcdownpayment,
    new_documentationfee,
    new_advancedpayments,
    new_netduetovendor,
    new_contracttype
  FROM CRMReplication2013.dbo.New_opportunityterm WITH (NOLOCK)
  WHERE new_isinlcw = 1) t
    ON o.opportunityid = t.New_opportunityid
  LEFT JOIN (SELECT
    SUM(new_amount) AS OtherIncomeExpense,
    new_opportunitytermid
  FROM CRMReplication2013.dbo.new_opportunitytermcost
  WHERE new_costtype = 2
  AND new_amount > 0
  GROUP BY new_opportunitytermid) otc
    ON t.New_opportunitytermid = otc.New_opportunitytermid
  LEFT JOIN #otvExcluded otvE
    ON otvE.New_opportunitytermid = t.new_opportunitytermid
  LEFT JOIN #otv otv
    ON t.New_opportunitytermid = otv.New_opportunitytermid
  LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_BeaconScore bs
    ON o.opportunityid = bs.oppid
  LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_FICOScore fs
    ON o.opportunityid = fs.oppid
  LEFT JOIN CRMReplication2013.dbo.[vw_CRMCredit_PaydexScore] pd
    ON o.opportunityid = pd.[OppId]
    AND pd.[accountid] = o.AccountID
  LEFT JOIN #rc rc
    ON rc.accountid = o.AccountID

  LEFT JOIN #otCTE_temp cm
    ON cm.oppid = o.OpportunityId

  LEFT JOIN (SELECT
    attributevalue,
    value,
    CASE
      WHEN CHARINDEX('+', value) <= 0 THEN 0
      ELSE CAST(LEFT(value, 1) AS int)
    END AS firstTerm,
    CASE
      WHEN CHARINDEX('+', value) <= 0 THEN 0
      ELSE CAST(RIGHT(value, 1) AS int)
    END AS lastTerm
  FROM CRMReplication2013.dbo.stringmap
  WHERE objecttypecode = 10012
  AND attributename = 'new_advancedpayments') apts
    ON apts.attributevalue = t.new_advancedpayments


  LEFT JOIN (SELECT
    attributevalue,
    value,
    CASE
      WHEN CHARINDEX('+', value) <= 0 THEN 0
      ELSE CAST(LEFT(value, 1) AS int)
    END AS firstTerm,
    CASE
      WHEN CHARINDEX('+', value) <= 0 THEN 0
      ELSE CAST(RIGHT(value, 1) AS int)
    END AS lastTerm
  FROM CRMReplication2013.dbo.stringmap
  WHERE objecttypecode = 3
  AND attributename = 'CFPAdvancePaymentDesc') sm_CFPAdvancePaymentDesc
    ON sm_CFPAdvancePaymentDesc.attributevalue = o.CFPAdvancePaymentDesc

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
  LEFT JOIN #ocExcluded ocE
    ON o.opportunityid = ocE.New_OppContactId
  LEFT JOIN (SELECT
    value,
    attributevalue
  FROM CRMReplication2013.dbo.stringmap
  WHERE objecttypecode = 3
  AND attributename = 'CFPFundingSource') sm_CFPFundingSource
    ON sm_CFPFundingSource.attributevalue = o.CFPFundingSource
  LEFT JOIN (SELECT
    attributevalue,
    value,
    CASE
      WHEN ISNUMERIC(REPLACE(value, '$', '')) = 1 THEN CAST(REPLACE(value, '$', '') AS money)
      ELSE 0
    END AS docfee
  FROM CRMReplication2013.dbo.stringmap
  WHERE objecttypecode = 3
  AND attributename = 'CFPDocFee') sm_CFPDocFee
    ON sm_CFPDocFee.attributevalue = o.CFPDocFee
  LEFT JOIN (SELECT
    attributevalue,
    value,
    su.systemuserid,
    su.fullname
  FROM CRMReplication2013.dbo.stringmap sm_cm
  INNER JOIN CRMReplication2013.dbo.systemuser su
    ON sm_cm.value = su.firstname + ' ' + su.lastname
  WHERE objecttypecode = 3
  AND attributename = 'prioritycode') sm_prioritycode
    ON sm_prioritycode.attributevalue = o.prioritycode
  LEFT JOIN #oc oc
    ON o.opportunityid = oc.New_OppContactId
    left join
    (  
  select sm.value,su.fullname,su.systemuserid,sm.attributevalue from 
  (select attributevalue,case when value='Chaves, Jennifer' then 'Chaves, Jen' else value end as value 
  from CRMReplication2013.dbo.stringmap  where objecttypecode=3 and attributename='CFPLeaseAdministrator')
  sm inner join CRMReplication2013.dbo.systemuser su
  on sm.value=su.fullname)sm_CFPLeaseAdministrator
   ON sm_CFPLeaseAdministrator.attributevalue = o.CFPLeaseAdministrator 
   left join
   (select value,attributevalue from 
    CRMReplication2013.dbo.stringmap  where objecttypecode=3 and attributename='statuscode'
    )sm_statuscode
    on sm_statuscode.attributevalue=o.statuscode
   left join #Distributionmethod dm
   on dm.opportunityid=o.opportunityid
   left join #Manualdocs MD on MD.OPPORTUNITYID=o.opportunityid
   LEFT JOIN #DocusignLCW DSLCW ON DSLCW.OPPORTUNITYID=o.opportunityid
   LEFT JOIN #DocsPendingDate DP ON DP.New_opportunityId=o.opportunityid
    LEFT JOIN #InitialPurchaseOrderDate IPOD ON IPOD.OpportunityId=O.opportunityid
  WHERE o.CFDEquipmentAcceptDate >= @dateFrom
  AND ((o.StatusCode = 2)
  OR (o.StatusCode = 9)
  OR (o.StatusCode = 1))
  AND o.CreatedOn >= @cbdate
  AND o.salesstagecode = 7

  TRUNCATE TABLE KeyStats_AcceptedOpportunity_HourlySnapshot
  INSERT INTO KeyStats_AcceptedOpportunity_HourlySnapshot([opid]
      ,[Appid]
      ,[name]
      ,[consultant]
      ,[consultantId]
      ,[companyName]
      ,[acceptanceDate]
      ,[leaseAmt]
      ,[FundingMethodValue]
      ,[FundingMethod]
      ,[initialCash]
      ,[NetVendorAmount]
      ,[securityDeposit]
      ,[Payment]
      ,[purchaseOption]
      ,[EquipmentCost]
      ,[TotalReferralFee]
      ,[TotalReferralFeePts]
      ,[CreditManager]
      ,[CreditManagerid]
      ,[oneoffProfit]
      ,[oneoffProfitPts]
      ,[IRR]
      ,[AVGBeaconScore]
      ,[AVGFICOScore]
      ,[tib]
      ,[paydex]
      ,[repeatclient]
      ,[insideSales]
      ,[insideSalesId]
      ,[SD_Eligible]
      ,[PO_Eligible]
      ,[isTitled]
      ,[equipmentType]
      ,[New_LeaseAdministratorId]
      ,[New_LeaseAdministratorIdName]
      ,[oppStatus]
      ,[distributionmethod]
      ,[NoOfEnvelopesSent]
        ,DocsPendingDate
  ,DocsSent
   ,DocumentsReceivedDate
  ,InitialPurchaseOrderDate
  ,ContractType
  ,NoOfDocsAdded
  ,NoOfDocsRemoved
  ,OtherIncomeExpense
  )
      SELECT [opid]
      ,[Appid]
      ,[name]
      ,[consultant]
      ,[consultantId]
      ,[companyName]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [acceptanceDate])
      ,[leaseAmt]
      ,[FundingMethodValue]
      ,[FundingMethod]
      ,[initialCash]
      ,[NetVendorAmount]
      ,[securityDeposit]
      ,[Payment]
      ,[purchaseOption]
      ,[EquipmentCost]
      ,[TotalReferralFee]
      ,[TotalReferralFeePts]
      ,[CreditManager]
      ,[CreditManagerid]
      ,[oneoffProfit]
      ,[oneoffProfitPts]
      ,[IRR]
      ,[AVGBeaconScore]
      ,[AVGFICOScore]
      ,[tib]
      ,[paydex]
      ,[repeatclient]
      ,[insideSales]
      ,[insideSalesId]
      ,[SD_Eligible]
      ,[PO_Eligible]
      ,[isTitled]
      ,[equipmentType]
      ,[New_LeaseAdministratorId]
      ,[New_LeaseAdministratorIdName]
      ,[oppStatus]
      ,[distributionmethod]
      ,[NoOfEnvelopesSent]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), DocsPendingDate)
  ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), DocsSent)
   ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CFDDocumentsReceivedDate)
  ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), InitialPurchaseOrderDate )
  ,ContractType
  , NoOfDocsAdded
  ,NoOfDocsRemoved
  ,OtherIncomeExpense
  FROM #tempsalesdetails
  
  
--credit approval

--submit

IF OBJECT_ID('TEMPDB..#tempSubmitOpportunities') IS NOT NULL
BEGIN
DROP TABLE #tempSubmitOpportunities
END

select 
		distinct Details.OpportunityId as opid
		, Details.OwnerId as consultantId,Details.OwnerIdName as consultant ,
			--sm.value as FundingMethod,
			lcwt.new_fundingmethod as FundingMethodvalue,
				 cm.new_creditmanageridname as CreditManager
				 ,cm.new_creditmanagerid as creditmanagerid
					,submittedterm.creditsubmissiondate as SubmitDate,
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
		into #tempSubmitOpportunities			
from
		CRMReplication2013.dbo.Opportunity as Details 	
	
		inner join 
			(
				select  New_opportunityid,new_opportunitytermid,new_accountidname,new_fundingmethod
				from CRMReplication2013.dbo.New_opportunityterm WITH (NOLOCK) where new_isinlcw = 1 
			) lcwt	
			on Details.OpportunityId=lcwt.New_opportunityid
		inner join 
		(
	select New_opportunityid ,min(ctc.creditsubmissiondate) as creditsubmissiondate
	from (select * from  CRMReplication2013.dbo.New_opportunityterm WITH (NOLOCK) where createdbyname <>N'Admin, CRM' 
	) term
 	inner join 
				 (select   new_opportunitytermid,min(createdon) as creditsubmissiondate
					from CRMReplication2013.dbo.new_opportunitytermcredit				
				where new_creditdecision =N'submission' 
				group by new_opportunitytermid
				) ctc			
					on ctc.new_opportunitytermid=term.new_opportunitytermid 
					group by New_opportunityid) submittedterm
					on submittedterm.New_opportunityid=Details.OpportunityId						
						
				LEFT JOIN #otCTE_temp cm
  ON cm.oppid = Details.OpportunityId

LEFT JOIN #InsideSales iso
  ON Details.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON Details.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON Details.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON Details.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON Details.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON Details.new_sharecredit5id = issc5.guid
		where Details.CreatedOn >=  @cbdate 	
	--select * into KeyStats_SubmitOpportunity_HourlySnapshot
	--from #tempSubmitOpportunities
	truncate table 
	KeyStats_SubmitOpportunity_HourlySnapshot
	insert into KeyStats_SubmitOpportunity_HourlySnapshot
	([opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[creditmanagerid]
      ,[SubmitDate]
      ,[insideSales]
      ,[insideSalesId])
	select [opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[creditmanagerid]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [SubmitDate]) 
      ,[insideSales]
      ,[insideSalesId]	
	from #tempSubmitOpportunities
------------------------------------------------------------------------------
--funded info should read from opportunity 
----funded CFDCreditCardExpiration

    
IF OBJECT_ID('TEMPDB..#tempFundOpportunities') IS NOT NULL
BEGIN
DROP TABLE #tempFundOpportunities
END

	select distinct Details.OpportunityId as opid,
	OwnerId as consultantId,OwnerIdName as consultant,		
		lcwt.new_fundingmethod as FundingMethodvalue,
	 cm.new_creditmanageridname as CreditManager,	
	  cm.new_creditmanagerid as CreditManagerid		
--,lcwt.new_decisioneffectivedate as ApprovalDate
,CFDCreditCardExpiration as FundDate,
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
			into #tempFundOpportunities
			from CRMReplication2013.dbo.Opportunity as Details 
			inner join 
			(
				select  New_opportunityid, new_decisioneffectivedate,new_fundingmethod
				from CRMReplication2013.dbo.New_opportunityterm WITH (NOLOCK) where new_isinlcw = 1 
			) lcwt	
			on Details.opportunityid =lcwt.New_opportunityid
	
		
				LEFT JOIN #otCTE_temp cm
  ON cm.oppid = Details.OpportunityId

LEFT JOIN #InsideSales iso
  ON Details.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON Details.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON Details.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON Details.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON Details.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON Details.new_sharecredit5id = issc5.guid
		
			where Details.CreatedOn >= @cbdate 
			and  
			(Details.statuscode=1 or Details.statuscode=2 or Details.statuscode=9 ) and Details.CFDCreditCardExpiration is not null		
	
	truncate table 
	KeyStats_FundOpportunity_HourlySnapshot
	insert into KeyStats_FundOpportunity_HourlySnapshot
	([opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[CreditManagerid]
      --,[ApprovalDate]
      ,[FundDate]
      ,[insideSales]
      ,[insideSalesId])
	select [opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[CreditManagerid]
      --,[ApprovalDate]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [FundDate]) 
      ,[insideSales]
      ,[insideSalesId]
	from #tempFundOpportunities

----------------------------------------------------------------------------------
----approvaed
--approval date should read from opportunity CFDFollowUpDate
    
IF OBJECT_ID('TEMPDB..#tempApprovedOpportunities') IS NOT NULL
BEGIN
DROP TABLE #tempApprovedOpportunities
END


	
		select  distinct Details.OpportunityId as opid,
		OwnerId as consultantId,OwnerIdName as consultant,
			lcwt.new_fundingmethod as FundingMethodvalue,
				 cm.new_creditmanageridname as CreditManager	
				 , cm.new_creditmanagerid as CreditManagerid	
				 ,t.new_decisioneffectivedate as ApprovalDate,
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
			INTO #tempApprovedOpportunities
			from CRMReplication2013.dbo.Opportunity as Details 		
		inner join 
			(
				select  New_opportunityid,new_opportunitytermid,new_fundingmethod
				from CRMReplication2013.dbo.New_opportunityterm where new_isinlcw = 1 
			) lcwt	
			on Details.OpportunityId=lcwt.New_opportunityid
			
		
			inner join		
			
					(
					select  ot.New_opportunityid,min(ot.new_decisioneffectivedate) as new_decisioneffectivedate
					from CRMReplication2013.dbo.New_opportunityterm ot 
					where new_decisioneffectivedate is not null and Createdbyname <>N'Admin, CRM'  and ( new_termstatus=3 or new_termstatus=8 ) 
					group by New_opportunityid 
				)t
					on  Details.OpportunityId =t.New_opportunityid 
					
					LEFT JOIN #otCTE_temp cm
  ON cm.oppid = Details.OpportunityId

LEFT JOIN #InsideSales iso
  ON Details.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON Details.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON Details.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON Details.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON Details.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON Details.new_sharecredit5id = issc5.guid		
								where Details.CreatedOn >= @cbdate 				
    	
	truncate table 
	KeyStats_ApprovedOpportunity_HourlySnapshot
	insert into KeyStats_ApprovedOpportunity_HourlySnapshot
	([opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[CreditManagerid]
      ,[ApprovalDate]
      ,[insideSales]
      ,[insideSalesId])
	select [opid]
      ,[consultantId]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[CreditManager]
      ,[CreditManagerid]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [ApprovalDate]) 
      ,[insideSales]
      ,[insideSalesId]
	from #tempApprovedOpportunities
		
---------------------------------------------------------------------------------------------
	--deals reviewed /terms submitted   
    
    	
	IF OBJECT_ID('TEMPDB..#tempReviewedTerms') IS NOT NULL
BEGIN
DROP TABLE #tempReviewedTerms
END
		
select new_appid as appid,opportunityid, ownerid as consultantid,
owneridname as consultant,


		lcw_fundingmethod as FundingMethodvalue,
termid,termname,new_isinlcw,lcw_termid,lcw_termname,lcw_fundingmethod,
[Min. Pts. Profit] ,[Payment Type],[Credit Approval Date],[Submission Date],[Submitted by],result.[reviewedOn],[reviewed by]
,creditmanager ,creditmanagerid,[credit decision],comments
, CASE
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

into #tempReviewedTerms
from 
(


select  o.new_appid,opportunityid,o.ownerid ,o.owneridname ,
o.new_sharecreditid ,o.new_sharecredit2id ,o.new_sharecredit3id ,
o.new_sharecredit4id,o.new_sharecredit5id ,
	
				otc.new_fundingmethod as fundingmethod,ot_lcw.new_fundingmethod as lcw_fundingmethod,
				otc.new_opportunitytermid as termid, otc.new_termname as termname,otc.new_isinlcw,
				ot_lcw.new_opportunitytermid as lcw_termid,ot_lcw.new_termname as lcw_termname,
				ot_lcw.new_profitminpoints as [Min. Pts. Profit]
				,sm.value as [Payment Type]
				,ot_lcw.new_decisioneffectivedate as [Credit Approval Date] 
				,otc.new_creditdecision as [credit decision], otc.creditmanager,
				otc.creditmanagerid,
				otc.new_comment as comments
				,case when otc.new_creditdecision=N'Submission'  then otc.createdon else null end as [Submission Date]
				,case when otc.new_creditdecision=N'Submission' then  otc.createdbyname else null end as [Submitted by]
				,case when otc.new_creditdecision=N'Submission'  then null else otc.createdon end as [reviewedOn]			
				,case when otc.new_creditdecision=N'Submission' then  null else otc.createdbyname end as [reviewed by]
	
		from CRMReplication2013.dbo.opportunity o
			inner  join (SELECT new_achrequired,New_opportunityid,new_fundingmethod,new_opportunitytermid,new_termname,new_profitminpoints,new_decisioneffectivedate
			 FROM CRMReplication2013.dbo.New_opportunityterm WITH (NOLOCK) where new_isinlcw = 1 ) AS ot_lcw
			on o.opportunityid = ot_lcw.New_opportunityid
		
			inner join 
			(
				select t.new_opportunityid,t.new_termname,t.new_isinlcw,t.new_fundingmethod, t.new_opportunitytermid,	new_creditdecision,	new_comment	,
			new_creditmanagerid AS creditmanagerid,
			new_creditmanageridname as creditmanager,new_description ,tc.createdon,tc.createdbyname
			from CRMReplication2013.dbo.new_opportunityterm t inner join CRMReplication2013.dbo.new_opportunitytermcredit tc 
			on tc.new_opportunitytermid=t.new_opportunitytermid  
			 where
			 tc.new_fundingsourceid is null and tc.new_creditmanageridname is not null and tc.new_creditmanageridname <> 'Admin, CRM' )as otc
			on otc.new_opportunityid=o.opportunityid 	
			
				left join CRMReplication2013.dbo.stringmap sm on sm.objecttypecode=10012 
					and sm.attributename=N'new_achrequired'	
					and sm.attributevalue= ot_lcw.new_achrequired
) 
			result	 
		
					

LEFT JOIN #InsideSales iso
  ON result.ownerid = iso.guid
LEFT JOIN #InsideSales issc1
  ON result.new_sharecreditid = issc1.guid
LEFT JOIN #InsideSales issc2
  ON result.new_sharecredit2id = issc2.guid
LEFT JOIN #InsideSales issc3
  ON result.new_sharecredit3id = issc3.guid
LEFT JOIN #InsideSales issc4
  ON result.new_sharecredit4id = issc4.guid
LEFT JOIN #InsideSales issc5
  ON result.new_sharecredit5id = issc5.guid	
    
    --select * into
    --dbo.KeyStats_ReviewedTerms_HourlySnapshot
    --from #tempReviewedTerms
    
	TRUNCATE TABLE KeyStats_ReviewedTerms_HourlySnapshot
	INSERT INTO KeyStats_ReviewedTerms_HourlySnapshot
	([appid]
      ,[opportunityid]
      ,[consultantid]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[termid]
      ,[termname]
      ,[new_isinlcw]
      ,[lcw_termid]
      ,[lcw_termname]
      ,[lcw_fundingmethod]
      ,[Min. Pts. Profit]
      ,[Payment Type]
      ,[Credit Approval Date]
      , [Submission Date]
      ,[Submitted by]
      ,[reviewedOn]
      ,[reviewed by]
      ,[creditmanager]
       ,[CreditManagerid]
      ,[credit decision]
      ,[comments]
      ,[insideSales]
      ,[insideSalesId])
	select [appid]
      ,[opportunityid]
      ,[consultantid]
      ,[consultant]
      ,[FundingMethodvalue]
      ,[termid]
      ,[termname]
      ,[new_isinlcw]
      ,[lcw_termid]
      ,[lcw_termname]
      ,[lcw_fundingmethod]
      ,[Min. Pts. Profit]
      ,[Payment Type]
      ,[Credit Approval Date]
      ,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),[Submission Date])
      ,[Submitted by]
      , DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [reviewedOn]) 
      ,[reviewed by]
      ,[creditmanager],CreditManagerid
      ,[credit decision]
      ,[comments]
      ,[insideSales]
      ,[insideSalesId]
     	from #tempReviewedTerms		


END
GO
