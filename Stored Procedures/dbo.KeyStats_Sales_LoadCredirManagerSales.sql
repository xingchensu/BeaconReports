SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      Ruonan Wen				
-- Create date: 12/31/2015
-- Description:	Loads Key Stats Sales' credit 
--				manager View Data 
-- =============================================
--[KeyStats_Sales_LoadCredirManagerSales] '1/01/2015','12/22/2015',2
create PROCEDURE [dbo].[KeyStats_Sales_LoadCredirManagerSales] 
@DateFrom datetime,
@DateTo datetime,
@fundingMethod AS int = NULL,
@OutsideSalesID AS uniqueidentifier = NULL,
@InsideSalesID AS uniqueidentifier = NULL,
@CreditManagerID AS uniqueidentifier = NULL
AS


  DECLARE @MiscOutsideSalesID AS uniqueidentifier
  SET @MiscOutsideSalesID = '00000000-0000-0000-0000-000000000000'

  --Category ID
  DECLARE @categoryID AS int
  SET @categoryID = 13--fixed for credit manager

  --Employees Temp Table
  IF OBJECT_ID('tempdb..#employees') IS NOT NULL
  BEGIN
    DROP TABLE #employees
  END
  SELECT
    em.lname + ', ' + em.fname AS fullname,
    em.CRMGuid,
    em.username,
    em.UniqueUserId,
    em.userid,
    em.IntranetTable,
    CASE
      WHEN r.IsMiscellaneous = 0 THEN em.username
      ELSE 'Misc.'
    END AS username_group,
    CASE
      WHEN r.IsMiscellaneous = 0 THEN em.CRMGuid
      ELSE @MiscOutsideSalesID
    END AS CRMGuid_group,
    CASE
      WHEN r.IsMiscellaneous = 0 THEN em.lname + ', ' + em.fname
      ELSE 'Miscellaneous'
    END AS fullname_group,
    CASE
      WHEN r.IsMiscellaneous = 0 THEN em.UniqueUserId
      ELSE 999999999
    END AS UniqueUserId_group,
    CAST(startdate AS datetime) AS startdate,
    r.IsMiscellaneous INTO #employees
  FROM dbo.KeyStats_AllEmployees em
  INNER JOIN dbo.KeyStats_Category_Employee_Relation r
    ON r.UniqueUserId = em.UniqueUserId
  INNER JOIN dbo.KeyStats_Categories c
    ON r.CategoryID = c.CategoryID
  WHERE c.CategoryID = @categoryID

  DECLARE @mis_startdate AS date
  SELECT
    @mis_startdate = CAST(AVG(CAST(startdate AS float)) AS datetime)
  FROM #employees
  WHERE IsMiscellaneous = 1

  UPDATE #employees
  SET startdate = @mis_startdate
  WHERE IsMiscellaneous = 1

  DECLARE @avg_startdate AS date
  SELECT
    @avg_startdate = CAST(AVG(CAST(startdate AS float)) AS datetime)
  FROM #employees

  INSERT INTO #employees
    SELECT
      'BFC Tot.',
      NULL,
      'Beacon Funding Corporation Total',
      0,
      0,
      'Beacon',
      --for grouping
      'BFC Tot.' AS username_group,
      NULL AS CRMGuid_group,
      'Beacon Funding Corporation Total' fullname_group,
      1,
      @avg_startdate,
      NULL AS IsMiscellaneous
  --select * from #employees




  --convert to UTC
  SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom)
  SET @dateTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo)


  -- Annualized Rate Calculation
  DECLARE @daysOfCurrentYear AS float
  SET @daysOfCurrentYear = DATEPART(dy, DATEADD(dd, -1, DATEADD(yy, DATEDIFF(yy, 0, @DateTo) + 1, 0)))

  DECLARE @currentDaysOfYear AS float
  SET @currentDaysOfYear = DATEPART(dy, @DateTo)

  DECLARE @AnnualizedRate AS float
  SET @AnnualizedRate = @daysOfCurrentYear / @currentDaysOfYear

  -- ********** Accepted Opportunities (sales details data) **********

  IF OBJECT_ID('tempdb..#details') IS NOT NULL
  BEGIN
    DROP TABLE #details
  END
  CREATE TABLE #details (
    name varchar(300) NULL,
    opid [uniqueidentifier] NOT NULL,
    [Appid] [varchar](15) NULL,
    [companyName] [varchar](250) NULL,
    [repeatclient] [int] NULL,
    [FundingMethodValue] [tinyint] NULL,
    [FundingMethod] [varchar](200) NULL,
    [CreditManager] [varchar](200) NULL,
    [CreditManagerid] [uniqueidentifier] NULL,
    [acceptanceDate] [datetime2](2) NULL,
    [EquipmentCost] [money] NULL,
    [leaseAmt] [money] NULL,
    [NetVendorAmount] [money] NULL,
    [securityDeposit] [money] NULL,
    [payment] [money] NULL,
    [SD_Eligible] [bit] NULL,
    [initialCash] [money] NULL,
    [purchaseOption] [money] NULL,
    [PO_Eligible] [bit] NOT NULL,
    [TotalReferralFee] [money] NULL,
    [TotalReferralFeePts] [float] NULL,
    [oneoffProfit] [money] NULL,
    [oneoffProfitPts] [float] NULL,
    [IRR] [float] NULL,
    [AVGBeaconScore] [int] NULL,
    [AVGFICOScore] [int] NULL,
    [tib] [decimal](8, 2) NULL,
    [paydex] [int] NULL,
    [insideSales] [varchar](200) NULL,
    [insideSalesid] [uniqueidentifier] NULL,
    [consultant] [varchar](160) NULL,
    [consultantId] [uniqueidentifier] NOT NULL,
    OtherIncomeExpense money NULL
  )
  
  
  INSERT INTO #details
		(name,opid,
		[Appid],
		[companyName],
		[repeatclient],
		[FundingMethodValue],
		[FundingMethod],
		[CreditManager],
		[CreditManagerid],
		[acceptanceDate],
		[EquipmentCost],
		[leaseAmt],
		[NetVendorAmount],
		[securityDeposit],
		[payment],
		[SD_Eligible],
		[initialCash],
		[purchaseOption],
		[PO_Eligible],
		[TotalReferralFee],
		[TotalReferralFeePts],
		[oneoffProfit],
		[oneoffProfitPts],
		[IRR],
		[AVGBeaconScore],
		[AVGFICOScore],
		[tib],
		[paydex],
		[insideSales],
		[insideSalesid],
		[consultant],
		[consultantId],OtherIncomeExpense)
	SELECT name,opid,
		[Appid],
		[companyName],
		[repeatclient],
		[FundingMethodValue],
		[FundingMethod],
		[CreditManager],
		[CreditManagerid],
		[acceptanceDate],
		[EquipmentCost],
		[leaseAmt],
		[NetVendorAmount],
		[securityDeposit],
		[payment],
		[SD_Eligible],
		[initialCash],
		[purchaseOption],
		[PO_Eligible],
		[TotalReferralFee],
		[TotalReferralFeePts],
		[oneoffProfit],
		[oneoffProfitPts],
		[IRR],
		[AVGBeaconScore],
		[AVGFICOScore],
		[tib],
		[paydex],
		[insideSales],
		[insideSalesid],
		[consultant],
		[consultantId],OtherIncomeExpense
	FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot]
	WHERE acceptanceDate>=@DateFrom AND acceptanceDate<=@DateTo
	AND(FundingMethodValue=@fundingMethod OR @fundingMethod IS null)
	and(consultantId=@OutsideSalesID OR @OutsideSalesID IS null)
	AND (insideSalesid=@insideSalesID OR @insideSalesID IS null)
	
  -- ********** SELECT Sales Details **********

  SELECT
    name,
    opid,
    [companyName],
    [repeatclient],
    [FundingMethod],
    [CreditManager],
    [acceptanceDate],
    [EquipmentCost],
    [leaseAmt],
    [securityDeposit],
    [initialCash],
    [purchaseOption],
    [TotalReferralFee],
    [TotalReferralFeePts],
    [oneoffProfit],
    [oneoffProfitPts]*100 AS [oneoffProfitPts],
    [IRR]/100 AS IRR,
    [AVGBeaconScore],
    [AVGFICOScore],
    [tib],
    [paydex],
    [insideSales],
    [consultant] AS Owner
  FROM #details

  --CREDIT APPROVAL section
  IF OBJECT_ID('tempdb..#reviewedDeals') IS NOT NULL
  BEGIN
    DROP TABLE #reviewedDeals
  END
  CREATE TABLE #reviewedDeals (
  username_group VARCHAR(50) NULL,
    reviewedDeals int NULL
  )
  insert into #reviewedDeals
	(username_group,reviewedDeals)
  SELECT   
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group, 
  count(opportunityid)
  FROM [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
   INNER JOIN #employees em
    ON s.creditmanagerid = em.CRMGuid
  WHERE s.[Submission Date]>=@datefrom AND s.[Submission Date]<=@dateto
AND(FundingMethodValue=@fundingMethod OR @fundingMethod IS null)
	and (consultantId=@OutsideSalesID OR @OutsideSalesID IS null)
	AND (insideSalesid=@insideSalesID OR @insideSalesID IS null)
	 GROUP BY em.username_group WITH ROLLUP 
  

  IF OBJECT_ID('tempdb..#reviewedTerms') IS NOT NULL
  BEGIN
    DROP TABLE #reviewedTerms
  END
  CREATE TABLE #reviewedTerms (
   username_group VARCHAR(50) NULL,
    reviewedTerms int NULL
  )
 insert into #reviewedTerms(username_group,reviewedTerms)
  SELECT 
   CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group
  ,count(termid)
   FROM [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
    INNER JOIN #employees em
    ON s.creditmanagerid = em.CRMGuid
   WHERE s.reviewedOn>=@datefrom AND s.reviewedOn<=@dateto
AND(FundingMethodValue=@fundingMethod OR @fundingMethod IS null)
	and(consultantId=@OutsideSalesID OR @OutsideSalesID IS null)
	AND (insideSalesid=@insideSalesID OR @insideSalesID IS null)
	 GROUP BY em.username_group WITH ROLLUP
  
  


  IF OBJECT_ID('tempdb..#app') IS NOT NULL
  BEGIN
    DROP TABLE #app
  END
  CREATE TABLE #app (
    username_group VARCHAR(50) NULL,
    appPercent float NULL
  ) 
  
  insert into #app
