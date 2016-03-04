SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CRM_BeaconIntranet_LoadALL]--'11/1/2015','11/20/2015 23:59:59','','',1, 10, 2013
@dateFrom as datetime, @dateTo as datetime,
@fm VARCHAR(200),
@cm nvarchar(50),
@takeSnapShot int = Null,
@month as int=null,
@year as int=null
AS
SET NOCOUNT ON;
--set statistics io on
--  set statistics time on
declare @fromdate as date= DATEADD(year,-1, @dateTo)
	----run commission hourly snap shot
	--exec[dbo].[CommissionBuilder_LoadDrawReport_Hourly]
-- ### Take Snap Shot ### --

	declare @cbdate as date
	set @cbdate = '01/20/2012'

	SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), '1/1/2006') 
	set @dateTo = getdate()

	
IF OBJECT_ID('TEMPDB..#LPTABLE') IS NOT NULL
BEGIN
  DROP TABLE #LPTABLE
END
 SELECT
  LeaseUser.LeaseUserPercent1,
  LeaseAux.LeaseYield,
  LeaseDatabase.LeaseNum,
  leaseuseramt6
  into #LPTABLE
FROM (LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseDatabase LeaseDatabase
INNER JOIN LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseUser LeaseUser
  ON (LeaseDatabase.LeaseCompanyNum = LeaseUser.LeaseUserCompanyNum)
  AND (LeaseDatabase.LeaseNum = LeaseUser.LeaseUserLeaseNum))
INNER JOIN LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseAux LeaseAux
  ON (LeaseDatabase.LeaseCompanyNum = LeaseAux.LeaseAuxCompanyNum)
  AND (LeaseDatabase.LeaseNum = LeaseAux.LeaseAuxLeaseNum)
WHERE LeaseDatabase.LeasePostedSw = 'Y'

IF OBJECT_ID('TEMPDB..#otvExcluded') IS NOT NULL
BEGIN
  DROP TABLE #otvExcluded
END

SELECT
  New_opportunitytermid,
  SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(new_equipmentsoftcosts, 0)) AS GrossDueToVendor,
  SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS NetDueToVendor
into #otvExcluded
FROM CRMReplication2013.dbo.New_opportunitytermvendor
WHERE New_isuserselected = 1
AND New_opportunitytermid IS NOT NULL
AND (New_AccountIdName IN (SELECT
  ExcludedVendorName COLLATE SQL_Latin1_General_CP1_CI_AS
FROM CRMReplication2013.dbo.XCelsius_ExcludedVendors)
)
GROUP BY New_opportunitytermid



IF OBJECT_ID('TEMPDB..#otv') IS NOT NULL
BEGIN
  DROP TABLE #otv
END
SELECT
  New_opportunitytermid,
  SUM(ISNULL(New_EquipmentCost, 0)) AS EquipmentCost,
  SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(new_equipmentsoftcosts, 0)) AS GrossDueToVendor
into #otv
FROM CRMReplication2013.dbo.New_opportunitytermvendor
WHERE New_isuserselected = 1
AND New_opportunitytermid IS NOT NULL
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

IF OBJECT_ID('TEMPDB..#oc') IS NOT NULL
BEGIN
  DROP TABLE #oc
END
SELECT
  New_OppContactId,
  SUM(ISNULL(New_EquipmentCost, 0)) AS EquipmentCost,
  SUM(ISNULL(New_EquipmentCost, 0)) + SUM(ISNULL(Amount, 0)) AS GrossDueToVendor
  into #oc
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
  COUNT(leasecustidnum) AS NoOfLeasesWithBeacon
  into #rc
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

