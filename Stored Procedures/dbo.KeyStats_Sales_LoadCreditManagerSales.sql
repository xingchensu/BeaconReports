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
--[KeyStats_Sales_LoadCreditManagerSales]'1/01/2015','12/22/2015',null,null,null,'4044781a-b204-e011-b009-78e7d1f817f8'
CREATE PROCEDURE [dbo].[KeyStats_Sales_LoadCreditManagerSales] 
@DateFrom datetime,
@DateTo datetime,
@fundingMethod AS int = NULL,
@OutsideSalesID AS uniqueidentifier = NULL,
@InsideSalesID AS uniqueidentifier = NULL,
@CreditManagerID AS uniqueidentifier = NULL
AS


  DECLARE @MiscCreditManagerID AS uniqueidentifier
  SET @MiscCreditManagerID = '00000000-0000-0000-0000-000000000000'

  --Category ID
  DECLARE @categoryID AS int
  SET @categoryID = 13--fixed for credit manager

  --Employees Temp Table
  IF OBJECT_ID('tempdb..#employees') IS NOT NULL
  BEGIN
    DROP TABLE #employees
  END
  CREATE TABLE #employees (
    [Index] int,
    --LastName varchar(50),
    --fullname varchar(100),
    CRMGuid uniqueidentifier,
    username varchar(50),
    --UniqueUserId int,
    UserID int,
    IntranetTable varchar(10),
    lastname_group varchar(50),
    username_group varchar(50),
    CRMGuid_group uniqueidentifier,
    fullname_group varchar(100),
    --UniqueUserId_group int,
    startdate datetime,
    IsMiscellaneous bit
  )

  INSERT INTO #employees (
  --LastName,
  --fullname,
  CRMGuid,
  username,
  --UniqueUserId,
  UserID,
  IntranetTable,
  lastname_group,
  username_group,
  CRMGuid_group,
  fullname_group,
  --UniqueUserId_group,
  startdate,
  IsMiscellaneous)
    SELECT
      --em.LName AS LastName,
      --em.lname + ', ' + em.fname AS fullname,
      em.CRMGuid,
      em.username,
      --em.UniqueUserId,
      em.userid,
      em.IntranetTable,
      CASE
        WHEN r.IsMiscellaneous = 0 THEN em.LName
        ELSE 'Misc.'
      END AS lastname_group,
      CASE
        WHEN r.IsMiscellaneous = 0 THEN em.username
        ELSE 'Misc.'
      END AS username_group,
      CASE
        WHEN r.IsMiscellaneous = 0 THEN em.CRMGuid
        ELSE @MiscCreditManagerID
      END AS CRMGuid_group,
      CASE
        WHEN r.IsMiscellaneous = 0 THEN em.lname + ', ' + em.fname
        ELSE 'Miscellaneous'
      END AS fullname_group,
      --CASE
      --  WHEN r.IsMiscellaneous = 0 THEN em.UniqueUserId
      --  ELSE 999999999
      --END AS UniqueUserId_group,
      CAST(startdate AS datetime) AS startdate,
      r.IsMiscellaneous
    FROM dbo.KeyStats_AllEmployees em
    INNER JOIN dbo.KeyStats_Category_Employee_Relation r
      ON r.UniqueUserId = em.UniqueUserId
    INNER JOIN dbo.KeyStats_Categories c
      ON r.CategoryID = c.CategoryID
    WHERE c.CategoryID = @categoryID
  ;
  WITH cte_emp
  AS (SELECT
    username,
    ROW_NUMBER() OVER (ORDER BY lastname_group) + 1 AS RowNum
  FROM #employees
  WHERE IsMiscellaneous = 0)
  UPDATE #employees
  SET #employees.[Index] = cte_emp.RowNum
  FROM #employees
  INNER JOIN cte_emp
    ON #employees.username = cte_emp.username

  DECLARE @mis_startdate AS date
  SELECT
    @mis_startdate = CAST(AVG(CAST(startdate AS float)) AS datetime)
  FROM #employees
  WHERE IsMiscellaneous = 1

  UPDATE #employees
  SET startdate = @mis_startdate
  WHERE IsMiscellaneous = 1


  UPDATE #employees
  SET [Index] = (SELECT MAX([Index]) + 1 FROM #employees WHERE IsMiscellaneous = 0)
  WHERE IsMiscellaneous = 1
  
  DECLARE @avg_startdate AS date
  SELECT
    @avg_startdate = CAST(AVG(CAST(startdate AS float)) AS datetime)
  FROM #employees

  INSERT INTO #employees ([Index],
  --LastName,
  --fullname,
  CRMGuid,
  username,
  --UniqueUserId,
  UserID,
  IntranetTable,
  lastname_group,
  username_group,
  CRMGuid_group,
  fullname_group,
  --UniqueUserId_group,
  startdate,
  IsMiscellaneous)
    SELECT
      0,
      --'BFC Tot.',
      --'BFC Tot.',
      NULL,
      'Beacon Funding Corporation Total',
      --0,
      0,
      'Beacon',
      --for grouping
      'BFC Tot.' AS lastname_group,
      'BFC Tot.' AS username_group,
      NULL AS CRMGuid_group,
      'Beacon Funding Corporation Total' fullname_group,
      --1,
      @avg_startdate,
      NULL AS IsMiscellaneous
  --select * from #employees


  DECLARE @CreditManager AS varchar(160)
  IF @CreditManagerID IS NOT NULL
  BEGIN
    SELECT
      @CreditManager = fullname_group
    FROM #employees
    WHERE CRMGuid_group = @CreditManagerID
  END

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
    OtherIncomeExpense money NULL,
        [CreditManagerid_group] [uniqueidentifier] NULL
  )


  INSERT INTO #details (name, opid,
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
  [consultantId], OtherIncomeExpense,CreditManagerid_group)
    SELECT
      s.name,
     s. opid,
     s. [Appid],
      s.[companyName],
      s.[repeatclient],
     s. [FundingMethodValue],
     s. [FundingMethod],
     s. [CreditManager],
     s. [CreditManagerid],
      s.[acceptanceDate],
      s.[EquipmentCost],
     s. [leaseAmt],
     s. [NetVendorAmount],
     s. [securityDeposit],
     s. [payment],
      s.[SD_Eligible],
      s.[initialCash],
      s.[purchaseOption],
      s.[PO_Eligible],
      s.[TotalReferralFee],
      s.[TotalReferralFeePts],
      s.[oneoffProfit],
     s. [oneoffProfitPts],
     s. [IRR],
     s. [AVGBeaconScore],
     s. [AVGFICOScore],
     s. [tib],
     s. [paydex],
    s.  [insideSales],
     s. [insideSalesid],
      s.[consultant],
      s.[consultantId],
      s.OtherIncomeExpense,
      e.CRMGuid_group
    FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot]s
    LEFT JOIN #employees e
    ON s.CreditManagerid=e.CRMGuid
    WHERE s.acceptanceDate >= @DateFrom
    AND s.acceptanceDate <= @DateTo
    AND (s.FundingMethodValue = @fundingMethod
    OR @fundingMethod IS NULL)
    AND (s.consultantId = @OutsideSalesID
    OR @OutsideSalesID IS NULL)
    AND (s.insideSalesid = @insideSalesID
    OR @insideSalesID IS NULL)

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
      [oneoffProfitPts] * 100 AS [oneoffProfitPts],
      [IRR] / 100 AS IRR,
      [AVGBeaconScore],
      [AVGFICOScore],
      [tib],
      [paydex],
      [insideSales],
      [consultant] AS Owner
    FROM #details
    WHERE CreditManagerid_group=@CreditManagerID OR @CreditManagerID IS NULL
    
    

  --CREDIT APPROVAL section
  IF OBJECT_ID('tempdb..#reviewedDeals') IS NOT NULL
  BEGIN
    DROP TABLE #reviewedDeals
  END
  CREATE TABLE #reviewedDeals (
    username_group varchar(50) NULL,
    reviewedDeals int NULL
  )
  INSERT INTO #reviewedDeals (username_group, reviewedDeals)
    SELECT
      CASE
        WHEN GROUPING(em.username_group) = 0 THEN em.username_group
        ELSE 'BFC Tot.'
      END AS username_group,
      COUNT(opportunityid)
    FROM [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
    INNER JOIN #employees em
      ON s.creditmanagerid = em.CRMGuid
    WHERE s.[Submission Date] >= @datefrom
    AND s.[Submission Date] <= @dateto
    AND (FundingMethodValue = @fundingMethod
    OR @fundingMethod IS NULL)
    AND (consultantId = @OutsideSalesID
    OR @OutsideSalesID IS NULL)
    AND (insideSalesid = @insideSalesID
    OR @insideSalesID IS NULL)
    GROUP BY em.username_group WITH ROLLUP


  IF OBJECT_ID('tempdb..#reviewedTerms') IS NOT NULL
  BEGIN
    DROP TABLE #reviewedTerms
  END
  CREATE TABLE #reviewedTerms (
    username_group varchar(50) NULL,
    reviewedTerms int NULL
  )
  INSERT INTO #reviewedTerms (username_group, reviewedTerms)
    SELECT
      CASE
        WHEN GROUPING(em.username_group) = 0 THEN em.username_group
        ELSE 'BFC Tot.'
      END AS username_group,
      COUNT(termid)
    FROM [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
    INNER JOIN #employees em
      ON s.creditmanagerid = em.CRMGuid
    WHERE s.reviewedOn >= @datefrom
    AND s.reviewedOn <= @dateto
    AND (FundingMethodValue = @fundingMethod
    OR @fundingMethod IS NULL)
    AND (consultantId = @OutsideSalesID
    OR @OutsideSalesID IS NULL)
    AND (insideSalesid = @insideSalesID
    OR @insideSalesID IS NULL)
    GROUP BY em.username_group WITH ROLLUP




  IF OBJECT_ID('tempdb..#app') IS NOT NULL
  BEGIN
    DROP TABLE #app
  END
  CREATE TABLE #app (
    username_group varchar(50) NULL,
    appPercent float NULL
  )

  INSERT INTO #app (appPercent, username_group)
    SELECT
      CAST(SUM(
      CASE
        WHEN a.ApprovalDate IS NULL OR
          a.ApprovalDate > @DateTo THEN 0
        ELSE 1
      END) AS float) / CAST(SUM(1) AS float)
      AS appPercent,
      CASE
        WHEN GROUPING(em.username_group) = 0 THEN em.username_group
        ELSE 'BFC Tot.'
      END AS username_group

    FROM (SELECT
      *
    FROM [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot]
    WHERE [SubmitDate] >= DATEADD(YEAR, -1, @DateTo)
    AND [SubmitDate] <= @DateTo
    AND (FundingMethodValue = @fundingMethod
    OR @fundingMethod IS NULL)
    AND (consultantId = @OutsideSalesID
    OR @OutsideSalesID IS NULL)
    AND (insideSalesid = @insideSalesID
    OR @insideSalesID IS NULL)) s
    LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a
      ON s.[opid] = a.[opid]
    INNER JOIN #employees em
      ON s.creditmanagerid = em.CRMGuid
    GROUP BY em.username_group WITH ROLLUP


  IF OBJECT_ID('tempdb..#fund') IS NOT NULL
  BEGIN
    DROP TABLE #fund
  END
  CREATE TABLE #fund (
    username_group varchar(50) NULL,
    fundPercent float NULL
  )
  INSERT INTO #fund (fundPercent, username_group)
    SELECT
      CAST(SUM(
      CASE
        WHEN f.FundDate IS NULL OR
          f.FundDate > @DateTo THEN 0
        ELSE 1
      END) AS float) / CAST(SUM(1) AS float)
      AS fundPercent,
      CASE
        WHEN GROUPING(em.username_group) = 0 THEN em.username_group
        ELSE 'BFC Tot.'
      END AS username_group

    FROM (SELECT
      *
    FROM [dbo].[KeyStats_ApprovedOpportunity_HourlySnapshot]
    WHERE [ApprovalDate] >= DATEADD(YEAR, -1, @DateTo)
    AND [ApprovalDate] <= @DateTo
    AND (FundingMethodValue = @fundingMethod
    OR @fundingMethod IS NULL)
    AND (consultantId = @OutsideSalesID
    OR @OutsideSalesID IS NULL)
    AND (insideSalesid = @insideSalesID
    OR @insideSalesID IS NULL)) a
    LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f
      ON a.[opid] = f.[opid]
    INNER JOIN #employees em
      ON a.creditmanagerid = em.CRMGuid
    GROUP BY em.username_group WITH ROLLUP






  -- ********** Company Sales **********

  IF OBJECT_ID('tempdb..#final') IS NOT NULL
  BEGIN
    DROP TABLE #final
  END;

  WITH cte_accepted
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    SUM(1) AS [totalCount],	--Number of Deals
    (SUM(1) * @AnnualizedRate) AS [annualizedTotalCount], --Annulaized totalCount
    SUM([EquipmentCost]) AS [EquipmentCost], --Equipment Cost
    AVG([EquipmentCost]) AS [EquipmentCost_avg],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
      ELSE 0
    END) AS [portfolioleaseAmt], --Portofolio Originations

    AVG(CASE
      WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
      ELSE NULL
    END) AS [portfolioleaseAmt_avg],

    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 1
      ELSE 0
    END) AS [portfolioCount], --Portofolio Count
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE [leaseAmt]
    END) AS [oneoffleaseAmt], --One-Off Originations
    AVG(CASE
      WHEN [FundingMethodValue] = 1 THEN NULL
      ELSE [leaseAmt]
    END) AS [oneoffleaseAmt_avg],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE 1
    END) AS [oneoffCount], --One-Off count
    CASE
      WHEN SUM(ISNULL([leaseAmt], 0)) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
          ELSE 0
        END) / SUM(ISNULL([leaseAmt], 0)))
    END AS [portofolioOrigPercent], --Portfolio Origations %
    CASE
      WHEN SUM(ISNULL([leaseAmt], 0)) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN 0
          ELSE [leaseAmt]
        END) / SUM(ISNULL([leaseAmt], 0)))
    END AS [oneOffOrigPercent], --One Off Origations %
    SUM([leaseAmt]) AS [leaseAmt], --Total Originations
    AVG([leaseAmt]) AS [leaseAmt_avg],
    SUM([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt], --Annualized Total Originations
    AVG([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt_avg],
    SUM(CASE
      WHEN [insideSalesid] IS NOT NULL THEN [leaseAmt]
      ELSE 0
    END) AS [leaseAmtInsideSales], --Total Originations - Inside Sales
    AVG(CASE
      WHEN [insideSalesid] IS NOT NULL THEN [leaseAmt]
      ELSE NULL
    END) AS [leaseAmtInsideSales_avg],

    CASE
      WHEN SUM(ISNULL([leaseAmt], 0)) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [insideSalesid] IS NOT NULL THEN [leaseAmt]
          ELSE 0
        END) / SUM(ISNULL([leaseAmt], 0)))
    END AS [leastAmtInsideSalesPercent], --Total Originations - Inside Sales %
    SUM([securityDeposit]) AS [securityDeposit], --Security Deposit $, regardless of eligibility
    AVG([securityDeposit]) AS [securityDeposit_avg],
    CASE
      WHEN (SUM(CASE
          WHEN [SD_Eligible] = 1 THEN ISNULL([payment], 0)
          ELSE 0
        END) * 2) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [SD_Eligible] = 1 THEN ISNULL([securityDeposit], 0) + ISNULL(OtherIncomeExpense, 0)-- Security Deposit % (ADD OTHER INCOME WITH SD_ELIGIBLE)
          ELSE 0
        END)
        / (SUM(CASE
          WHEN [SD_Eligible] = 1 THEN ISNULL([payment], 0)
          ELSE 0
        END) * 2))
    END
    AS [securityDepositPercent],
    CASE
      WHEN SUM(ISNULL([NetVendorAmount], 0)) <= 0 THEN NULL
      ELSE (SUM([initialCash]) / SUM(ISNULL([NetVendorAmount], 0)))
    END AS [initialCashPercent], --Initial Cash %		

    SUM([purchaseOption]) AS [purchaseOption], --Purchase Option $
    AVG([purchaseOption]) AS [purchaseOption_avg], --Purchase Option $
    CASE
      WHEN
        SUM(CASE
          WHEN [PO_Eligible] = 1 THEN ISNULL([EquipmentCost], 0)
          ELSE 0
        END) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [PO_Eligible] = 1 THEN [purchaseOption]
          ELSE 0
        END)
        / SUM(CASE
          WHEN [PO_Eligible] = 1 THEN ISNULL([EquipmentCost], 0)
          ELSE 0
        END))
    END AS [purchaseOptionPercent], --Purchase Option %
    SUM([TotalReferralFee]) AS [TotalReferralFee], --Referral Fee $
    AVG([TotalReferralFee]) AS [TotalReferralFee_avg],
    CASE
      WHEN SUM(ISNULL([leaseAmt], 0)) <= 0 THEN NULL
      ELSE ((SUM([TotalReferralFee]) / SUM(ISNULL([leaseAmt], 0))) * 100)
    END AS [totalReferralFeePts], --[TotalReferralFee] Referral Fee Points
    SUM([oneoffProfit]) AS [oneoffProfit], --One Off Profit $
    AVG([oneoffProfit]) AS [oneoffProfit_avg],
    CASE
      WHEN
        SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN 0
          ELSE ISNULL([leaseAmt], 0)
        END) <= 0 THEN NULL
      ELSE ((SUM([oneoffProfit]) /
        SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN 0
          ELSE ISNULL([leaseAmt], 0)
        END)) * 100)
    END AS [oneOffProfitPts], --One Off Profit Pts
    CASE
      WHEN
        SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN ISNULL([leaseAmt], 0)
          ELSE 0
        END) <= 0 THEN NULL
      ELSE (SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN ([IRR] / 100) * [leaseAmt]
          ELSE 0
        END) /
        SUM(CASE
          WHEN [FundingMethodValue] = 1 THEN ISNULL([leaseAmt], 0)
          ELSE 0
        END))
    END AS [IRR] --[IRR] IRR Portofolio %
    ,
    AVG(AVGBeaconScore) AS AVGBeaconScore,
    AVG(AVGFICOScore) AS AVGFICOScore,
    AVG(tib) AS tib,
    AVG(CAST(paydex AS float)) AS paydex
  FROM #details s
  INNER JOIN #employees em
    ON s.creditmanagerid = em.CRMGuid
  GROUP BY em.username_group WITH ROLLUP)






  SELECT DISTINCT
    emp.[Index],
    emp.username_group AS ConsultantUserName,
    emp.lastname_group AS ConsultantName,
    emp.CRMguid_group AS ConsultantID,
    emp.fullname_group AS ConsultantFullName,
    --emp.UniqueUserId_group AS UniqueUserId,
    emp.startdate AS StartDateVal,
    cte_accepted.EquipmentCost AS EquipmentCostVal,
    cte_accepted.EquipmentCost_avg AS EquipmentCostVal_avg,
    cte_accepted.totalCount AS DealsVal,
    ROUND(cte_accepted.annualizedTotalCount, 0) AS AnnualizedDealsVal,
    ROUND(cte_accepted.portfolioleaseAmt, 0) AS PortofolioOrigVal,
    ROUND(cte_accepted.portfolioleaseAmt_avg, 0) AS PortofolioOrigVal_avg,
    cte_accepted.portfolioCount,
    ROUND(cte_accepted.oneoffleaseAmt, 0) AS OneOffOrigVal,
    ROUND(cte_accepted.oneoffleaseAmt_avg, 0) AS OneOffOrigVal_avg,
    cte_accepted.oneoffCount,
    ROUND(cte_accepted.portofolioOrigPercent, 2) AS PortOrigPercentVal,
    ROUND(cte_accepted.oneOffOrigPercent, 2) AS OneOffOrigPercentVal,
    ROUND(cte_accepted.leaseAmt, 0) AS TotalOrigVal,
    ROUND(cte_accepted.leaseAmt_avg, 0) AS TotalOrigVal_avg,
    ROUND(cte_accepted.annualizedLeaseAmt, 0) AS AnnualizedTotalOrigVal,
    ROUND(cte_accepted.annualizedLeaseAmt_avg, 0) AS AnnualizedTotalOrigVal_avg,
    ROUND(cte_accepted.leaseAmtInsideSales, 0) AS TotalOrigInsideVal,
    ROUND(cte_accepted.leaseAmtInsideSales_avg, 0) AS TotalOrigInsideVal_avg,
    ROUND(cte_accepted.leastAmtInsideSalesPercent, 2) AS TotalOrigInsidePercentVal,
    ROUND(cte_accepted.securityDeposit, 0) AS SecDepMVal,
    ROUND(cte_accepted.securityDeposit_avg, 0) AS SecDepMVal_avg,
    ROUND(cte_accepted.securityDepositPercent, 4) AS SecDepPVal,
    ROUND(cte_accepted.purchaseOption, 0) AS PurchOptVal,
    ROUND(cte_accepted.purchaseOption_avg, 0) AS PurchOptVal_avg,
    ROUND(cte_accepted.purchaseOptionPercent, 4) AS PurchOptAvgVal,
    ROUND(cte_accepted.initialCashPercent, 4) AS InitialCashPercentVal,
    ROUND(cte_accepted.TotalReferralFee, 0) AS RefFeeVal,
    ROUND(cte_accepted.TotalReferralFee_avg, 0) AS RefFeeVal_avg,
    ROUND(cte_accepted.totalReferralFeePts, 2) AS RefFeePtsVal,
    ROUND(cte_accepted.oneoffProfit, 0) AS OneOffProfitVal,
    ROUND(cte_accepted.oneoffProfit_avg, 0) AS OneOffProfitVal_avg,
    ROUND(cte_accepted.oneOffProfitPts, 2) AS OneOffPtsVal,
    ROUND(cte_accepted.IRR, 4) AS IRRVal,
    cte_accepted.AVGBeaconScore AS BeaconScoreVal,
    cte_accepted.AVGFICOScore AS FICOScoreVal,
    CAST(ROUND(cte_accepted.tib, 2) AS decimal(8, 2)) AS TIBVal,
    ROUND(cte_accepted.paydex, 2) AS PaydexScoreVal,
    rd.reviewedDeals AS UniqueDealsReviewedVal,
    rt.reviewedTerms AS SubmissionsVal,
    CASE
      WHEN rd.reviewedDeals > 0 THEN ROUND(CAST(rt.reviewedTerms AS float)
        / CAST(rd.reviewedDeals AS float),
        2)
      ELSE NULL
    END AS SubmissionsPerDealVal,
    app.appPercent AS ApprovalPVal,
    fund.fundPercent AS ClosedPVal,
	0 AS _sc_excluded  
	INTO #final
  FROM #employees emp
  LEFT JOIN cte_accepted
    ON cte_accepted.username_group = emp.username_group
  LEFT JOIN #reviewedDeals rd
    ON rd.username_group = emp.username_group
  LEFT JOIN #reviewedTerms rt
    ON rt.username_group = emp.username_group
  LEFT JOIN #app app
    ON app.username_group = emp.username_group
  LEFT JOIN #fund fund
    ON fund.username_group = emp.username_group


  DECLARE @em_count AS int
  SELECT
    @em_count = COUNT(CRMGuid) - 1--exclude bfc total
  FROM #employees


  INSERT INTO #final ([Index],
  ConsultantUserName,
  ConsultantName,
  ConsultantID,
  ConsultantFullName,
  StartDateVal,
  EquipmentCostVal,
  DealsVal,
  AnnualizedDealsVal,
  PortofolioOrigVal,
  portfolioCount,
  OneOffOrigVal,
  oneoffCount,
  PortOrigPercentVal,
  OneOffOrigPercentVal,
  TotalOrigVal,
  AnnualizedTotalOrigVal,
  TotalOrigInsideVal,
  TotalOrigInsidePercentVal,
  SecDepMVal,
  SecDepPVal,
  PurchOptVal,
  PurchOptAvgVal,
  InitialCashPercentVal,
  RefFeeVal,
  RefFeePtsVal,
  OneOffProfitVal,
  OneOffPtsVal,
  IRRVal,
  BeaconScoreVal,
  FICOScoreVal,
  TIBVal,
  PaydexScoreVal,
  UniqueDealsReviewedVal,
  SubmissionsVal,
  SubmissionsPerDealVal,
  ApprovalPVal,
  ClosedPVal,
	_sc_excluded)
    SELECT
      1, -- Index - int
      'BFC Avg.', -- ConsultantUserName - varchar(50)
      'BFC Avg.', -- ConsultantName - varchar(50)
      NULL, -- ConsultantID - uniqueidentifier
      'Beacon Funding Corporation Average', -- ConsultantFullName - varchar(100)    
      @avg_startdate, -- StartDateVal - datetime            
      EquipmentCostVal_avg,
      DealsVal / @em_count,
      AnnualizedDealsVal / @em_count,
      PortofolioOrigVal_avg,
      portfolioCount / @em_count,
      OneOffOrigVal_avg,
      oneoffCount / @em_count,
      PortOrigPercentVal,
      OneOffOrigPercentVal,
      TotalOrigVal_avg,
      AnnualizedTotalOrigVal_avg,
      TotalOrigInsideVal_avg,
      TotalOrigInsidePercentVal,
      SecDepMVal_avg,
      SecDepPVal,
      PurchOptVal_avg,
      PurchOptAvgVal,
      InitialCashPercentVal,
      RefFeeVal_avg,
      RefFeePtsVal,
      OneOffProfitVal_avg,
      OneOffPtsVal,
      IRRVal,
      BeaconScoreVal,
      FICOScoreVal,
      TIBVal,
      PaydexScoreVal,
      UniqueDealsReviewedVal / @em_count,
      SubmissionsVal / @em_count,
      SubmissionsPerDealVal,
      ApprovalPVal,
      ClosedPVal,
	  1
    FROM #final
    WHERE [index] = 0

  UPDATE #final
  SET StartDateVal = NULL,
      PortOrigPercentVal = NULL,
      OneOffOrigPercentVal = NULL,
      TotalOrigInsidePercentVal = NULL,
      SecDepPVal = NULL,
      PurchOptAvgVal = NULL,
      InitialCashPercentVal = NULL,
      RefFeePtsVal = NULL,
      OneOffPtsVal = NULL,
      IRRVal = NULL,
      BeaconScoreVal = NULL,
      FICOScoreVal = NULL,
      TIBVal = NULL,
      PaydexScoreVal = NULL,
      SubmissionsPerDealVal = NULL,
      ApprovalPVal = NULL,
      ClosedPVal = NULL,
	  _sc_excluded = 1
  WHERE [index] = 0

  ALTER TABLE #final ALTER COLUMN [_sc_excluded] BIT

  IF @CreditManagerID IS NULL
  BEGIN
    SELECT
      [Index],
      ConsultantUserName,
      ConsultantName,
      ConsultantID,
      ConsultantFullName,
      StartDateVal AS StartDateVal,
      EquipmentCostVal,
      DealsVal,
      AnnualizedDealsVal,
      PortofolioOrigVal,
      portfolioCount,
      OneOffOrigVal,
      oneoffCount,
      PortOrigPercentVal,
      OneOffOrigPercentVal,
      TotalOrigVal,
      AnnualizedTotalOrigVal,
      TotalOrigInsideVal,
      TotalOrigInsidePercentVal,
      SecDepMVal,
      SecDepPVal,
      PurchOptVal,
      PurchOptAvgVal,
      InitialCashPercentVal,
      RefFeeVal,
      RefFeePtsVal,
      OneOffProfitVal,
      OneOffPtsVal,
      IRRVal,
      BeaconScoreVal,
      FICOScoreVal,
      TIBVal,
      PaydexScoreVal,
      UniqueDealsReviewedVal,
      SubmissionsVal,
      SubmissionsPerDealVal,
      ApprovalPVal,
      ClosedPVal,
	  _sc_excluded
    FROM #final
	ORDER BY [Index]

  END

  ELSE
  BEGIN
    SELECT
      CASE WHEN ConsultantID = @creditmanagerid THEN 0 ELSE [index] END AS [Index] ,
      ConsultantUserName,
      ConsultantName,
      ConsultantID,
      ConsultantFullName,
      StartDateVal AS StartDateVal,
      EquipmentCostVal,
      DealsVal,
      AnnualizedDealsVal,
      PortofolioOrigVal,
      portfolioCount,
      OneOffOrigVal,
      oneoffCount,
      PortOrigPercentVal,
      OneOffOrigPercentVal,
      TotalOrigVal,
      AnnualizedTotalOrigVal,
      TotalOrigInsideVal,
      TotalOrigInsidePercentVal,
      SecDepMVal,
      SecDepPVal,
      PurchOptVal,
      PurchOptAvgVal,
      InitialCashPercentVal,
      RefFeeVal,
      RefFeePtsVal,
      OneOffProfitVal,
      OneOffPtsVal,
      IRRVal,
      BeaconScoreVal,
      FICOScoreVal,
      TIBVal,
      PaydexScoreVal,
      UniqueDealsReviewedVal,
      SubmissionsVal,
      SubmissionsPerDealVal,
      ApprovalPVal,
      ClosedPVal
    FROM #final
    WHERE [index] = 1--bfc avg
    OR ConsultantID = @CreditManagerID

    UNION ALL

    SELECT
      2,
      'Difference',
      'Difference',
      NULL,
      'Difference',
		NULL,
      fi.EquipmentCostVal - fa.EquipmentCostVal,
      fi.DealsVal - fa.DealsVal,
      fi.AnnualizedDealsVal - fa.AnnualizedDealsVal,
      fi.PortofolioOrigVal - fa.PortofolioOrigVal,
      fi.portfolioCount - fa.portfolioCount,
      fi.OneOffOrigVal - fa.OneOffOrigVal,
      fi.oneoffCount - fa.oneoffCount,
      fi.PortOrigPercentVal - fa.PortOrigPercentVal,
      fi.OneOffOrigPercentVal - fa.OneOffOrigPercentVal,
      fi.TotalOrigVal - fa.TotalOrigVal,
      fi.AnnualizedTotalOrigVal - fa.AnnualizedTotalOrigVal,
      fi.TotalOrigInsideVal - fa.TotalOrigInsideVal,
      fi.TotalOrigInsidePercentVal - fa.TotalOrigInsidePercentVal,
      fi.SecDepMVal - fa.SecDepMVal,
      fi.SecDepPVal - fa.SecDepPVal,
      fi.PurchOptVal - fa.PurchOptVal,
      fi.PurchOptAvgVal - fa.PurchOptAvgVal,
      fi.InitialCashPercentVal - fa.InitialCashPercentVal,
      fi.RefFeeVal - fa.RefFeeVal,
      fi.RefFeePtsVal - fa.RefFeePtsVal,
      fi.OneOffProfitVal - fa.OneOffProfitVal,
      fi.OneOffPtsVal - fa.OneOffPtsVal,
      fi.IRRVal - fa.IRRVal,
      fi.BeaconScoreVal - fa.BeaconScoreVal,
      fi.FICOScoreVal - fa.FICOScoreVal,
      fi.TIBVal - fa.TIBVal,
      fi.PaydexScoreVal - fa.PaydexScoreVal,
      fi.UniqueDealsReviewedVal - fa.UniqueDealsReviewedVal,
      fi.SubmissionsVal - fa.SubmissionsVal,
      fi.SubmissionsPerDealVal - fa.SubmissionsPerDealVal,
      fi.ApprovalPVal - fa.ApprovalPVal,
      fi.ClosedPVal - fa.ClosedPVal

    FROM #final fi
    INNER JOIN #final fa
      ON fi.ConsultantID = @CreditManagerID
      AND fa.[index] = 1--'BFC Avg.'  
	ORDER BY [Index]
  END




--[KeyStats_Sales_LoadCreditManagerSales] '1/01/2015','12/22/2015'
GO