(appPercent,username_group)
select 
 cast(sum(
    case when a.ApprovalDate is null or a.ApprovalDate> @DateTo  then 0
    else 1 end)  as float)/cast(sum(1) as float)
     as appPercent,
      CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group
     
  FROM (select * from [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] 
  WHERE [SubmitDate]>= DATEADD(YEAR, -1, @DateTo)
  AND [SubmitDate]<=@DateTo
  and (FundingMethodValue=@fundingMethod OR @fundingMethod IS null)
	and(consultantId=@OutsideSalesID OR @OutsideSalesID IS null)
	AND (insideSalesid=@insideSalesID OR @insideSalesID IS null)) s
  LEFT join   dbo.KeyStats_ApprovedOpportunity_HourlySnapshot  a
  on s.[opid]=a.[opid]
   INNER JOIN #employees em
    ON s.creditmanagerid = em.CRMGuid 
   GROUP BY em.username_group WITH ROLLUP
    
  
  IF OBJECT_ID('tempdb..#fund') IS NOT NULL
  BEGIN
    DROP TABLE #fund
  END
  CREATE TABLE #fund (
    username_group VARCHAR(50) NULL,
    fundPercent float NULL
  )
   insert into #fund
(fundPercent,username_group)
  select 
 cast(sum(
    case when f.FundDate is null or f.FundDate> @DateTo  then 0
    else 1 end)  as float)/cast(sum(1) as float)
     as fundPercent,
      CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group
     
  FROM (select * from [dbo].[KeyStats_ApprovedOpportunity_HourlySnapshot] 
  WHERE [ApprovalDate]>= DATEADD(YEAR, -1, @DateTo)
  AND [ApprovalDate]<=@DateTo
  and (FundingMethodValue=@fundingMethod OR @fundingMethod IS null)
	and(consultantId=@OutsideSalesID OR @OutsideSalesID IS null)
	AND (insideSalesid=@insideSalesID OR @insideSalesID IS null)) a
  LEFT join   dbo.KeyStats_FundOpportunity_HourlySnapshot  f
  on a.[opid]=f.[opid]
   INNER JOIN #employees em
    ON a.creditmanagerid = em.CRMGuid 
   GROUP BY em.username_group WITH ROLLUP
   
  




