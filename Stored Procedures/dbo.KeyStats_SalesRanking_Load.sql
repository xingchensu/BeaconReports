SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Mathew
-- Create date: 07/02/2015
-- Description:	To load the Sale Ranking data

-- TEST SP:		[dbo].[KeyStats_SalesRanking_Load] '1/1/2015', '11/23/2015'
-- =============================================

CREATE PROCEDURE [dbo].[KeyStats_SalesRanking_Load]
@FromDate AS DATE,
@ToDate AS DATE
AS
BEGIN

--DECLARE @FromDate AS DATE = '01/01/2015';
--DECLARE @ToDate AS DATE = '11/03/2015';

-- From & To date is for only three columns : 
-- 1. Current Year Origination
-- 2. Current Year TotalEquipUsedPrice
-- 3. Current Year Profit Opp
-- 4. Current Year Annualize
-- 5. Prior Year Annualized


-- === DATE RANGE VARIABLES : START =====
DECLARE @dateFrom1 AS DATE;
SET @dateFrom1 = CAST(CAST(YEAR(@FromDate) - 2 AS varchar(20)) + '/01/01' AS DATE);
DECLARE @dateTo1 AS DATE;
SET @dateTo1 = CAST(CAST(YEAR(@FromDate) - 2 AS varchar(20)) + '/12/31' AS DATE);

DECLARE @dateFrom2 AS DATE;
SET @dateFrom2 = CAST(CAST(YEAR(@FromDate) - 1 AS varchar(20)) + '/01/01' AS DATE);
DECLARE @dateTo2 AS DATE;
SET @dateTo2 = CAST(CAST(YEAR(@FromDate) - 1 AS varchar(20)) + '/12/31' AS DATE);

-- For Prior Year Annualized
DECLARE @dateFromPriorAnnualized AS DATE = CAST((YEAR(@FromDate) - 1) AS VARCHAR(20)) + '/01/01';
DECLARE @dateToPriorAnnualized AS DATE = CAST((YEAR(@FromDate) - 1) AS VARCHAR(20)) + '/' + CAST(MONTH(@ToDate) AS VARCHAR(20)) + '/' + CAST(DAY(@ToDate) AS VARCHAR(20));
-- === DATE RANGE VARIABLES : END =====


--===== CONSULTANT DATA :: START ===================
IF OBJECT_ID('tempdb..#Consultants') is not null  
BEGIN  
 drop table #Consultants
