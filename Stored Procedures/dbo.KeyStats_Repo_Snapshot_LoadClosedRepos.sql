SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Ruonan 12242014 - Load Repo records for key sales repo report
--[dbo].[KeyStats_Repo_Snapshot_LoadClosedRepos]1
CREATE PROCEDURE [dbo].[KeyStats_Repo_Snapshot_LoadClosedRepos] 
AS
BEGIN

    IF OBJECT_ID('tempdb..#assets') IS NOT NULL
      DROP TABLE #assets
    SELECT
      New_RepoId,
      COUNT(*) AS Number,
      MIN(createdon) AS AssetCreatedOn,
      MIN(New_SoldDate) AS New_SoldDate,
      MIN(New_TransferableTitle) AS New_TransferableTitle,
      MIN(New_ActualPickup) AS New_ActualPickup,
      MIN(New_ScheduledPickup) AS New_ScheduledPickup,
      MIN(New_ListDate) AS New_ListDate,
      SUM(new_estimatedsalesprice) AS estimatedsalesprice,
	  [CRMReplication2013].dbo.RepoBuilder_CalculateRepoEstListSalePrice(New_RepoId) AS ListPrice
      --SUM(
      --CASE
      --  WHEN COALESCE(li.equ_ask_price, 0) <> 0 THEN CASE
      --      WHEN ((ra.new_parentrepoassetid IS NOT NULL AND
      --        ra.new_parentrepoassetid <> '')) THEN 0
      --      ELSE COALESCE(li.equ_ask_price, 0)
      --    END
      --  ELSE 0
      --END


      --) AS ListPrice
       INTO #assets
    FROM [CRMReplication2013].dbo.New_repoasset ra
    LEFT JOIN EquipUsed.dbo.EquipmentListings_RepoAsset_Mapping m
      ON ra.New_repoassetId = m.repoAsset_id
    LEFT JOIN EquipUsed.dbo.EquipmentListings li
      ON m.equ_id = li.equ_id


    GROUP BY New_RepoId

    IF OBJECT_ID('tempdb..#assetsSold') IS NOT NULL
      DROP TABLE #assetsSold
    SELECT
      New_RepoId,
      COUNT(*) AS Number INTO #assetsSold
    FROM [CRMReplication2013].dbo.New_repoasset
    WHERE 
    New_SoldDate IS NOT NULL
    GROUP BY New_RepoId

    IF OBJECT_ID('tempdb..#assetET') IS NOT NULL
      DROP TABLE #assetET
    SELECT
    DISTINCT
      ra.New_RepoId,
      [CRMReplication2013].dbo.StringMapValue(10058, 'New_EquipmentType', ec.New_EquipmentType) AS EquipmentType INTO #assetET
    FROM [CRMReplication2013].dbo.New_repoasset ra
    INNER JOIN [CRMReplication2013].dbo.New_equipmentcategory ec
      ON ra.New_repoassetId = ec.New_RepoAssetId

    IF OBJECT_ID('tempdb..#EqupTypes') IS NOT NULL
      DROP TABLE #EqupTypes
    SELECT DISTINCT
      RA2.New_RepoId,
      SUBSTRING((SELECT
        ',' + RA1.EquipmentType AS [text()]
      FROM #assetET RA1
      WHERE RA1.New_RepoId = RA2.New_RepoId
      ORDER BY RA1.New_RepoId
      FOR xml PATH ('')), 2, 1000) EquipTypes INTO #EqupTypes
    FROM #assetET RA2

    --IF OBJECT_ID('tempdb..#closedcomments') IS NOT NULL
    --  DROP TABLE #closedcomments
    --SELECT
    --  new_repoid,
    --  MAX(createdon) AS closedon INTO #closedcomments
    --FROM new_repocomment
    --WHERE new_commenttype = 4
    --GROUP BY new_repoid

    IF OBJECT_ID('tempdb..#settlements') IS NOT NULL
      DROP TABLE #settlements
    SELECT
      r.new_repoid,
      SUM(ISNULL(new_amount, 0)) AS settlementamount INTO #settlements
    FROM [CRMReplication2013].dbo.new_repo r
    LEFT JOIN (SELECT
      new_repoid,
      new_amount
    FROM [CRMReplication2013].dbo.new_repomisccost
    WHERE new_costtype = 2) c
      ON c.new_repoid = r.new_repoid
    GROUP BY r.new_repoid

    IF OBJECT_ID('tempdb..#Commission') IS NOT NULL
      DROP TABLE #Commission
    SELECT
      SUM(com.commission) AS commission,
      SUM(com.commissionpayback) AS commissionpayback,
      new_repoid INTO #Commission
    FROM [CRMReplication2013].dbo.new_repo
    CROSS APPLY [CRMReplication2013].[dbo].[RepoBuilder_GetRepoTotalOriginalCommission]([CRMReplication2013].dbo.new_repo.new_repoid) com
    GROUP BY new_repoid

    IF OBJECT_ID('tempdb..#Lease_Repo') IS NOT NULL
      DROP TABLE #Lease_Repo
    SELECT DISTINCT r.new_repoid,
      ln.value AS leaseno 
	INTO #Lease_Repo
    FROM [CRMReplication2013].dbo.new_repo r
    CROSS APPLY [CRMReplication2013].[dbo].[SG_Split_Custom](new_leaseno, ',') ln
	INNER JOIN CRMReplication2013.dbo.new_repoasset ra
	on r.new_repoid=ra.new_repoid
	
    IF OBJECT_ID('tempdb..#BeaconScore') IS NOT NULL
      DROP TABLE #BeaconScore
    SELECT
      lease_repo.new_repoid,
      AVG(bs.AVGBeaconScore) AS AVGBeaconScore INTO #BeaconScore
    FROM #Lease_Repo lease_repo
    INNER JOIN [CRMReplication2013].dbo.opportunity o
      ON o.CFSLeaseNumber = lease_repo.leaseno
    INNER JOIN [CRMReplication2013].dbo.vw_CRMCredit_BeaconScore bs
      ON bs.OppID = o.opportunityid
    GROUP BY lease_repo.new_repoid

    IF OBJECT_ID('tempdb..#FICOScore') IS NOT NULL
      DROP TABLE #FICOScore
    SELECT
      lease_repo.new_repoid,
      AVG(fs.AVGFICOScore) AS AVGFICOScore INTO #FICOScore
    FROM #Lease_Repo lease_repo
    INNER JOIN [CRMReplication2013].dbo.opportunity o
      ON o.CFSLeaseNumber = lease_repo.leaseno
    INNER JOIN [CRMReplication2013].dbo.vw_CRMCredit_FICOScore fs
      ON fs.OppID = o.opportunityid
    GROUP BY lease_repo.new_repoid

    DECLARE @cbdate AS date
    SET @cbdate = '01/20/2012'

    IF OBJECT_ID('tempdb..#crm') IS NOT NULL
      DROP TABLE #crm
    SELECT
      lease_repo.new_repoid,

      AVG(ot.new_irr) AS new_irr,
      AVG(OT.NEW_totalterm) AS NEW_totalterm,
      AVG(CASE
        WHEN o.createdon >= @cbdate THEN ot.new_amountfinanced - ISNULL(ot.NetDueToVendor, 0)
        ELSE CRMReplication2013.dbo.LoadLeaseAmount(o.OpportunityId)
      END) AS AmountFinanced INTO #crm
    FROM #Lease_Repo lease_repo
    INNER JOIN CRMReplication2013.dbo.opportunity o
      ON o.CFSLeaseNumber = lease_repo.leaseno
    LEFT JOIN (SELECT
      t.*,
      SUM(otv.New_VendorTotalEquipmentCost) AS NetDueToVendor
    FROM (SELECT
      new_opportunityid,
      new_opportunitytermid,
      new_totalterm,
      new_irr,
      new_termname,
      new_amountfinanced
    FROM CRMReplication2013.dbo.new_opportunityterm
    WHERE new_isinlcw = 1
    ) t
    LEFT JOIN (SELECT
      New_VendorTotalEquipmentCost,
      New_opportunitytermid
    FROM CRMReplication2013.dbo.New_opportunitytermvendor
    WHERE New_isuserselected = 1
   
    AND (New_AccountIdName IN (SELECT
      ExcludedVendorName COLLATE SQL_Latin1_General_CP1_CI_AS
    FROM CRMReplication2013.dbo.XCelsius_ExcludedVendors)
    )) otv
      ON t.new_opportunitytermid = otv.new_opportunitytermid
    GROUP BY t.New_opportunitytermid,
             new_irr,
             new_termname,
             new_amountfinanced,
             new_opportunityid,
             NEW_totalterm) ot
      ON o.opportunityid = ot.new_opportunityid

    GROUP BY lease_repo.new_repoid

    IF OBJECT_ID('tempdb..#LP') IS NOT NULL
      DROP TABLE #LP
    SELECT
      lease_repo.new_repoid,
      AVG(lp.lease_pmts_rem) AS PaymentRemaining,
      AVG(lp.lease_pmts_received) AS PaymentMade,
      AVG(CASE
        WHEN (lu.LeaseuserPercent1 > 0) THEN Lu.LeaseuserPercent1 / 100
        ELSE CONVERT(decimal(10, 2), lp.Lease_Yield / 100)
      END) AS IRR,
      AVG(lp.lease_term) AS originalTerm,

      CAST(AVG(CAST((CASE
        WHEN lp.lease_oldest_rent_due IS NOT NULL AND
          lp.lease_oldest_rent_due > '01/01/1900' THEN lp.lease_oldest_rent_due
        ELSE NULL

      END) AS float)) AS datetime) AS lease_oldest_rent_due,

      CAST(AVG(CAST((LastPaymentReceivedDate) AS float)) AS datetime) AS LastPaymentReceivedDate INTO #LP
    FROM #Lease_Repo lease_repo
    LEFT JOIN LINK_LEASEPLUS.LeasePlusv3.dbo.LPlusLeaseVW lp
      ON lease_repo.leaseno = lp.lease_num
    INNER JOIN LINK_LEASEPLUS.LeasePlusv3.dbo.LeaseDatabase LD
      ON ld.leasenum = lp.lease_num
    LEFT JOIN LINK_LEASEPLUS.LeasePlusV3.dbo.LeaseUser lu
      ON (ld.LeaseCompanyNum = lu.LeaseUserCompanyNum)
      AND (ld.LeaseNum = lu.LeaseUserLeaseNum)
    LEFT JOIN (SELECT
      invdtl_lease_num,
      MAX(invdtl_last_pmt_date) AS LastPaymentReceivedDate
    FROM LINK_LEASEPLUS.LeasePlusv3.dbo.LPlusOpenInvoiceDetailVW
    WHERE invdtl_inv_desc IN ('Lease Payment Due', 'Monthly Payment Due')
    AND invdtl_last_pmt_date < GETDATE()
    GROUP BY invdtl_lease_num) lpoidvw
      ON lp.lease_num = lpoidvw.invdtl_lease_num
    GROUP BY lease_repo.new_repoid

    IF OBJECT_ID('tempdb..#ColNotes') IS NOT NULL
    BEGIN
      DROP TABLE #ColNotes
    END
    SELECT
      COUNT(*) AS numOfCollectorComments,
      customerNumber INTO #ColNotes
    FROM (SELECT
      contact_hist_cust_id_num AS customerNumber,
      (CASE
        WHEN DATALENGTH(contact_hist_note) > 4000 THEN SUBSTRING(contact_hist_note, 1, 4000)
        ELSE contact_hist_note
      END
      ) AS Note,

      contact_hist_contact_name AS NoteOperator,
      CONVERT(varchar(100), contact_hist_call_date, 101) AS DateTimeStamp
    -- ,      contact_hist_result_code AS ResultCode     
    FROM LINK_LEASEPLUS.[LeasePlusv3].[dbo].LPlusCplusContactHistoryVW) note
    GROUP BY customerNumber

    --    IF @StateCode IS NULL
    --BEGIN
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

	IF OBJECT_ID('tempdb..#Lease_Repo_Sub') IS NOT NULL
    DROP TABLE #Lease_Repo_Sub
	SELECT lr.New_repoId AS [RepoGUID]
	,lr.leaseno AS [LeaseNumber]
	,abc.New_CreditManagerId AS [CreditManager]
	,abc.New_CreditManagerIdName AS [CreditManagerGUID]
	,abc.OwnerId AS [SalesPerson]
	,abc.OwnerIdName [SalesPersonGUID]
	INTO #Lease_Repo_Sub
	FROM #Lease_Repo lr
	INNER JOIN
	(
		SELECT t.New_CreditManagerId
		,t.New_CreditManagerIdName
		,o.ownerid
		,o.owneridname
		,o.CFSLeaseNumber
		FROM #otCTE_temp t
		INNER JOIN CRMReplication2013.dbo.opportunity o
		ON o.opportunityid=t.oppid
	) abc ON lr.leaseno = abc.CFSLeaseNumber

	IF OBJECT_ID('tempdb..#Lease_Repo_WithMultipleCreditManagersAndSalesmen') IS NOT NULL
    DROP TABLE #Lease_Repo_WithMultipleCreditManagersAndSalesmen
	SELECT DISTINCT MAIN.RepoGUID
	,Left(MAIN.LeaseNumber, Len(MAIN.LeaseNumber) - 1) AS LeaseNumber
	,Left(MAIN.CreditManagerGUID, Len(MAIN.CreditManagerGUID) - 1) AS CreditManagerGUID
	,Left(MAIN.CreditManager, Len(MAIN.CreditManager) - 1) AS CreditManager
	,Left(MAIN.SalesPersonGUID, Len(MAIN.SalesPersonGUID) - 1) AS SalesPersonGUID
	,Left(MAIN.SalesPerson, Len(MAIN.SalesPerson) - 1) AS SalesPerson
	INTO #Lease_Repo_WithMultipleCreditManagersAndSalesmen
	FROM
	(
		SELECT DISTINCT lrsOuter.RepoGUID AS RepoGUID
		,(
			SELECT DISTINCT lrsInner.LeaseNumber + ':' AS [text()]
			FROM #Lease_Repo_Sub lrsInner
			WHERE lrsInner.RepoGUID = lrsOuter.RepoGUID
			For XML PATH ('')
		)AS LeaseNumber
		,(
			SELECT DISTINCT lrsInner.CreditManagerGUID + ':' AS [text()]
			FROM #Lease_Repo_Sub lrsInner
			WHERE lrsInner.RepoGUID = lrsOuter.RepoGUID
			For XML PATH ('')
		) AS CreditManagerGUID
		,(
			SELECT DISTINCT CONVERT(nvarchar(100),lrsInner.CreditManager) + ':' AS [text()]
			FROM #Lease_Repo_Sub lrsInner
			WHERE lrsInner.RepoGUID = lrsOuter.RepoGUID
			For XML PATH ('')
		) AS CreditManager
		,(
			SELECT DISTINCT CONVERT(nvarchar(100),lrsInner.SalesPersonGUID) + ':' AS [text()]
			FROM #Lease_Repo_Sub lrsInner
			WHERE lrsInner.RepoGUID = lrsOuter.RepoGUID
			For XML PATH ('')
		)AS SalesPersonGUID
		,(
			SELECT DISTINCT CONVERT(nvarchar(100),lrsInner.SalesPerson) + ':' AS [text()]
			FROM #Lease_Repo_Sub lrsInner
			WHERE lrsInner.RepoGUID = lrsOuter.RepoGUID
			For XML PATH ('')
		)AS SalesPerson
		FROM #Lease_Repo_Sub lrsOuter
	) [MAIN]

    IF OBJECT_ID('tempdb..#final') IS NOT NULL
      DROP TABLE #final
    SELECT DISTINCT
      r.New_repoId AS RepoID
      ,r.New_Topic AS Topic
      ,r.New_AccountId AS AccountID
      ,a.name AS CompanyName
      ,a.address1_country AS DBA
      ,a.accountnumber AS CustomerNumber
      ,r.New_LeaseNo AS LeaseNumber
      ,[CRMReplication2013].dbo.StringMapValue(1, 'CFPaddress1_StateOrProvinceCode', a.CFPaddress1_StateOrProvinceCode) AS CustomerState
      ,COALESCE(r.New_AttorneyFirmIdName, '') + CASE
        WHEN r.New_AttorneyFirm2IdName IS NULL THEN ''
        ELSE ', ' + r.New_AttorneyFirm2IdName
      END AS Legal
      ,CAST(EqupTypes.EquipTypes AS nvarchar(500)) AS EquipTypes
      ,[CRMReplication2013].dbo.StringMapValue(10063, 'New_Type', r.New_Type) AS [Type]
      ,r.New_Type AS [TypeValue]
	  ,r.statecode AS [StateCode]
      ,r.statuscode
      ,[CRMReplication2013].dbo.StringMapValue(10063, 'statuscode', r.statuscode) AS [Status]
      ,r.new_reposalesstage AS SalesStageCode
      ,[CRMReplication2013].dbo.StringMapValue(10063, 'new_reposalesstage', r.new_reposalesstage) AS SalesStage
      ,COALESCE(assets.Number, 0) AS TotalAssets
      ,COALESCE(assetsSold.Number, 0) AS TotalAssetsSold
      ,CASE
        WHEN ISNULL(assets.Number, 0) = 0 THEN 0
        ELSE CAST(COALESCE(assetsSold.Number, 0) AS float) / CAST(COALESCE(assets.Number, 0) AS float)
      END AS AssetSoldPct
      ,COALESCE(assets.ListPrice, 0) AS ListPrice
      ,COALESCE(assets.estimatedsalesprice, 0) AS estimatedsalesprice
      ,r.New_NetInvestmentatDefault AS BVDefault
      ,r.New_EquipmentCost AS EquipmentCost
      ,CASE
        WHEN r.New_Type = 1 THEN r.New_NetInvestmentatDefault
        ELSE r.New_EquipmentCost
      END AS BVCost
      ,r.New_GainorLoss AS GainLoss
      ,r.New_NetGainorLoss AS NetGainLoss
      ,r.ownerid
      ,r.owneridname
      ,cast(ISNULL([CRMReplication2013].dbo.ConvertUTCToLocalTime(r.[new_RepoClosedOnDate]), NULL) as date) as closedon    
      ,r.new_repostartdate
      ,CASE
        WHEN r.[new_RepoClosedOnDate] IS NULL OR
          r.new_repostartdate IS NULL THEN NULL
        ELSE DATEDIFF(DAY, r.new_repostartdate, r.[new_RepoClosedOnDate])
      END AS repoDays
      ,r.new_totalexpenses AS totalExpenses
      ,r.new_miscexpensescredits AS miscexpensescredits
      ,r.new_breakeven AS breakeven
      ,r.new_proceedsfromsale AS proceedsfromsale
      ,r.new_totalcommission AS TotalSalesCommission
      ,r.new_profitopportunitycommission AS profitopportunitycommission
      ,bs.AVGBeaconScore AS [OriginalBeaconScore]
      ,fs.AVGFICOScore AS [OriginalFicoScore]
      ,bsRepo.AVGBeaconScore AS [RepoBeaconScore]
      ,fsRepo.AVGFICOScore AS [RepoFicoScore]
      ,CASE a.new_businessorigin
        WHEN NULL THEN NULL
        WHEN 2 THEN 0
        WHEN 1 THEN CASE aeb.New_BusinessStartDate
            WHEN NULL THEN NULL
            ELSE DATEDIFF(DAY, aeb.New_BusinessStartDate, GETDATE())
          END

      END AS tib
      ,pd.[USDS_12MonthPaydex] AS paydex

      --,key dates
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(r.CreatedOn) AS CreatedOn
      ,lp.lease_oldest_rent_due AS [oldestrentdue]
      ,DATEDIFF(DAY, lp.lease_oldest_rent_due, r.createdon) - 1 AS [DaysPastDueatRepo]
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(r.ModifiedOn) AS ModifiedOn
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.New_ListDate) AS ListDate
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.New_SoldDate) AS SoldDate
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.New_ActualPickup) AS ActualPickupDate
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.New_ScheduledPickup) AS ScheduledPickupDate
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.New_TransferableTitle) AS TransferableTitleDate
      ,[CRMReplication2013].dbo.ConvertUTCToLocalTime(assets.assetcreatedon) AS AssetCreatedOnDate
      ,settle.settlementamount AS [settlementreceived]
      ,lp.PaymentRemaining
      ,lp.PaymentMade
      ,lp.LastPaymentReceivedDate
      ,CASE
        WHEN r.New_Type = 1 AND
          sp.new_irr IS NULL THEN lp.IRR
        ELSE sp.new_irr
      END AS [IRR]
      ,AmountFinanced--LP.leaseAmt AS [LPleaseAmt]
      ,CASE
        WHEN r.New_Type = 1 AND
          sp.NEW_totalterm IS NULL THEN LP.originalTerm
        ELSE sp.NEW_totalterm
      END AS [Total Term]
      ,com.commission AS salesCommission
      ,com.commissionpayback AS commissionPayBack
      ,n.numOfCollectorComments
      ,New_ShareCreditId AS [SharedCredit1Guid]
      ,New_ShareCreditIdname AS [SharedCredit1] 
	  ,lrwmcmas.CreditManagerGUID AS CreditManagerGUID
	  ,lrwmcmas.CreditManager AS CreditManager
	  ,lrwmcmas.SalesPersonGUID AS SalesPersonGUID
	  ,lrwmcmas.SalesPerson AS SalesPerson
	  ,CAST(r.new_collectorid AS varchar(36)) AS CollectorGUID
      ,r.new_collectoridname AS Collector
         
      INTO #final
	  FROM [CRMReplication2013].dbo.new_repo r
	  INNER JOIN [CRMReplication2013].dbo.Account a
      ON r.New_AccountId = a.AccountId
	  LEFT JOIN #assets assets
	  ON r.New_repoId = assets.New_RepoId
	  LEFT JOIN #assetsSold assetsSold
	  ON r.New_repoId = assetsSold.New_RepoId
      LEFT JOIN #EqupTypes EqupTypes
	  ON r.New_RepoId = EqupTypes.New_RepoId
	  --LEFT JOIN #closedcomments closedcomments
	  --ON r.New_RepoId = closedcomments.New_RepoId
	  LEFT JOIN #BeaconScore bs
	  ON r.New_RepoId = bs.new_repoid
	  LEFT JOIN #FICOScore fs
	  ON r.New_RepoId = FS.new_repoid
	  LEFT JOIN [CRMReplication2013].dbo.vw_CRMCredit_BeaconScore_AllEntities bsRepo
	  ON bsRepo.entityid = r.new_repoid
	  LEFT JOIN [CRMReplication2013].dbo.vw_CRMCredit_FicoScore_AllEntities fsRepo
	  ON fsRepo.entityid = r.new_repoid
	  LEFT JOIN [CRMReplication2013].dbo.[vw_CRMCredit_PaydexScore] pd
	  ON pd.[accountid] = r.new_AccountID
	  LEFT JOIN [CRMReplication2013].dbo.AccountExtensionBase aeb
	  ON aeb.AccountId = r.new_accountid
	  LEFT JOIN #crm sp
      ON sp.new_repoid = r.new_repoid
	  LEFT JOIN #lp lp
	  ON lp.new_repoid = r.new_repoid
	  LEFT JOIN #settlements settle
	  ON settle.new_repoid = r.New_RepoId
      LEFT JOIN #Commission com
	  ON com.new_repoid = r.New_RepoId
	  LEFT JOIN #ColNotes n
	  ON n.customerNumber = a.accountnumber
	  LEFT JOIN #Lease_Repo_WithMultipleCreditManagersAndSalesmen lrwmcmas
	  ON lrwmcmas.RepoGUID = r.New_repoId
	  --ORDER BY r.[new_RepoClosedOnDate] DESC

    --TRUNCATE TABLE KeyStats_Repo_ClosedRepos_DailySnapShot
	INSERT INTO KeyStats_Repo_ClosedRepos_DailySnapShot
	  ([RepoID]
      ,[Topic]
      ,[AccountID]
      ,[CompanyName]
      ,[DBA]
      ,[CustomerNumber]
      ,[LeaseNumber]
      ,[CustomerState]
      ,[Legal]
      ,[EquipTypes]
      ,[Type]
      ,[TypeValue]
	  ,[StateCode]
      ,[statuscode]
      ,[Status]
      ,[SalesStageCode]
      ,[SalesStage]
      ,[TotalAssets]
      ,[TotalAssetsSold]
      ,[AssetSoldPct]
      ,[ListPrice]
      ,[estimatedsalesprice]
      ,[BVDefault]
      ,[EquipmentCost]
      ,[BVCost]
      ,[GainLoss]
      ,[NetGainLoss]
      ,[ownerid]
      ,[owneridname]
      ,[closedon]
      ,[new_repostartdate]
      ,[repoDays]
      ,[totalExpenses]
      ,[miscexpensescredits]
      ,[breakeven]
      ,[proceedsfromsale]
      ,[TotalSalesCommission]
      ,[profitopportunitycommission]
      ,[OriginalBeaconScore]
      ,[OriginalFicoScore]
      ,[RepoBeaconScore]
      ,[RepoFicoScore]
      ,[tib]
      ,[paydex]
      ,[CreatedOn]
      ,[oldestrentdue]
      ,[DaysPastDueatRepo]
      ,[ModifiedOn]
      ,[ListDate]
      ,[SoldDate]
      ,[ActualPickupDate]
      ,[ScheduledPickupDate]
      ,[TransferableTitleDate]
      ,[AssetCreatedOnDate]
      ,[settlementreceived]
      ,[PaymentRemaining]
      ,[PaymentMade]
      ,[LastPaymentReceivedDate]
      ,[IRR]
      ,[AmountFinanced]
      ,[TotalTerm]
      ,[salesCommission]
      ,[commissionPayBack]
      ,[numOfCollectorComments]
      ,[SharedCredit1Guid]
      ,[SharedCredit1]
      ,[SalesPersonGUID]
	  ,[SalesPerson]
	  ,[CreditManagerGUID]
	  ,[CreditManager]
	  ,[CollectorGUID]
	  ,[Collector]
	  )

	  SELECT f.*
      FROM #final f
      WHERE [statuscode]!=2 AND [StateCode] = 1 
	  --UNCOMMENT ABOVE LINE AFTER TESTING
END
GO