-- ********** Company Sales **********

IF OBJECT_ID('tempdb..#final') IS NOT NULL
BEGIN
	DROP TABLE #final
END;

WITH 
cte_accepted AS
	(SELECT
	 CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
			SUM(1) AS [totalCount],	--Number of Deals
			(SUM(1) * @AnnualizedRate) AS [annualizedTotalCount], --Annulaized totalCount
			SUM([EquipmentCost]) AS [EquipmentCost], --Equipment Cost
			SUM(CASE
						WHEN [FundingMethodValue] = 1 
							THEN [leaseAmt]
							ELSE 0
					END) AS [portfolioleaseAmt], --Portofolio Originations
			SUM(CASE
						WHEN [FundingMethodValue] = 1 
							THEN 1
							ELSE 0
					END) AS [portfolioCount], --Portofolio Count
			SUM(CASE
						WHEN [FundingMethodValue] = 1
							THEN 0
							ELSE [leaseAmt]
					END) AS [oneoffleaseAmt], --One-Off Originations
			SUM(CASE
						WHEN [FundingMethodValue] = 1 
							THEN 0
							ELSE 1
					END) AS [oneoffCount], --One-Off count
					case when SUM(isnull([leaseAmt],0))<=0 then null
					else					
			(SUM(CASE
						WHEN [FundingMethodValue] = 1 
							THEN [leaseAmt]
							ELSE 0
					END) / SUM(isnull([leaseAmt],0))) 
					end AS [portofolioOrigPercent], --Portfolio Origations %
					case when SUM(isnull([leaseAmt],0))<=0 then null
			else (SUM(CASE
						WHEN [FundingMethodValue] = 1
							THEN 0
							ELSE [leaseAmt]
					END) / SUM(isnull([leaseAmt],0))) 
					end AS [oneOffOrigPercent], --One Off Origations %
			SUM([leaseAmt]) AS [leaseAmt], --Total Originations
			SUM([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt], --Annualized Total Originations
			SUM(CASE
						WHEN [insideSalesid] is not NULL
							THEN [leaseAmt]
							ELSE 0
					END) AS [leaseAmtInsideSales], --Total Originations - Inside Sales

					case when SUM(isnull([leaseAmt],0))<=0 then null
					else
			(SUM(CASE
						WHEN [insideSalesid] is not NULL
							THEN [leaseAmt]
							ELSE 0
					END) / SUM(isnull([leaseAmt],0))) 
					end AS [leastAmtInsideSalesPercent], --Total Originations - Inside Sales %
			SUM([securityDeposit]) AS [securityDeposit], --Security Deposit $, regardless of eligibility
			case when (SUM(CASE
									WHEN [SD_Eligible] = 1
									THEN isnull([payment],0)
									ELSE 0
								END)*2)<=0 then null
								else
			(SUM(CASE
							WHEN [SD_Eligible] = 1
							THEN isnull([securityDeposit],0)+isnull(OtherIncomeExpense,0)-- Security Deposit % (ADD OTHER INCOME WITH SD_ELIGIBLE)
							ELSE 0
						END)
					/(SUM(CASE
									WHEN [SD_Eligible] = 1
									THEN isnull([payment],0)
									ELSE 0
								END)*2))
								end 
								 AS [securityDepositPercent], 
			case when SUM(isnull([NetVendorAmount],0))<=0 then null
			else
			(SUM([initialCash])/SUM(isnull([NetVendorAmount],0)))
			end AS [initialCashPercent], --Initial Cash %		

			SUM([purchaseOption]) AS [purchaseOption], --Purchase Option $
			case when 
			SUM(CASE
									WHEN [PO_Eligible] = 1
									THEN isnull([EquipmentCost],0)
									ELSE 0
								END)<=0 then null
								else
			(SUM(CASE
							WHEN [PO_Eligible] = 1
							THEN [purchaseOption]
							ELSE 0
							END)
					/SUM(CASE
									WHEN [PO_Eligible] = 1
									THEN isnull([EquipmentCost],0)
									ELSE 0
								END))
								end AS [purchaseOptionPercent], --Purchase Option %
			SUM([TotalReferralFee]) AS [TotalReferralFee], --Referral Fee $
			case when SUM(isnull([leaseAmt],0))<=0 then null
			else
			((SUM([TotalReferralFee])/SUM(isnull([leaseAmt],0))) * 100)
			end AS [totalReferralFeePts], --[TotalReferralFee] Referral Fee Points
			SUM([oneoffProfit]) AS [oneoffProfit], --One Off Profit $
			case when 
			SUM(CASE
									WHEN [FundingMethodValue] = 1
										THEN 0
										ELSE isnull([leaseAmt],0)
								END)<=0 then null
								else

			((SUM([oneoffProfit])/
						SUM(CASE
									WHEN [FundingMethodValue] = 1
										THEN 0
										ELSE isnull([leaseAmt],0)
								END))*100)
								end AS [oneOffProfitPts], --One Off Profit Pts
								case when
								SUM(CASE
									WHEN [FundingMethodValue] = 1 
										THEN isnull([leaseAmt],0)
										ELSE 0
								END)<=0 then null
							else	
			(SUM(CASE WHEN [FundingMethodValue]=1 THEN ([IRR]/100)*[leaseAmt] 
			ELSE 0 end)/
						SUM(CASE
									WHEN [FundingMethodValue] = 1 
										THEN isnull([leaseAmt],0)
										ELSE 0
								END)) 
								end AS [IRR] --[IRR] IRR Portofolio %
							,avg(AVGBeaconScore) as 	AVGBeaconScore
								,avg(AVGFICOScore) as 	AVGFICOScore
								,avg(tib) as 	tib
									,avg(cast(paydex as float)) as 	paydex
		FROM #details s
		INNER JOIN #employees em
    ON s.creditmanagerid = em.CRMGuid
  GROUP BY em.username_group WITH ROLLUP)

 



		select DISTINCT
    emp.username_group AS username,
      emp.CRMguid_group AS CRMguid,
        emp.fullname_group AS fullname,
         emp.UniqueUserId_group AS UniqueUserId,
    emp.startdate
    , cte_accepted.EquipmentCost ,
                cte_accepted.totalCount ,
                CAST(ROUND(cte_accepted.annualizedTotalCount, 0) AS INT) AS annualizedTotalCount ,
                CAST(ROUND(cte_accepted.portfolioleaseAmt, 0) AS INT) AS portfolioleaseAmt ,
                cte_accepted.portfolioCount ,
                CAST(ROUND(cte_accepted.oneoffleaseAmt, 0) AS INT) AS oneoffleaseAmt ,
                cte_accepted.oneoffCount ,
                ROUND(cte_accepted.portofolioOrigPercent, 2) AS portofolioOrigPercent ,
                ROUND(cte_accepted.oneOffOrigPercent, 2) AS oneOffOrigPercent ,
                CAST(ROUND(cte_accepted.leaseAmt, 0) AS INT) AS leaseAmt ,
                CAST(ROUND(cte_accepted.annualizedLeaseAmt, 0) AS INT) AS annualizedLeaseAmt ,
                CAST(ROUND(cte_accepted.leaseAmtInsideSales, 0) AS INT) AS leaseAmtInsideSales ,
                ROUND(cte_accepted.leastAmtInsideSalesPercent, 2) AS leastAmtInsideSalesPercent ,
                CAST(ROUND(cte_accepted.securityDeposit, 0) AS INT) AS securityDeposit ,
                ROUND(cte_accepted.securityDepositPercent, 4) AS securityDepositPercent ,
                CAST(ROUND(cte_accepted.purchaseOption, 0) AS INT) AS purchaseOption ,
                ROUND(cte_accepted.purchaseOptionPercent, 4) AS purchaseOptionPercent ,
                ROUND(cte_accepted.initialCashPercent, 4) initialCashPercent ,
                CAST(ROUND(cte_accepted.TotalReferralFee, 0) AS INT) AS TotalReferralFee ,
                ROUND(cte_accepted.totalReferralFeePts, 2) totalReferralFeePts ,
                CAST(ROUND(cte_accepted.oneoffProfit, 0) AS INT) AS oneoffProfit ,
                ROUND(cte_accepted.oneOffProfitPts, 2) oneOffProfitPts ,
                ROUND(cte_accepted.IRR, 4) IRR ,
                cte_accepted.AVGBeaconScore ,
                cte_accepted.AVGFICOScore ,
                CAST(ROUND(cte_accepted.tib, 2) AS DECIMAL(8, 2)) AS tib ,
                ROUND(cte_accepted.paydex, 2) AS paydex ,
                rd.reviewedDeals AS UniqueDealsReviewed,
                rt.reviewedTerms AS TermsSubmitted
                ,   CASE WHEN rd.reviewedDeals > 0
                     THEN ROUND(CAST (rt.reviewedTerms AS FLOAT)
                                / CAST(rd.reviewedDeals AS FLOAT),
                                2)
                     ELSE NULL
                END AS submissionPerDeal ,
                app.appPercent, fund.fundPercent
                 
    INTO #final
  FROM #employees emp
  LEFT JOIN cte_accepted 
    ON cte_accepted.username_group = emp.username_group
    LEFT JOIN #reviewedDeals rd
    ON rd.username_group=emp.username_group
    LEFT JOIN #reviewedTerms rt
    ON rt.username_group=emp.username_group
    LEFT JOIN #app app
    ON app.username_group=emp.username_group
     LEFT JOIN #fund fund
    ON fund.username_group=emp.username_group  
    
    SELECT * FROM #final
    
   
--KeyStats_Sales_LoadCredirManagerSales '1/01/2015','12/22/2015'
GO
