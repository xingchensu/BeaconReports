SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Ruonan 04072015 - Load Repo asset records for key sales 
--[dbo].[KeyStats_Repo_Snapshot_LoadRepoExpense]1
CREATE PROCEDURE [dbo].[KeyStats_Repo_Snapshot_LoadRepoExpense]
AS
BEGIN

IF OBJECT_ID('tempdb..#Lease_Repo') IS NOT NULL
      DROP TABLE #Lease_Repo
SELECT DISTINCT r.new_repoid,
      ln.value AS leaseno 
	INTO #Lease_Repo
    FROM [CRMReplication2013].dbo.new_repo r
    CROSS APPLY [CRMReplication2013].[dbo].[SG_Split_Custom](new_leaseno, ',') ln
	INNER JOIN CRMReplication2013.dbo.new_repoasset ra
	on r.new_repoid=ra.new_repoid

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


	--TRUNCATE TABLE KeyStats_Repo_AllReposExpense_DailySnapShot
	INSERT INTO KeyStats_Repo_AllReposExpense_DailySnapShot(
	  [RepoExpenseID]
	  ,[RepoCompany]
      ,[new_repoid]
      ,[RepoID]
      ,[RepoTypeValue]
      ,[RepoType]
      ,[new_topic]
      ,[repoStatusCode]
      ,[RepoStatus]
      ,[ExpenseID]
      ,[StageValue]
      ,[expenseStage]
      ,[stage]
      ,[Type]
      ,[description]
      ,[Quantity]
      ,[UnitPrice]
      ,[new_expense]
      ,[Payee]
      ,[InvoiceID]
      ,[paymentstatus] 
      ,[owneridname]
      ,[closedon]
      ,[CustomerState]
      ,[CustomerStatecode]
      ,EquipTypes
	  ,[CollectorGUID]
	  ,[Collector]
	  ,[CreditManagerGUID]
	  ,[CreditManager]
	  ,[SalesPersonGUID]
	  ,[SalesPerson]
	  )
	SELECT
    re.NEW_REPOEXPENSEID,
    r.new_accountidname AS [RepoCompany],
    r.new_repoid,
    r.new_repoappid AS [RepoID],
    r.new_type AS RepoTypeValue,
    [CRMReplication2013].dbo.StringMapValue(10063, 'New_Type', r.New_Type) AS [RepoType],
    r.new_topic,
    r.statuscode AS repoStatusCode,
    [CRMReplication2013].dbo.StringMapValue(10063, 'statuscode', r.statuscode) AS [RepoStatus],
    re.new_expenseid AS [ExpenseID],
    re.new_expensetype AS [StageValue],
    [CRMReplication2013].dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype) AS [expenseStage],
    
    CASE LEFT ([CRMReplication2013].dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype),1)
		WHEN '1' THEN 'Recovery/Repo'
		WHEN '2' THEN 'Refurbish/Remarket'
		WHEN '3' THEN 'Sales/Overhead'
		WHEN '4' THEN 'Warranty'
	END AS [stage],
    --CHARINDEX( dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype) , ' - ')
	RIGHT ([CRMReplication2013].dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype), (LEN([CRMReplication2013].dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype))-4))
    AS[Type]
    
    --,CASE
    --  WHEN re.new_expensetype = 34 THEN 'Commission'
    --  WHEN re.new_expensetype = 35 THEN 'Crating'
    --  WHEN re.new_expensetype = 1 THEN 'Labor'
    --  WHEN re.new_expensetype = 4 THEN 'Legal'
    --  WHEN re.new_expensetype = 2 THEN 'Other'
    --  WHEN re.new_expensetype = 32 THEN 'Parts'
    --  WHEN re.new_expensetype = 5 THEN 'Shipping'
    --  WHEN re.new_expensetype = 36 THEN 'Storage'
    --  WHEN re.new_expensetype = 3 THEN 'Travel'

    --  WHEN re.new_expensetype = 37 THEN 'Commission'
    --  WHEN re.new_expensetype = 38 THEN 'Crating'
    --  WHEN re.new_expensetype = 7 THEN 'Labor'
    --  WHEN re.new_expensetype = 26 THEN 'Legal'
    --  WHEN re.new_expensetype = 12 THEN 'Other'
    --  WHEN re.new_expensetype = 10 THEN 'Parts'
    --  WHEN re.new_expensetype = 11 THEN 'Shipping'
    --  WHEN re.new_expensetype = 9 THEN 'Storage'
    --  WHEN re.new_expensetype = 28 THEN 'Travel'

    --  WHEN re.new_expensetype = 14 THEN 'Commission'
    --  WHEN re.new_expensetype = 18 THEN 'Crating'
    --  WHEN re.new_expensetype = 39 THEN 'Labor'
    --  WHEN re.new_expensetype = 40 THEN 'Legal'
    --  WHEN re.new_expensetype = 15 THEN 'Other'
    --  WHEN re.new_expensetype = 41 THEN 'Parts'
    --  WHEN re.new_expensetype = 17 THEN 'Shipping'
    --  WHEN re.new_expensetype = 42 THEN 'Storage'
    --  WHEN re.new_expensetype = 29 THEN 'Travel'  

    --  WHEN re.new_expensetype = 43 THEN 'Commission'
    --  WHEN re.new_expensetype = 44 THEN 'Crating'
    --  WHEN re.new_expensetype = 21 THEN 'Labor'
    --  WHEN re.new_expensetype = 45 THEN 'Legal'
    --  WHEN re.new_expensetype = 24 THEN 'Other'
    --  WHEN re.new_expensetype = 20 THEN 'Parts'
    --  WHEN re.new_expensetype = 23 THEN 'Shipping'
    --  WHEN re.new_expensetype = 46 THEN 'Storage'
    --  WHEN re.new_expensetype = 22 THEN 'Travel'
    --END AS [Type]
    
    ,re.new_description AS [description]
	,re.new_quantities AS [Quantity]
	,re.new_dollarperunit AS [UnitPrice]
	,re.new_expense
	,ri.new_accountidname AS [Payee]
	,ri.new_invoiceid AS [InvoiceID]
    ,[CRMReplication2013].dbo.StringMapValue(10070, 'new_paymentstatus',ri.new_paymentstatus) as [paymentstatus]

    --,case when  r.new_type =2  then r.[New_ShareCreditIdName] else null end as salesperson
    --,case when  r.new_type =2  then r.[New_ShareCreditId] else null end as salespersonID
	,r.[owneridname] as owneridname 
    ,cast(  ISNULL([CRMReplication2013].dbo.ConvertUTCToLocalTime(r.[new_RepoClosedOnDate]), NULL) as date) as closedon
    ,[CRMReplication2013].dbo.StringMapValue(1, 'CFPaddress1_StateOrProvinceCode',A.[CFPaddress1_StateOrProvinceCode]) AS [CustomerState]
	, A.[CFPaddress1_StateOrProvinceCode] as  [CustomerStatecode]
	,r_eqc.EquipmentType
	,r.[New_CollectorIdName] as Collector
    ,r.[New_CollectorId] as CollectorGUID
	,lrwmcmas.CreditManagerGUID
	,lrwmcmas.CreditManager
	,lrwmcmas.SalesPersonGUID
	,lrwmcmas.SalesPerson
	FROM [CRMReplication2013].dbo.new_repoexpense re
	LEFT JOIN #Lease_Repo_WithMultipleCreditManagersAndSalesmen lrwmcmas
	ON lrwmcmas.RepoGUID = re.new_RepoId
	INNER JOIN [CRMReplication2013].dbo.new_repo r
    ON re.new_repoid = r.new_repoid
    INNER JOIN [CRMReplication2013].dbo.ACCOUNT A ON A.ACCOUNTID=R.NEW_ACCOUNTID
	LEFT JOIN [CRMReplication2013].dbo.new_repoinvoice ri
    ON re.new_repoinvoiceid = ri.new_repoinvoiceid
    --left join 
    --(SELECT
    --new_repoid,
    --MAX(createdon) AS closedon
    --FROM new_repocomment
    --WHERE new_commenttype = 4
    --GROUP BY new_repoid)closedcomments
    --ON r.New_RepoId = closedcomments.New_RepoId
    LEFT JOIN
    (SELECT New_RepoId,EquipmentType FROM
		(SELECT
			ra.New_RepoId
			,[CRMReplication2013].dbo.StringMapValue(10058, 'New_EquipmentType', ec.New_EquipmentType) AS EquipmentType --INTO #assetET
			,ra.[New_OriginalEquipmentCost],ra.new_repoassetid  
			,RANK() OVER 
			(PARTITION BY ra.New_RepoId ORDER BY ra.[New_OriginalEquipmentCost] DESC,ra.new_repoassetid) AS [Rank]
	FROM [CRMReplication2013].dbo.New_repoasset ra
	INNER JOIN [CRMReplication2013].dbo.New_equipmentcategory ec
	ON ra.New_repoassetId = ec.New_RepoAssetId) r_eqcs
	WHERE [Rank]=1) r_eqc ON r_eqc.New_RepoId=r.New_RepoId
	--where --dbo.StringMapValue(10071, 'new_expensetype', re.new_expensetype) is null  
	--and ri.new_paymentstatus<>5
	--and   re.new_expense<=0

	--WHY THIS Update statement HERE?  Tony
	--UPDATE KeyStats_Repo_AllReposExpense_DailySnapShot
	--SET [Sales Person]=u.fullname
	--FROM KeyStats_Repo_AllReposExpense_DailySnapShot f
	--LEFT JOIN [CRMReplication2013].dbo.systemuser u
	--ON f.RepoSalesPersonGuid=u.systemuserid
END
GO