END
SELECT e.[fname],e.[lname], e.[fname] + ' ' + e.[lname] as [fullname],  e.[lname] + ', ' + e.[fname] as [fullname2],  
	[username],[userid],su.[SystemUserId] AS [CRMGuid], r.[IsMiscellaneous]
	INTO #Consultants
	FROM
	[dbo].[KeyStats_AllEmployees] e 
	INNER JOIN [dbo].[KeyStats_Category_Employee_Relation] r ON r.[CompanyID]=e.[Company] and r.[EmployeeID]=e.[UserID]
	INNER JOIN [dbo].[KeyStats_Categories] c ON c.[CategoryID]=r.[CategoryID]
	LEFT JOIN [CRMReplication2013].[dbo].[systemuser] su ON e.[username] = REPLACE(su.[DomainName],'ECS\','')
	where c.[CategoryID]=15
    order by e.[fname]
--===== CONSULTANT DATA :: END ===================

SELECT c.[fname]
, c.[lname]
, c.[fullname]
, c.[fullname2]
, c.[username]
, c.[userid]
, c.[CRMGuid]
, c.IsMiscellaneous

-- Secound Last Year Data
, oriSecLastYear.[OriginationSecLastYear]
, equipSecLastYear.[EquipUsedPriceSecLastYear]
, proOppSecLastYear.[ProfitOppSecLastYear]
, (ISNULL(oriSecLastYear.[OriginationSecLastYear], 0) + ISNULL(equipSecLastYear.[EquipUsedPriceSecLastYear], 0) + ISNULL(proOppSecLastYear.[ProfitOppSecLastYear], 0)) AS [TotalOriginationSecLastYear]

-- Last Year Data
, oriLastYear.[OriginationLastYear]
, equipLastYear.[EquipUsedPriceLastYear]
, proOppLastYear.[ProfitOppLastYear]
, (ISNULL(oriLastYear.[OriginationLastYear], 0) + ISNULL(equipLastYear.[EquipUsedPriceLastYear], 0) + ISNULL(proOppLastYear.[ProfitOppLastYear], 0)) AS [TotalOriginationLastYear]

-- Current Last Year Data
, oriCurrYear.[OriginationCurrYear]
, equipCurrYear.[EquipUsedPriceCurrYear]
, proOppCurrYear.[ProfitOppCurrYear]
, (ISNULL(oriCurrYear.[OriginationCurrYear], 0) + ISNULL(equipCurrYear.[EquipUsedPriceCurrYear], 0) + ISNULL(proOppCurrYear.[ProfitOppCurrYear], 0)) AS [TotalOriginationCurrYear]

-- Annualized
, currentYrAnnualized.[CurrentYrAnnualized]
, priorYrAnnualized.[PriorYrAnnualized]
, (ISNULL(currentYrAnnualized.[CurrentYrAnnualized], 0) - ISNULL(priorYrAnnualized.[PriorYrAnnualized], 0)) AS [AnnualizeDiff]
FROM #Consultants c

-- ============= SECOND LAST YEAR : START ==============================================
-- Origination for Second Last Year
LEFT JOIN (SELECT [consultantId], SUM(leaseAmt) 'OriginationSecLastYear'
FROM [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
WHERE acceptanceDate >= @dateFrom1 AND acceptanceDate <= @dateTo1
GROUP BY [consultantId]) oriSecLastYear ON oriSecLastYear.[consultantId] = c.[CRMGuid]
-- Equip Used Price for Second Last Year
LEFT JOIN (SELECT a.SalesRepID
	,SUM(a.equ_purch_price) AS 'EquipUsedPriceSecLastYear'
	FROM [EquipUsed].[dbo].[SalesDetails] a
	INNER JOIN [EquipUsed].[dbo].[EquipmentListings] b 
	ON a.[equ_id] = b.[equ_id]
	WHERE  a.[SoldDate] >= @dateFrom1 AND a.[SoldDate] <= @dateTo1 AND b.[equ_status] = 'R'
	GROUP BY a.[SalesRepID]) equipSecLastYear ON equipSecLastYear.[SalesRepID] = c.[userid]
-- Profit Opps Price for Second Last Year
LEFT JOIN (SELECT ra.[OwnerId]
, SUM(ra.[New_NetGainorLoss]) AS 'ProfitOppSecLastYear'
FROM [CRMReplication2013].[dbo].[new_repo] ra
WHERE ra.[New_Type] = 2 AND [OwnerId] IS NOT NULL
AND ra.[CreatedOn] >= @dateFrom1 AND ra.[CreatedOn] <= @dateTo1
GROUP BY [OwnerId]) proOppSecLastYear ON proOppSecLastYear.[OwnerId] = c.[CRMGuid]
-- ============= SECOND LAST YEAR : END ================================================


-- ============= LAST YEAR : START =====================================================
-- Origination for Last Year
LEFT JOIN (SELECT [consultantId], SUM(leaseAmt) 'OriginationLastYear'
FROM [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
WHERE acceptanceDate >= @dateFrom2 AND acceptanceDate <= @dateTo2
GROUP BY [consultantId]) oriLastYear ON oriLastYear.[consultantId] = c.[CRMGuid]
-- Equip Used Price for Last Year
LEFT JOIN (SELECT a.SalesRepID
	,SUM(a.equ_purch_price) AS 'EquipUsedPriceLastYear'
	FROM [EquipUsed].[dbo].[SalesDetails] a
	INNER JOIN [EquipUsed].[dbo].[EquipmentListings] b 
	ON a.[equ_id] = b.[equ_id]
	WHERE  a.[SoldDate] >= @dateFrom2 AND a.[SoldDate] <= @dateTo2 AND b.[equ_status] = 'R'
	GROUP BY a.[SalesRepID]) equipLastYear ON equipLastYear.[SalesRepID] = c.[userid]
-- Profit Opps Price for Last Year
LEFT JOIN (SELECT ra.[OwnerId]
, SUM(ra.[New_NetGainorLoss]) AS 'ProfitOppLastYear'
FROM [CRMReplication2013].[dbo].[new_repo] ra
WHERE ra.[New_Type] = 2 AND [OwnerId] IS NOT NULL
AND ra.[CreatedOn] >= @dateFrom2 AND ra.[CreatedOn] <= @dateTo2
GROUP BY [OwnerId]) proOppLastYear ON proOppLastYear.[OwnerId] = c.[CRMGuid]
-- ============= LAST YEAR : END =====================================================


-- ============= CURRENT YEAR : START ================================================
-- Origination for Current Year
LEFT JOIN (SELECT [consultantId], SUM(leaseAmt) 'OriginationCurrYear'
FROM [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
WHERE acceptanceDate >= @FromDate AND acceptanceDate <= @ToDate
GROUP BY [consultantId]) oriCurrYear ON oriCurrYear.[consultantId] = c.[CRMGuid]
-- Equip Used Price for Current Year
LEFT JOIN (SELECT a.SalesRepID
	,SUM(a.equ_purch_price) AS 'EquipUsedPriceCurrYear'
	FROM [EquipUsed].[dbo].[SalesDetails] a
	INNER JOIN [EquipUsed].[dbo].[EquipmentListings] b 
	ON a.[equ_id] = b.[equ_id]
	WHERE  a.[SoldDate] >= @FromDate AND a.[SoldDate] <= @ToDate AND b.[equ_status] = 'R'
	GROUP BY a.[SalesRepID]) equipCurrYear ON equipCurrYear.[SalesRepID] = c.[userid]
-- Profit Opps Price for Current Year
LEFT JOIN (SELECT ra.[OwnerId]
, SUM(ra.[New_NetGainorLoss]) AS 'ProfitOppCurrYear'
FROM [CRMReplication2013].[dbo].[new_repo] ra
WHERE ra.[New_Type] = 2 AND [OwnerId] IS NOT NULL
AND ra.[CreatedOn] >= @FromDate AND ra.[CreatedOn] <= @ToDate
GROUP BY [OwnerId]) proOppCurrYear ON proOppCurrYear.[OwnerId] = c.[CRMGuid]
-- ============= CURRENT YEAR : END ===================================================


-- ============= CURRENT YEAR ANNUALIZED : START ================================================
LEFT JOIN (SELECT [consultantId], ((SUM(leaseAmt) / (DATEDIFF(dd, @FromDate, @ToDate) + 1)) * (CASE WHEN (YEAR(@ToDate) % 4) = 0 THEN 366 ELSE 365 END)) 'CurrentYrAnnualized'
FROM [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
WHERE acceptanceDate >= @FromDate AND acceptanceDate <= @ToDate
GROUP BY [consultantId]) currentYrAnnualized ON currentYrAnnualized.[consultantId] = c.[CRMGuid]
-- ============= CURRENT YEAR ANNUALIZED : END ================================================


-- ============= PRIOR YEAR ANNUALIZED : START ================================================
LEFT JOIN (SELECT [consultantId], ((SUM(leaseAmt) / (DATEDIFF(dd, @dateFromPriorAnnualized, @dateToPriorAnnualized) + 1)) * (CASE WHEN (YEAR(@dateToPriorAnnualized) % 4) = 0 THEN 366 ELSE 365 END)) 'PriorYrAnnualized'
FROM [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
WHERE acceptanceDate >= @dateFromPriorAnnualized AND acceptanceDate <= @dateToPriorAnnualized
GROUP BY [consultantId]) priorYrAnnualized ON priorYrAnnualized.[consultantId] = c.[CRMGuid]
-- ============= PRIOR YEAR ANNUALIZED : END ================================================

END
GO
