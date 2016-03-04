SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Ruonan 04072015 - Load Repo asset records for key sales 
--[dbo].[KeyStats_Repo_Snapshot_LoadAllAssets]1,'10/13/2015'
CREATE PROCEDURE [dbo].[KeyStats_Repo_Snapshot_LoadAllAssets]
AS
BEGIN
-----------------------------------------------
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

-----------------------------------------------
IF OBJECT_ID('tempdb..#final') IS NOT NULL
      DROP TABLE #final
SELECT
 r.new_repoid
 ,r.new_repoappid
 ,r.new_type as RepoTypeValue
 ,CRMReplication2013.dbo.StringMapValue(10063, 'New_Type', r.New_Type) AS [RepoType]
 ,r.new_topic
 ,r.statuscode as repoStatusCode       
 ,CRMReplication2013.dbo.StringMapValue(10063, 'statuscode', r.statuscode) AS [RepoStatus]
 ,ra.new_repoassetid
 ,ra.new_assetuid as AssetID
 ,ra.new_repoassetno as AssetNo
 ,ec.New_EquipmentType as EquipmentCategoryValue
 ,CRMReplication2013.dbo.StringMapValue(10058, 'New_EquipmentType', ec.New_EquipmentType) AS EquipmentCategory
 ,ra.New_OwnershipType
 ,CRMReplication2013.dbo.StringMapValue(10064, 'new_ownershiptype', ra.new_ownershiptype) AS [AssetRelationship]
 ,ra.new_year
 ,ra.new_make,ra.new_model
 ,ra.new_description
 ,ra.new_salestage
 ,case when r.new_type =2 then CRMReplication2013.dbo.StringMapValue(10064, 'new_salestage', ra.new_salestage)
 else case when  ra.new_salestage=4 then 'Settlement' else CRMReplication2013.dbo.StringMapValue(10064, 'new_salestage', ra.new_salestage) 
 end 
 end AS [salestage/Status]
 ,ra.new_originalequipmentcost as [OrigEquip]
 ,case when isnull( r.New_EquipmentCost,0)<>0 then
 isnull( ra.new_originalequipmentcost* cast (r.New_NetInvestmentatDefault as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 else 0 end  as [DefaultBV]
 ,isnull(ra.new_estimatedsalesprice,0) as estimatedsalesprice
 ,equipused.equ_id
 ,isnull(equipused.listPrice,0) as [List]
 ,case when equipused.equ_status ='c' then 1 else 0 end as [ContractPendingFlag]
 ,case when ra.new_parentrepoassetid is null then 0 else 1 end as [IsChildAsset]
 ,equipused.salesprice as [SALEPRICE]
 ,equipused.[TotalCommission] as EUCommission
 ,case when isnull( r.New_EquipmentCost,0)<>0 then
 isnull( ra.new_originalequipmentcost* cast (r.[New_TotalExpenses] as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 else 0 end as [ProratedExpenses]
 ,case when isnull( r.New_EquipmentCost,0)<>0 then
 isnull( ra.new_originalequipmentcost* cast (r.[New_MiscExpensesCredits] as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 else 0 end as [ProratedMiscExpensesCredits]
 ,case when isnull( r.New_EquipmentCost,0)<>0 then 
 isnull( ra.new_originalequipmentcost* cast (r.[New_SettlementCost] as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 else 0 end as [ProratedSettlementCost]
 ,CASE WHEN ISNULL(new_settlementcommission,0)=0 AND ISNULL(new_eucommission,0)<>0 THEN 'EU COMMISSION'
 WHEN  ISNULL(new_settlementcommission,0)<>0 AND ISNULL(new_eucommission,0)=0 THEN 'Settlement COMMISSION'
 WHEN  ISNULL(new_settlementcommission,0)<>0 AND ISNULL(new_eucommission,0)<>0 THEN 'Settlement and EU COMMISSION'
 else 'No Sales Commission'
 end as [SalesCommissionType]  
 ,CASE WHEN ISNULL(new_settlementcommission,0)=0 AND ISNULL(new_eucommission,0)<>0 THEN isnull(equipused.[TotalCommission],0) 
 WHEN  ISNULL(new_settlementcommission,0)<>0 AND ISNULL(new_eucommission,0)=0 THEN 
 case when isnull( r.New_EquipmentCost,0)<>0 then
 isnull( ra.new_originalequipmentcost* cast (r.new_settlementcommission as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 else 0 end 
 WHEN ISNULL(new_settlementcommission,0)<>0 AND ISNULL(new_eucommission,0)<>0 THEN
 case when isnull( r.New_EquipmentCost,0)<>0 then
 isnull( ra.new_originalequipmentcost* cast (r.new_settlementcommission as decimal)/cast( r.New_EquipmentCost as decimal),0) 
 +isnull( equipused.[TotalCommission] ,0)
 else isnull( equipused.[TotalCommission] ,0) end 
 else 0
 end as [ProratedSalesCommission]  
 ,r.[owneridname] as owneridname
 ,cast(ISNULL(CRMReplication2013.dbo.ConvertUTCToLocalTime(r.[new_RepoClosedOnDate]), NULL) as date) as closedon
 ,CRMReplication2013.dbo.StringMapValue(1, 'CFPaddress1_StateOrProvinceCode',A.[CFPaddress1_StateOrProvinceCode]) AS [CustomerState]
 , A.[CFPaddress1_StateOrProvinceCode] as  [CustomerStatecode]
 ,ra.createdon
 ,r.[New_CollectorIdName] as Collector
 ,r.[New_CollectorId] as CollectorGUID
 ,lrwmcmas.CreditManagerGUID
 ,lrwmcmas.CreditManager
 ,lrwmcmas.SalesPersonGUID
 ,lrwmcmas.SalesPerson
 INTO #final
 FROM CRMReplication2013.dbo.new_repoasset ra
 LEFT JOIN #Lease_Repo_WithMultipleCreditManagersAndSalesmen lrwmcmas --tony addition
 ON lrwmcmas.RepoGUID = ra.New_RepoId --tony addition
 INNER JOIN CRMReplication2013.dbo.new_repo r
 on ra.new_repoid=r.new_repoid
 INNER JOIN CRMReplication2013.dbo.ACCOUNT A 
 ON A.ACCOUNTID=R.NEW_ACCOUNTID
 LEFT JOIN CRMReplication2013.dbo.New_equipmentcategory ec
 ON ra.New_repoassetId = ec.New_RepoAssetId
 LEFT JOIN 
	(SELECT repoAsset_id,l.equ_id as equ_id ,
	l.equ_ask_price as listPrice, SUM(sd.equ_purch_price) as salesprice, equ_status
	,SUM(sd.[TotalCommission]) as [TotalCommission]
	FROM EquipUsed.dbo.EquipmentListings_RepoAsset_Mapping m
 INNER JOIN EquipUsed.dbo.EquipmentListings l
 ON m.equ_id = l.equ_id
 LEFT JOIN EquipUsed.dbo.SalesDetails sd 
 ON sd.equ_id=l.equ_id
 GROUP BY repoAsset_id,l.equ_id,equ_status, l.equ_ask_price) equipused
 ON ra.New_repoassetId = equipused.repoAsset_id
 --where a.accountid<>'BEA6D5EA-8339-E211-B356-78E7D1F817F8'
 ORDER BY r.new_repoid,ra.new_assetuid

 --WHY IS THIS Update statement here? Tony
--UPDATE KeyStats_Repo_AllReposAssets_DailySnapShot
-- set [Sales Person]=u.fullname
-- from KeyStats_Repo_AllReposAssets_DailySnapShot f
-- left join CRMReplication2013.dbo.systemuser u
-- on f.RepoSalesPersonGuid=u.systemuserid
TRUNCATE TABLE KeyStats_Repo_AllOpenReposAssets_DailySnapShot
TRUNCATE TABLE KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot
-- INSERT INTO KeyStats_Repo_AllReposAssets_DailySnapShot
--([new_repoid]
--      ,[new_repoappid]
--      ,[RepoTypeValue]
--      ,[Repo Type]
--      ,[new_topic]
--      ,[repoStatusCode]
--      ,[Repo Status]
--      ,[new_repoassetid]
--      ,[AssetID]
--      ,[AssetNo]
--      ,[EquipmentCategoryValue]
--      ,[EquipmentCategory]
--      ,[new_ownershiptype]
--      ,[Asset Relationship]
--      ,[new_year]
--      ,[new_make]
--      ,[new_model]
--      ,[new_description]
--      ,[new_salestage]
--      ,[salestage/Status]
--      ,[Orig. Equip $]
--      ,[Default BV$]
--      ,[estimatedsalesprice]
--      ,[equ_id]
--      ,[$ List]
--      ,[Contract Pending Flag]
--      ,[Is Child Asset]
--      ,[SALE PRICE]
--      ,[EUCommission]
--      ,[Prorated Expenses]
--      ,[Prorated MiscExpensesCredits]
--      ,[Prorated SettlementCost]
--      ,[Sales Commission Type]
--      ,[Prorated Sales Commission]
--      ,[owneridname]
--      ,[closedon]
--      ,[Customer State]
--      ,[Customer State code]
--      ,CreatedOn
--	  ,[Collector]
--      ,[CollectorGUID]
--	  ,[CreditManagerGUID]
--	  ,[CreditManager]
--	  ,[SalesPersonGUID]
--	  ,[SalesPerson]
--	  )
--      select * from #final
 INSERT INTO KeyStats_Repo_AllOpenReposAssets_DailySnapShot
([new_repoid]
      ,[new_repoappid]
      ,[RepoTypeValue]
      ,[RepoType]
      ,[new_topic]
      ,[repoStatusCode]
      ,[RepoStatus]
      ,[new_repoassetid]
      ,[AssetID]
      ,[AssetNo]
      ,[EquipmentCategoryValue]
      ,[EquipmentCategory]
      ,[new_ownershiptype]
      ,[AssetRelationship]
      ,[new_year]
      ,[new_make]
      ,[new_model]
      ,[new_description]
      ,[new_salestage]
      ,[salestageStatus]
      ,[OrigEquip]
      ,[DefaultBV]
      ,[estimatedsalesprice]
      ,[equ_id]
      ,[List]
      ,[ContractPendingFlag]
      ,[IsChildAsset]
      ,[SALEPRICE]
      ,[EUCommission]
      ,[ProratedExpenses]
      ,[ProratedMiscExpensesCredits]
      ,[ProratedSettlementCost]
      ,[SalesCommissionType]
      ,[ProratedSalesCommission]
      ,[owneridname]
      ,[closedon]
      ,[CustomerState]
      ,[CustomerStatecode]
      ,CreatedOn
	  ,[Collector]
      ,[CollectorGUID]
	  ,[CreditManagerGUID]
	  ,[CreditManager]
	  ,[SalesPersonGUID]
	  ,[SalesPerson]
	  )
      select f.* from #final f where f.[repoStatusCode]=1


 INSERT INTO KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot
	  ([new_repoid]
      ,[new_repoassetid]
      ,[EUAdminStatus]
      ,[ListEstimatedValue]
      ,[BVCost]
      ,[ListEstimatedTotalValue]
      ,[EstNetGainLoss]
      ,[RepoTypeValue]
      ,[State]
      ,[EquipmentCategory]
      ,[CollectorGUID]
      ,[Collector]
      ,[CreditManagerGUID]
      ,[CreditManager]
      ,[SalesPersonGUID]
      ,[SalesPerson]
      --,[SnapshotDate]
	  )
	SELECT 
	aora.new_repoid 
	,aora.[new_repoassetid]     
	,case when aora.new_salestage=1 or aora.new_salestage=2 then 'Pending'
		when aora.new_salestage=3 and aora.[ContractPendingFlag]=0 then 'Available'
		when aora.new_salestage=3 and aora.[ContractPendingFlag]=1 then 'Contract Pending'
		when aora.new_salestage=4 then 'Completed Repo' else null  end as [EU Admin Status]     
	,case when aora.[SALEPRICE] is not null and aora.[SALEPRICE]>0 then aora.[SALEPRICE] else 
	case when aora.[List] is not null and aora.[List]>0 then aora.[List] else aora.[estimatedsalesprice] end end as [ListEstimatedValue]
	,case when aora.[RepoTypeValue]=1 then aora.[DefaultBV] else aora.[OrigEquip] end as [BVCost]
	,case when aora.[estimatedsalesprice]>aora.[List] then aora.[estimatedsalesprice] else aora.[List] end AS [ListEstimatedTotalValue]
	,[CRMReplication2013].[dbo].[RepoBuilder_CalculateEstimatedGainLoss](new_repoid) AS [EstNetGainLoss]
	,aora.[RepoTypeValue] AS [RepoTypeValue]
	,aora.[CustomerState] AS [State]
	,aora.[EquipmentCategory] AS [EquipmentCategory]
	,aora.[CollectorGUID]
	,aora.[Collector]
	,aora.[CreditManagerGUID]
	,aora.[CreditManager]
	,aora.[SalesPersonGUID]
	,aora.[SalesPerson]
	--,aora.SnapshotDate

	FROM [dbo].[KeyStats_Repo_AllOpenReposAssets_DailySnapShot] aora
	WHERE aora.new_repoid <>'FE414B07-B645-E411-9B4D-78E7D1F817F8'
	and aora.[IsChildAsset]=0
	and aora.new_salestage<>5 and new_salestage<>6
	and aora.repoStatusCode=1
END
GO