WITH otCTE AS
(
SELECT ot.new_opportunityid as oppid,
ot.NEW_OPPORTUNITYTERMID,ot.NEW_termname, ot.new_originatedtermid,ot.new_isinlcw, 0 AS distance
FROM NEW_OPPORTUNITYTERM ot WITH (NOLOCK)
WHERE ot.new_isinlcw=1 --and ot.NEW_OPPORTUNITYTERMID=@tid
UNION ALL
SELECT oto.new_opportunityid as oppid,
oto.NEW_OPPORTUNITYTERMID,oto.NEW_termname, oto.new_originatedtermid,oto.new_isinlcw, ott.distance + 1 AS distance
FROM otCTE AS ott
JOIN NEW_OPPORTUNITYTERM  AS oto WITH (NOLOCK)
ON ott.new_originatedtermid = oto.NEW_OPPORTUNITYTERMID
)
select * into  #otCTE_temp from
(
SELECT oppid,

row_number() over(partition by oppid order by creditdecisionLevel,distance,createdon desc) as rank ,new_creditmanageridname
FROM otCTE t
inner join 
 (select NEW_OPPORTUNITYTERMID,new_creditdecision,createdon
 ,case when new_creditdecision=N'ok to sell' then 0
 else 1 end as creditdecisionLevel ,new_creditmanageridname
 from dbo.new_opportunitytermcredit  
 where 
 new_fundingsourceid is null 
 and new_creditmanagerid is not null 
 and new_creditmanageridname NOT IN  (N'Baratta, Jon', N'Admin, CRM')
 ) c on
t.NEW_OPPORTUNITYTERMID=c.NEW_OPPORTUNITYTERMID
 
 )
r where rank=1
 

IF OBJECT_ID('TEMPDB..#tempsalesdetails') IS NOT NULL
	BEGIN
	DROP TABLE #tempsalesdetails
	END


	CREATE TABLE #tempsalesdetails
	( name nvarchar(300),
	opid uniqueidentifier,
	aid uniqueidentifier,
	consultant nvarchar(160),
	consultantId uniqueidentifier,
	companyName nvarchar(160),
	acceptanceDate datetime,
	leaseAmt money,
	NetVendorAmount money,
	FundingMethod  VARCHAR(200),
	BFCDownPayment real,
	DocFee real,	
	securityDeposit real,
	purchaseOption real,
	AdvancedPayment VARCHAR(50),
	payment real,
	GrossDueToVendorExcluded real,
	EquipmentCost real,
	totalReferralFee real,
	CreditManager nvarchar(50),
	oneoffProfit real,
	IRR real,
	image varchar(256),
	beacon_score int,
	fico_score int,
	tib int,
	paydex int,
	repeatclient int,
	programname nvarchar(300),
	SDEligibility bit,
	POEligibility bit,
	OtherIncomeExpense real,
	SharedCredit uniqueidentifier,
	SharedCredit2 uniqueidentifier,
	SharedCredit3 uniqueidentifier,
	SharedCredit4 uniqueidentifier,
	SharedCredit5 uniqueidentifier,CFSLeaseNumber  VARCHAR(15)
	,createdon datetime
	)

	INSERT INTO #tempsalesdetails
	(  name ,
	opid,
	aid,
	consultant,
	consultantId,
	companyName ,
	acceptanceDate ,
	leaseAmt,
	NetVendorAmount,
	FundingMethod ,
	BFCDownPayment ,
	DocFee ,
	securityDeposit,
	purchaseOption,
	AdvancedPayment,
	payment,
	GrossDueToVendorExcluded,
	EquipmentCost,
	totalReferralFee,
	CreditManager ,
	oneoffProfit,
	IRR ,
	image,
	beacon_score,
	fico_score,
	tib,
	paydex,
	repeatclient,
	programname ,
	SDEligibility ,
	POEligibility ,
	OtherIncomeExpense,
	SharedCredit ,
		SharedCredit2 ,
		SharedCredit3 ,
		SharedCredit4 ,
		SharedCredit5 ,CFSLeaseNumber
	,createdon 
	)


	      (SELECT
    Details.Name AS name,
    OpportunityId AS opid,
    Details.AccountID AS aid,
    Details.OwnerIdName AS consultant,
    Details.OwnerId AS consultantId,
    AccountIdName AS companyName,
    CFDEquipmentAcceptDate AS acceptanceDate,    
    ISNULL(Details.CFCLeaseAmount, 0) - ISNULL(ocE.VendorTotalEquipmentCost, 0) AS leaseAmt,
    0 AS NetVendorAmount,
    CASE Details.CFPFundingSource
      WHEN NULL THEN NULL
      WHEN 2 THEN 'Portfolio'
      ELSE REPLACE(CRMReplication2013.dbo.StringMapValue(3, 'CFPFundingSource', Details.CFPFundingSource), 'One Off - ', '')
    END AS FundingMethod,
    Details.CFCDownpaymentBFC AS BFCDownPayment,
    0 AS DocFee,--for old deal, set doc fee as 0 --Ruonan
    Details.CFCSecurityDeposit AS securityDeposit,
    Details.CFCOtherPurchaseOption AS purchaseOption,
    CASE Details.CFPAdvancePaymentDesc
      WHEN NULL THEN NULL
      ELSE CRMReplication2013.dbo.StringMapValue(3, 'CFPAdvancePaymentDesc', Details.CFPAdvancePaymentDesc)
    END AS AdvancedPayment,

    CASE
      WHEN CFCMonthlyPayment IS NULL OR
        CFCMonthlyPayment = 0 THEN CFCMonthlyPayment2
      ELSE CFCMonthlyPayment
    END AS Payment,
    oc.GrossDueToVendor - ISNULL(ocE.GrossDueToVendor, 0) AS GrossDueToVendorExcluded,
    oc.EquipmentCost AS EquipmentCost,
    Details.CFCInitialAmountDue AS totalReferralFee,
      CASE Details.prioritycode
      WHEN 2 THEN 'Magner, William'
      WHEN 3 THEN 'Oliva, Sam'
      WHEN 4 THEN 'McDonough, Toby'
      WHEN 5 THEN 'Source, Funding'
      WHEN 7 THEN 'Waxman, Todd'
      WHEN 8 THEN 'Schmuker, Tim'
    END AS CreditManager,
    lp.leaseuseramt6 AS oneoffProfit,
    CASE LP.LeaseUserPercent1
      WHEN 0 THEN LP.LeaseYield
      ELSE LP.LeaseUserPercent1

    END AS IRR,
    d.imagepath AS image,
    AVGBeaconScore,
    AVGFICOScore,
    CASE a.new_businessorigin
      WHEN NULL THEN NULL
      WHEN 2 THEN 0
      WHEN 1 THEN CASE a.New_BusinessStartDate
          WHEN NULL THEN NULL
          ELSE DATEDIFF(DAY, a.New_BusinessStartDate, GETDATE())
        END
    END AS tib,
    [USDS_12MonthPaydex] AS paydex,
    rc.NoOfLeasesWithBeacon AS RepeatClient,
    NULL,
    NULL,
    NULL,
    NULL,
    new_sharecreditid,
    new_sharecredit2id,
    new_sharecredit3id,
    new_sharecredit4id,
    new_sharecredit5id,
    CFSLeaseNumber,
    Details.createdon
  FROM CRMReplication2013.dbo.Opportunity AS Details
  INNER JOIN CRMReplication2013.dbo.account a
    ON a.AccountId = Details.AccountID
  INNER JOIN CRMReplication2013.dbo.SystemUser b
    ON details.ownerid = b.SystemUserID
  INNER JOIN intranet_beaconfunding.dbo.tblusers c
    ON (N'ecs\' + c.username = b.domainname)
  INNER JOIN intranet_beaconfunding.dbo.tbl_users_images d
    ON c.userid = d.id
  LEFT OUTER JOIN #LPTABLE LP
    ON Details.CFSLeaseNumber = LP.LeaseNum COLLATE DATABASE_DEFAULT
  LEFT JOIN #oc oc
    ON Details.opportunityid = oc.New_OppContactId
  LEFT JOIN #ocExcluded ocE
    ON Details.opportunityid = ocE.New_OppContactId
  LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_BeaconScore bs
    ON Details.opportunityid = bs.oppid
  LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_FICOScore fs
    ON Details.opportunityid = fs.oppid
  LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_PaydexScore pd
    ON Details.opportunityid = pd.[OppId]
    AND pd.[accountid] = Details.AccountID
  LEFT JOIN #rc rc
    ON rc.accountid = Details.AccountID
  WHERE CFDEquipmentAcceptDate >= @dateFrom
  AND (Details.StatusCode = 2
  OR Details.StatusCode = 9
  OR Details.StatusCode = 1)
  AND Details.CreatedOn < @cbdate
  AND salesstagecode = 7)
  
	union 	
	
 (SELECT
        Details.Name AS name,
        OpportunityId AS opid,
        Details.AccountID AS aid,
        Details.OwnerIdName AS consultant,
        Details.OwnerId AS consultantId,
        AccountIdName AS companyName,
        CFDEquipmentAcceptDate AS acceptanceDate,
        t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) AS leaseAmt,
        t.new_netduetovendor AS NetVendorAmount,
        ISNULL(t.new_accountidname, 'Portfolio') AS FundingMethod,
        t.new_bfcdownpayment AS BFCDownPayment,
        t.new_documentationfee AS DocFee,
        t.New_SecurityDeposit AS securityDeposit,
        t.New_PurchaseOptionAmount AS purchaseOption,

        CASE
          WHEN t.new_advancedpayments IS NULL THEN NULL
          ELSE CRMReplication2013.dbo.StringMapValue(10012, 'new_advancedpayments', t.new_advancedpayments)
        END AS AdvancedPayment,

        Payment = (SELECT TOP 1
          p.new_payment
        FROM dbo.new_opportunitytermpayment p
        WHERE p.new_opportunitytermid = t.new_opportunitytermid
        ORDER BY p.new_term DESC),
        otv.GrossDueToVendor - ISNULL(otvE.GrossDueToVendor, 0) AS GrossDueToVendorExcluded,
        otv.EquipmentCost AS EquipmentCost,
        t.new_totalreferralfee AS TotalReferralFee,
        --CASE
        --  WHEN t.new_fundingmethod = 1 THEN CRMReplication2013.dbo.SalesRanking_LoadTermCreditManager(t.new_opportunitytermid)
        --  ELSE CRMReplication2013.dbo.LoadTermOKToSellCreditManager(t.new_opportunitytermid)
        --END AS CreditManager,
        cm.new_creditmanageridname as CreditManager,
        t.new_oneoffprofit AS oneoffProfit,

        t.new_irr * 100 AS IRR,

        d.imagepath AS image,
        AVGBeaconScore,
        AVGFICOScore,
        CASE a.new_businessorigin
          WHEN NULL THEN NULL
          WHEN 2 THEN 0
          WHEN 1 THEN CASE a.New_BusinessStartDate
              WHEN NULL THEN NULL
              ELSE DATEDIFF(DAY, a.New_BusinessStartDate, GETDATE())
            END

        END AS tib,
        [USDS_12MonthPaydex] AS paydex,
        rc.NoOfLeasesWithBeacon AS repeatclient,
        t.new_programidname AS programname,
        CASE
          WHEN t.new_accountidname IS NULL THEN 1
          ELSE t.new_bfcretainsecuritydeposit
        END AS SD_Eligible,
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
        END AS PO_Eligible,
        otc.OtherIncomeExpense,
        new_sharecreditid,
        new_sharecredit2id,
        new_sharecredit3id,
        new_sharecredit4id,
        new_sharecredit5id,
        CFSLeaseNumber,
        Details.createdon
      FROM CRMReplication2013.dbo.Opportunity AS Details
      INNER JOIN CRMReplication2013.dbo.account a
        ON a.AccountId = Details.AccountID
      INNER JOIN CRMReplication2013.dbo.SystemUser b
        ON details.ownerid = b.SystemUserID
      INNER JOIN intranet_beaconfunding.dbo.tblusers c
        ON (N'ecs\' + c.username = b.domainname)
      INNER JOIN intranet_beaconfunding.dbo.tbl_users_images d
        ON c.userid = d.id
      LEFT OUTER JOIN #LPTABLE LP
        ON Details.CFSLeaseNumber = LP.LeaseNum COLLATE DATABASE_DEFAULT

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
        ON Details.opportunityid = t.New_opportunityid
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
        ON Details.opportunityid = bs.oppid
      LEFT JOIN CRMReplication2013.dbo.vw_CRMCredit_FICOScore fs
        ON Details.opportunityid = fs.oppid
      LEFT JOIN CRMReplication2013.dbo.[vw_CRMCredit_PaydexScore] pd
        ON Details.opportunityid = pd.[OppId]
        AND pd.[accountid] = Details.AccountID
      LEFT JOIN #rc rc
        ON rc.accountid = Details.AccountID     
   
		left join #otCTE_temp cm on cm.oppid= Details.OpportunityId		
  
   WHERE CFDEquipmentAcceptDate >= @dateFrom
      AND ((Details.StatusCode = 2)
      OR (Details.StatusCode = 9)
      OR (Details.StatusCode = 1))
      AND Details.CreatedOn >= @cbdate
      AND salesstagecode = 7)	
	
	
	--IF OBJECT_ID('CRM_BeaconIntranet_SalesDetails_Hourly','U') IS NOT NULL
	--BEGIN		
	--	DROP TABLE CRM_BeaconIntranet_SalesDetails_Hourly
	--END
	
	truncate table CRM_BeaconIntranet_SalesDetails_Hourly	
	insert into CRM_BeaconIntranet_SalesDetails_Hourly
	([name]
      ,[opid]
      ,[aid]
      ,[consultant]
      ,[consultantId]
      ,[companyName]
      ,[acceptanceDate]
      ,[leaseAmt]
      ,[NetVendorAmount]
      ,[FundingMethod]
      ,[BFCDownPayment]
      ,[DocFee]
      ,[securityDeposit]
      ,[purchaseOption]
      ,[AdvancedPayment]
      ,[payment]
      ,[GrossDueToVendorExcluded]
      ,[EquipmentCost]
      ,[totalReferralFee]
      ,[CreditManager]
      ,[oneoffProfit]
      ,[IRR]
      ,[image]
      ,[beacon_score]
      ,[fico_score]
      ,[tib]
      ,[paydex]
      ,[repeatclient]
      ,[programname]
      ,[SDEligibility]
      ,[POEligibility]
      ,[OtherIncomeExpense]
      ,[SharedCredit]
      ,[SharedCredit2]
      ,[SharedCredit3]
      ,[SharedCredit4]
      ,[SharedCredit5]
      ,[CFSLeaseNumber]
      ,[createdon])
	select 
	 name ,
	opid,
	aid,
	consultant,
	consultantId,
	companyName ,
	acceptanceDate ,
	leaseAmt,
	NetVendorAmount,
	FundingMethod ,
	BFCDownPayment ,
	DocFee ,
	securityDeposit,
	purchaseOption,
	AdvancedPayment,
	payment,
	GrossDueToVendorExcluded,
	EquipmentCost,
	totalReferralFee,
	CreditManager ,
	oneoffProfit,
	IRR ,
	image,
	beacon_score,
	fico_score,
	tib,
	paydex,
	repeatclient,
		programname ,
	SDEligibility ,
	POEligibility,
	OtherIncomeExpense ,
	SharedCredit ,
		SharedCredit2 ,
		SharedCredit3 ,
		SharedCredit4 ,
		SharedCredit5 ,CFSLeaseNumber
	,createdon
	from #tempsalesdetails where 
	leaseAmt >0 
	--order by acceptanceDate Desc,consultant Desc
	
GO
