SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      Ruonan Wen  			
-- Create date: 12/29/2015
-- Description:	Loads Key Stats Sales' outside 
--				Sales View Data 
-- =============================================
--KeyStats_Sales_LoadOutsideSales '1/01/2015','12/22/2015',null,null,null,'988E9267-B204-E011-B009-78E7D1F817F8'
CREATE PROCEDURE [dbo].[KeyStats_Sales_LoadOutsideSales]
    @DateFrom DATETIME ,
    @DateTo DATETIME ,
    @fundingMethod AS INT = NULL ,
    @InsideSalesID AS UNIQUEIDENTIFIER = NULL ,
    @CreditManagerID AS UNIQUEIDENTIFIER = NULL ,
    @OutsideSalesID AS UNIQUEIDENTIFIER = NULL
AS /*
  DECLARE @DateFrom datetime
  DECLARE @DateTo datetime
  DECLARE @fundingMethod AS int 
  DECLARE @OutsideSalesID AS UNIQUEIDENTIFIER
  SET @DateFrom = '1/01/2015'
  SET @DateTo = '12/31/2015'
  SET @fundingMethod = NULL
  SET @OutsideSalesID = NULL
  */

    DECLARE @MiscOutsideSalesID AS UNIQUEIDENTIFIER
    SET @MiscOutsideSalesID = '00000000-0000-0000-0000-000000000000'

  --Category ID
    DECLARE @categoryID AS INT
    SET @categoryID = 1--fixed for sales

  --Employees Temp Table
    IF OBJECT_ID('tempdb..#employees') IS NOT NULL 
        BEGIN
            DROP TABLE #employees
        END
    CREATE TABLE #employees
        (
          [Index] INT ,
          --LastName VARCHAR(50) ,
          --fullname VARCHAR(100) ,
          CRMGuid UNIQUEIDENTIFIER ,
          username VARCHAR(50) ,
          --UniqueUserId INT ,
          UserID INT ,
          IntranetTable VARCHAR(10) ,
          lastname_group VARCHAR(50) ,
          username_group VARCHAR(50) ,
          CRMGuid_group UNIQUEIDENTIFIER ,
          fullname_group VARCHAR(100) ,
          --UniqueUserId_group INT ,
          startdate DATETIME ,
          IsMiscellaneous BIT
        )

    INSERT  INTO #employees
            (-- LastName ,
            --  fullname ,
              CRMGuid ,
              username ,
              --UniqueUserId ,
              UserID ,
              IntranetTable ,
              lastname_group ,
              username_group ,
              CRMGuid_group ,
              fullname_group ,
              --UniqueUserId_group ,
              startdate ,
              IsMiscellaneous
            )
            SELECT 
             --em.LName AS LastName ,
             --       em.lname + ', ' + em.fname AS fullname ,
                    em.CRMGuid ,
                    em.username ,
                    --em.UniqueUserId ,
                    em.userid ,
                    em.IntranetTable ,
                    CASE WHEN r.IsMiscellaneous = 0 THEN em.LName
                         ELSE 'Misc.'
                    END AS lastname_group ,
                    CASE WHEN r.IsMiscellaneous = 0 THEN em.username
                         ELSE 'Misc.'
                    END AS username_group ,
                    CASE WHEN r.IsMiscellaneous = 0 THEN em.CRMGuid
                         ELSE @MiscOutsideSalesID
                    END AS CRMGuid_group ,
                    CASE WHEN r.IsMiscellaneous = 0
                         THEN em.lname + ', ' + em.fname
                         ELSE 'Miscellaneous'
                    END AS fullname_group ,
                    --CASE WHEN r.IsMiscellaneous = 0 THEN em.UniqueUserId
                    --     ELSE 999999999
                    --END AS UniqueUserId_group ,
                    CAST(startdate AS DATETIME) AS startdate ,
                    r.IsMiscellaneous
            FROM    dbo.KeyStats_AllEmployees em
                    INNER JOIN dbo.KeyStats_Category_Employee_Relation r ON r.UniqueUserId = em.UniqueUserId
                    INNER JOIN dbo.KeyStats_Categories c ON r.CategoryID = c.CategoryID
            WHERE   c.CategoryID = @categoryID;
    WITH    cte_emp
              AS ( SELECT   username ,
                            ROW_NUMBER() OVER ( ORDER BY lastname_group ) + 1 AS RowNum
                   FROM     #employees
                   WHERE    IsMiscellaneous = 0
                 )
        UPDATE  #employees
        SET     #employees.[Index] = cte_emp.RowNum
        FROM    #employees
                INNER JOIN cte_emp ON #employees.username = cte_emp.username

    DECLARE @mis_startdate AS DATE
    SELECT  @mis_startdate = CAST(AVG(CAST(startdate AS FLOAT)) AS DATETIME)
    FROM    #employees
    WHERE   IsMiscellaneous = 1

    UPDATE  #employees
    SET     startdate = @mis_startdate
    WHERE   IsMiscellaneous = 1

    UPDATE  #employees
    SET     [Index] = ( SELECT  MAX([Index]) + 1
                        FROM    #employees
                        WHERE   IsMiscellaneous = 0
                      )
    WHERE   IsMiscellaneous = 1

    DECLARE @avg_startdate AS DATE
    SELECT  @avg_startdate = CAST(AVG(CAST(startdate AS FLOAT)) AS DATETIME)
    FROM    #employees

    INSERT  INTO #employees
            ( [Index] ,
              --LastName ,
              --fullname ,
              CRMGuid ,
              username ,
              --UniqueUserId ,
              UserID ,
              IntranetTable ,
              lastname_group ,
              username_group ,
              CRMGuid_group ,
              fullname_group ,
              --UniqueUserId_group ,
              startdate ,
              IsMiscellaneous
            )
            SELECT  0 ,
                    --'BFC Tot.' ,
                    --'BFC Tot.' ,
                    NULL ,
                    'Beacon Funding Corporation Total' ,
                    --0 ,
                    0 ,
                    'Beacon' ,
      --for grouping
                    'BFC Tot.' AS lastname_group ,
                    'BFC Tot.' AS username_group ,
                    NULL AS CRMGuid_group ,
                    'Beacon Funding Corporation Total' fullname_group ,
                    --1 ,
                    @avg_startdate ,
                    NULL AS IsMiscellaneous
  --select * from #employees

  --DECLARE @OutsideSalesID AS UNIQUEIDENTIFIER
  --  SET @OutsideSalesID = '988E9267-B204-E011-B009-78E7D1F817F8'
    DECLARE @outsideSales AS VARCHAR(160)
    IF @OutsideSalesID IS NOT NULL 
        BEGIN
            SELECT  @outsideSales = fullname_group
            FROM    #employees
            WHERE   CRMGuid_group = @OutsideSalesID
        END



  --Snapshot dates
    DECLARE @dateSnapshot AS DATE
    --SET @dateSnapshot = '12/21/2015'
	SET @dateSnapshot = @dateto



  --convert to UTC, already done in the snapshot
    --SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
    --                        @dateFrom)
    --SET @dateTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo)


  -- Annualized Rate Calculation
    DECLARE @daysOfCurrentYear AS FLOAT
    SET @daysOfCurrentYear = DATEPART(dy,
                                      DATEADD(dd, -1,
                                              DATEADD(yy,
                                                      DATEDIFF(yy, 0, @DateTo)
                                                      + 1, 0)))

    DECLARE @currentDaysOfYear AS FLOAT
    SET @currentDaysOfYear = DATEPART(dy, @DateTo)

    DECLARE @AnnualizedRate AS FLOAT
    SET @AnnualizedRate = @daysOfCurrentYear / @currentDaysOfYear

  -- ********** Accepted Opportunities (sales details data) **********

    IF OBJECT_ID('tempdb..#details') IS NOT NULL 
        BEGIN
            DROP TABLE #details
        END
    CREATE TABLE #details
        (
          name VARCHAR(300) NULL ,
          opid [uniqueidentifier] NOT NULL ,
          [Appid] [varchar](15) NULL ,
          [companyName] [varchar](250) NULL ,
          [repeatclient] [int] NULL ,
          [FundingMethodValue] [tinyint] NULL ,
          [FundingMethod] [varchar](200) NULL ,
          [CreditManager] [varchar](200) NULL ,
          [CreditManagerid] [uniqueidentifier] NULL ,
          [acceptanceDate] [datetime2](2) NULL ,
          [EquipmentCost] [money] NULL ,
          [leaseAmt] [money] NULL ,
          [NetVendorAmount] [money] NULL ,
          [securityDeposit] [money] NULL ,
          [payment] [money] NULL ,
          [SD_Eligible] [bit] NULL ,
          [initialCash] [money] NULL ,
          [purchaseOption] [money] NULL ,
          [PO_Eligible] [bit] NOT NULL ,
          [TotalReferralFee] [money] NULL ,
          [TotalReferralFeePts] [float] NULL ,
          [oneoffProfit] [money] NULL ,
          [oneoffProfitPts] [float] NULL ,
          [IRR] [float] NULL ,
          [AVGBeaconScore] [int] NULL ,
          [AVGFICOScore] [int] NULL ,
          [tib] [decimal](8, 2) NULL ,
          [paydex] [int] NULL ,
          [insideSales] [varchar](200) NULL ,
          [insideSalesid] [uniqueidentifier] NULL ,
          [consultant] [varchar](160) NULL ,
          [consultantId] [uniqueidentifier] NOT NULL ,
          OtherIncomeExpense MONEY NULL,
             [consultantId_group] [uniqueidentifier]  NULL 
        )


    INSERT  INTO #details
            ( name ,
              opid ,
              [Appid] ,
              [companyName] ,
              [repeatclient] ,
              [FundingMethodValue] ,
              [FundingMethod] ,
              [CreditManager] ,
              [CreditManagerid] ,
              [acceptanceDate] ,
              [EquipmentCost] ,
              [leaseAmt] ,
              [NetVendorAmount] ,
              [securityDeposit] ,
              [payment] ,
              [SD_Eligible] ,
              [initialCash] ,
              [purchaseOption] ,
              [PO_Eligible] ,
              [TotalReferralFee] ,
              [TotalReferralFeePts] ,
              [oneoffProfit] ,
              [oneoffProfitPts] ,
              [IRR] ,
              [AVGBeaconScore] ,
              [AVGFICOScore] ,
              [tib] ,
              [paydex] ,
              [insideSales] ,
              [insideSalesid] ,
              [consultant] ,
              [consultantId] ,
              OtherIncomeExpense,
              consultantId_group
            )
            SELECT  s.name ,
                    s.opid ,
                    s.[Appid] ,
                    s.[companyName] ,
                    s.[repeatclient] ,
                    s.[FundingMethodValue] ,
                    s.[FundingMethod] ,
                    s.[CreditManager] ,
                    s.[CreditManagerid] ,
                    s.[acceptanceDate] ,
                    s.[EquipmentCost] ,
                    s.[leaseAmt] ,
                    s.[NetVendorAmount] ,
                    s.[securityDeposit] ,
                    s.[payment] ,
                    s.[SD_Eligible] ,
                    s.[initialCash] ,
                    s.[purchaseOption] ,
                    s.[PO_Eligible] ,
                    s.[TotalReferralFee] ,
                    s.[TotalReferralFeePts] ,
                    s.[oneoffProfit] ,
                    s.[oneoffProfitPts] ,
                    s.[IRR] ,
                    s.[AVGBeaconScore] ,
                    s.[AVGFICOScore] ,
                    s.[tib] ,
                    s.[paydex] ,
                    s.[insideSales] ,
                    s.[insideSalesid] ,
                    s.[consultant] ,
                    s.[consultantId] ,
                    s.OtherIncomeExpense
                    ,e.CRMGuid_group
            FROM    [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] s
            LEFT JOIN #employees e
            ON s.consultantId=e.CRMGuid
            
            WHERE   s.acceptanceDate >= @DateFrom
                    AND s.acceptanceDate <= @DateTo
                    AND ( s.FundingMethodValue = @fundingMethod
                          OR @fundingMethod IS NULL
                        )
                    AND ( s.CreditManagerid = @creditManagerID
                          OR @creditManagerID IS NULL
                        )
                    AND ( s.insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )

  -- ********** SELECT Sales Details **********
   SELECT  name ,
                    opid ,
                    [companyName] ,
                    [repeatclient] ,
                    [FundingMethod] ,
                    [CreditManager] ,
                    [acceptanceDate] ,
                    [EquipmentCost] ,
                    [leaseAmt] ,
                    [securityDeposit] ,
                    [initialCash] ,
                    [purchaseOption] ,
                    [TotalReferralFee] ,
                    [TotalReferralFeePts] ,
                    [oneoffProfit] ,
                    [oneoffProfitPts] * 100 AS [oneoffProfitPts] ,
                    [IRR] / 100 AS IRR ,
                    [AVGBeaconScore] ,
                    [AVGFICOScore] ,
                    [tib] ,
                    [paydex] ,
                    [insideSales] ,
                    [consultant] AS Owner
            FROM    #details
            WHERE   consultantId_group=@OutsideSalesID
            OR @OutsideSalesID IS NULL
  
  

  --CREDIT APPROVAL section
    IF OBJECT_ID('tempdb..#reviewedDeals') IS NOT NULL 
        BEGIN
            DROP TABLE #reviewedDeals
        END
    CREATE TABLE #reviewedDeals
        (
          username_group VARCHAR(50) NULL ,
          reviewedDeals INT NULL
        )
    INSERT  INTO #reviewedDeals
            ( username_group ,
              reviewedDeals
            )
            SELECT  CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group ,
                    COUNT(opportunityid)
            FROM    [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
                    INNER JOIN #employees em ON s.consultantId = em.CRMGuid
            WHERE   s.[Submission Date] >= @datefrom
                    AND s.[Submission Date] <= @dateto
                    AND ( FundingMethodValue = @fundingMethod
                          OR @fundingMethod IS NULL
                        )
                    AND ( CreditManagerid = @creditManagerID
                          OR @creditManagerID IS NULL
                        )
                    AND ( insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )
            GROUP BY em.username_group
                    WITH ROLLUP


    IF OBJECT_ID('tempdb..#reviewedTerms') IS NOT NULL 
        BEGIN
            DROP TABLE #reviewedTerms
        END
    CREATE TABLE #reviewedTerms
        (
          username_group VARCHAR(50) NULL ,
          reviewedTerms INT NULL
        )
    INSERT  INTO #reviewedTerms
            ( username_group ,
              reviewedTerms
            )
            SELECT  CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group ,
                    COUNT(termid)
            FROM    [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] s
                    INNER JOIN #employees em ON s.consultantid = em.CRMGuid
            WHERE   s.reviewedOn >= @datefrom
                    AND s.reviewedOn <= @dateto
                    AND ( FundingMethodValue = @fundingMethod
                          OR @fundingMethod IS NULL
                        )
                    AND ( CreditManagerid = @creditManagerID
                          OR @creditManagerID IS NULL
                        )
                    AND ( insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )
            GROUP BY em.username_group
                    WITH ROLLUP




    IF OBJECT_ID('tempdb..#app') IS NOT NULL 
        BEGIN
            DROP TABLE #app
        END
    CREATE TABLE #app
        (
          username_group VARCHAR(50) NULL ,
          appPercent FLOAT NULL
        )

    INSERT  INTO #app
            ( appPercent ,
              username_group
            )
            SELECT  CAST(SUM(CASE WHEN a.ApprovalDate IS NULL
                                       OR a.ApprovalDate > @DateTo THEN 0
                                  ELSE 1
                             END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS appPercent ,
                    CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group
            FROM    ( SELECT    *
                      FROM      [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot]
                      WHERE     [SubmitDate] >= DATEADD(YEAR, -1, @DateTo)
                                AND [SubmitDate] <= @DateTo
                                AND ( FundingMethodValue = @fundingMethod
                                      OR @fundingMethod IS NULL
                                    )
                                AND ( CreditManagerid = @creditManagerID
                                      OR @creditManagerID IS NULL
                                    )
                                AND ( insideSalesid = @insideSalesID
                                      OR @insideSalesID IS NULL
                                    )
                    ) s
                    LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a ON s.[opid] = a.[opid]
                    INNER JOIN #employees em ON s.consultantid = em.CRMGuid
            GROUP BY em.username_group
                    WITH ROLLUP


    IF OBJECT_ID('tempdb..#fund') IS NOT NULL 
        BEGIN
            DROP TABLE #fund
        END
    CREATE TABLE #fund
        (
          username_group VARCHAR(50) NULL ,
          fundPercent FLOAT NULL
        )
    INSERT  INTO #fund
            ( fundPercent ,
              username_group
            )
            SELECT  CAST(SUM(CASE WHEN f.FundDate IS NULL
                                       OR f.FundDate > @DateTo THEN 0
                                  ELSE 1
                             END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS fundPercent ,
                    CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group
            FROM    ( SELECT    *
                      FROM      [dbo].[KeyStats_ApprovedOpportunity_HourlySnapshot]
                      WHERE     [ApprovalDate] >= DATEADD(YEAR, -1, @DateTo)
                                AND [ApprovalDate] <= @DateTo
                                AND ( FundingMethodValue = @fundingMethod
                                      OR @fundingMethod IS NULL
                                    )
                                AND ( CreditManagerid = @creditManagerID
                                      OR @creditManagerID IS NULL
                                    )
                                AND ( insideSalesid = @insideSalesID
                                      OR @insideSalesID IS NULL
                                    )
                    ) a
                    LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f ON a.[opid] = f.[opid]
                    INNER JOIN #employees em ON a.consultantid = em.CRMGuid
            GROUP BY em.username_group
                    WITH ROLLUP




  -- ********** Accepted Opportunities (sales details data) **********

    IF OBJECT_ID('tempdb..#OpenDeals') IS NOT NULL 
        BEGIN
            DROP TABLE #OpenDeals
        END
    CREATE TABLE #OpenDeals
        (
          username_group VARCHAR(50) NULL ,
          [salesstagecode] [tinyint] NULL ,
          totalcount INT NULL ,
          [LeaseAmount] [money] NULL ,
          [LeaseAmount_avg] [money] NULL
        )


    INSERT  INTO #OpenDeals
            ( username_group ,
              [salesstagecode] ,
              totalcount ,
              [LeaseAmount] ,
              LeaseAmount_avg
            )
            SELECT  CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group ,
                    CASE WHEN em.username_group IS NULL THEN 10--10 for grand total
                         ELSE COALESCE(salesstagecode, 10)
                    END AS salesstagecode  -- 10 for individual total
                    ,
                    COUNT(OpportunityId) ,
                    SUM([LeaseAmount]) ,
                    AVG([LeaseAmount]) AS LeaseAmount_avg
            FROM    [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot] S
                    INNER JOIN #employees em ON s.consultantid = em.CRMGuid
            WHERE   SnapshotDate = @dateSnapshot
                    AND ( FundingMethodValue = @fundingMethod
                          OR @fundingMethod IS NULL
                        )
                    AND ( CreditManagerid = @creditManagerID
                          OR @creditManagerID IS NULL
                        )
                    AND ( insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )
            GROUP BY ROLLUP(em.username_group, s.salesstagecode)
            UNION ALL
            SELECT  'BFC Tot.' AS username_group ,
                    salesstagecode ,
                    COUNT(OpportunityId) ,
                    SUM([LeaseAmount]) ,
                    AVG(LeaseAmount) AS LeaseAmount_avg
            FROM    [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot]
            WHERE   SnapshotDate = @dateSnapshot
                    AND ( FundingMethodValue = @fundingMethod
                          OR @fundingMethod IS NULL
                        )
                    AND ( CreditManagerid = @creditManagerID
                          OR @creditManagerID IS NULL
                        )
                    AND ( insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )
            GROUP BY salesstagecode



  ---- ********** Activity **********
    IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL 
        BEGIN
            DROP TABLE #SpectorDailyAdminDataSnapShot
        END

    SELECT  DirectoryName ,
            [TotalActiveHr] ,
            [NonWorkHours] ,
            TotalHours ,
            [DailyStartMin] ,
            [DailyEndMin] ,
            [PhoneCalls] ,
            [CallDuration] ,
            [TotalInboundCalls] ,
            [TotalOutboundCalls] ,
            [TotalForwardCalls] ,
            [TotalInternalCalls] ,
            [KeyStrokes] ,
            [EmailSent] ,
            [SnapshotDate]
    INTO    #SpectorDailyAdminDataSnapShot
    FROM    LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
    WHERE   [SnapshotDate] >= @dateFrom
            AND [SnapshotDate] <= @dateTo
            AND DirectoryName IN ( SELECT   username
                                   FROM     #employees )


  --open lead 
    IF OBJECT_ID('tempdb..#OpenLeads') IS NOT NULL 
        BEGIN
            DROP TABLE #OpenLeads
        END
    CREATE TABLE #OpenLeads
        (
          username_group VARCHAR(50) NULL ,
          totalcount INT NULL ,
          EquipmentCost [money] NULL ,
          EquipmentCost_avg [money] NULL
        )

    INSERT  INTO #OpenLeads
            ( totalcount ,
              EquipmentCost ,
              EquipmentCost_avg ,
              username_group
            )
            SELECT  COUNT(leadid) ,
                    SUM(EquipmentCost) ,
                    AVG(EquipmentCost) AS EquipmentCost_avg ,
                    CASE WHEN GROUPING(em.username_group) = 0
                         THEN em.username_group
                         ELSE 'BFC Tot.'
                    END AS username_group
            FROM    [KeyStats_OpenLeadPipeline_DailySnapshot] s
                    INNER JOIN #employees em ON em.crmguid = s.consultantid
            WHERE   SnapshotDate = @dateSnapshot
                    AND ( insideSalesid = @insideSalesID
                          OR @insideSalesID IS NULL
                        )
            GROUP BY em.username_group
                    WITH ROLLUP


  --  --t&e	


    IF OBJECT_ID('tempdb..#TinyExpense') IS NOT NULL 
        BEGIN
            DROP TABLE #TinyExpense
        END

    SELECT  CASE WHEN GROUPING(em.username_group) = 0 THEN em.username_group
                 ELSE 'BFC Tot.'
            END AS username_group ,
            SUM(expenseAmount) AS TotalExpense
    INTO    #TinyExpense
    FROM    #employees em
            INNER JOIN intranet_beaconfunding.dbo.Exp_Reports r ON r.UserID = em.userid
                                                              AND em.IntranetTable = 'Beacon'
            LEFT JOIN intranet_beaconfunding.dbo.Exp_Expenses ex ON r.ReportID = ex.ReportID
            LEFT JOIN intranet_beaconfunding.dbo.Exp_ExpenseTypes t ON ex.ExpenseTypeID = t.ExpenseTypeID
            LEFT JOIN intranet_beaconfunding.dbo.Exp_StatusReasons s ON r.StatusReasonId = s.StatusReasonId
    WHERE   ExpenseID NOT IN ( 1794, 1803, 1807, 1823 )
            AND GLAccount IN ( 6040, 6090, 6220, 6287, 6634 )
            AND StatusReason LIKE 'Approved'
            AND ExpenseDate >= @dateFrom
            AND ExpenseDate <= @dateTo
    GROUP BY em.username_group
            WITH ROLLUP



  -- ********** Company Sales **********

    IF OBJECT_ID('tempdb..#final') IS NOT NULL 
        BEGIN
            DROP TABLE #final
        END;

    WITH    cte_accepted
              AS ( SELECT   CASE WHEN GROUPING(em.username_group) = 0
                                 THEN em.username_group
                                 ELSE 'BFC Tot.'
                            END AS username_group ,
                            SUM(1) AS [totalCount] ,	--Number of Deals
                            ( SUM(1) * @AnnualizedRate ) AS [annualizedTotalCount] , --Annulaized totalCount
                            SUM([EquipmentCost]) AS [EquipmentCost] , --Equipment Cost
                            AVG([EquipmentCost]) AS [EquipmentCost_avg] ,
                            SUM(CASE WHEN [FundingMethodValue] = 1
                                     THEN [leaseAmt]
                                     ELSE 0
                                END) AS [portfolioleaseAmt] , --Portofolio Originations
                            AVG(CASE WHEN [FundingMethodValue] = 1
                                     THEN [leaseAmt]
                                     ELSE NULL
                                END) AS [portfolioleaseAmt_avg] ,
                            SUM(CASE WHEN [FundingMethodValue] = 1 THEN 1
                                     ELSE 0
                                END) AS [portfolioCount] , --Portofolio Count
                            SUM(CASE WHEN [FundingMethodValue] = 1 THEN 0
                                     ELSE [leaseAmt]
                                END) AS [oneoffleaseAmt] , --One-Off Originations
                            AVG(CASE WHEN [FundingMethodValue] = 1 THEN NULL
                                     ELSE [leaseAmt]
                                END) AS [oneoffleaseAmt_avg] ,
                            SUM(CASE WHEN [FundingMethodValue] = 1 THEN 0
                                     ELSE 1
                                END) AS [oneoffCount] , --One-Off count
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( SUM(CASE WHEN [FundingMethodValue] = 1
                                                 THEN [leaseAmt]
                                                 ELSE 0
                                            END) / SUM(ISNULL([leaseAmt], 0)) )
                            END AS [portofolioOrigPercent] , --Portfolio Origations %
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( SUM(CASE WHEN [FundingMethodValue] = 1
                                                 THEN 0
                                                 ELSE [leaseAmt]
                                            END) / SUM(ISNULL([leaseAmt], 0)) )
                            END AS [oneOffOrigPercent] , --One Off Origations %
                            SUM([leaseAmt]) AS [leaseAmt] , --Total Originations
                            AVG([leaseAmt]) AS [leaseAmt_avg] ,
                            SUM([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt] , --Annualized Total Originations
                            AVG([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt_avg] ,
                            SUM(CASE WHEN [insideSalesid] IS NOT NULL
                                     THEN [leaseAmt]
                                     ELSE 0
                                END) AS [leaseAmtInsideSales] , --Total Originations - Inside Sales
                            AVG(CASE WHEN [insideSalesid] IS NOT NULL
                                     THEN [leaseAmt]
                                     ELSE NULL
                                END) AS [leaseAmtInsideSales_avg] ,
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( SUM(CASE WHEN [insideSalesid] IS NOT NULL
                                                 THEN [leaseAmt]
                                                 ELSE 0
                                            END) / SUM(ISNULL([leaseAmt], 0)) )
                            END AS [leastAmtInsideSalesPercent] , --Total Originations - Inside Sales %
                            SUM([securityDeposit]) AS [securityDeposit] , --Security Deposit $, regardless of eligibility
                            AVG([securityDeposit]) AS [securityDeposit_avg] ,
                            CASE WHEN ( SUM(CASE WHEN [SD_Eligible] = 1
                                                 THEN ISNULL([payment], 0)
                                                 ELSE 0
                                            END) * 2 ) <= 0 THEN NULL
                                 ELSE ( SUM(CASE WHEN [SD_Eligible] = 1
                                                 THEN ISNULL([securityDeposit],
                                                             0)
                                                      + ISNULL(OtherIncomeExpense,
                                                              0)-- Security Deposit % (ADD OTHER INCOME WITH SD_ELIGIBLE)
                                                 ELSE 0
                                            END)
                                        / ( SUM(CASE WHEN [SD_Eligible] = 1
                                                     THEN ISNULL([payment], 0)
                                                     ELSE 0
                                                END) * 2 ) )
                            END AS [securityDepositPercent] ,
                            CASE WHEN SUM(ISNULL([NetVendorAmount], 0)) <= 0
                                 THEN NULL
                                 ELSE ( SUM([initialCash])
                                        / SUM(ISNULL([NetVendorAmount], 0)) )
                            END AS [initialCashPercent] , --Initial Cash %		
                            SUM([purchaseOption]) AS [purchaseOption] , --Purchase Option $
                            AVG([purchaseOption]) AS [purchaseOption_avg] , --Purchase Option $
                            CASE WHEN SUM(CASE WHEN [PO_Eligible] = 1
                                               THEN ISNULL([EquipmentCost], 0)
                                               ELSE 0
                                          END) <= 0 THEN NULL
                                 ELSE ( SUM(CASE WHEN [PO_Eligible] = 1
                                                 THEN [purchaseOption]
                                                 ELSE 0
                                            END)
                                        / SUM(CASE WHEN [PO_Eligible] = 1
                                                   THEN ISNULL([EquipmentCost],
                                                              0)
                                                   ELSE 0
                                              END) )
                            END AS [purchaseOptionPercent] , --Purchase Option %
                            SUM([TotalReferralFee]) AS [TotalReferralFee] , --Referral Fee $
                            AVG([TotalReferralFee]) AS [TotalReferralFee_avg] ,
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( ( SUM([TotalReferralFee])
                                          / SUM(ISNULL([leaseAmt], 0)) ) * 100 )
                            END AS [totalReferralFeePts] , --[TotalReferralFee] Referral Fee Points
                            SUM([oneoffProfit]) AS [oneoffProfit] , --One Off Profit $
                            AVG([oneoffProfit]) AS [oneoffProfit_avg] ,
                            CASE WHEN SUM(CASE WHEN [FundingMethodValue] = 1
                                               THEN 0
                                               ELSE ISNULL([leaseAmt], 0)
                                          END) <= 0 THEN NULL
                                 ELSE ( ( SUM([oneoffProfit])
                                          / SUM(CASE WHEN [FundingMethodValue] = 1
                                                     THEN 0
                                                     ELSE ISNULL([leaseAmt], 0)
                                                END) ) * 100 )
                            END AS [oneOffProfitPts] , --One Off Profit Pts
                            CASE WHEN SUM(CASE WHEN [FundingMethodValue] = 1
                                               THEN ISNULL([leaseAmt], 0)
                                               ELSE 0
                                          END) <= 0 THEN NULL
                                 ELSE ( SUM(CASE WHEN [FundingMethodValue] = 1
                                                 THEN ( [IRR] / 100 )
                                                      * [leaseAmt]
                                                 ELSE 0
                                            END)
                                        / SUM(CASE WHEN [FundingMethodValue] = 1
                                                   THEN ISNULL([leaseAmt], 0)
                                                   ELSE 0
                                              END) )
                            END AS [IRR] --[IRR] IRR Portofolio %
                            ,
                            AVG(AVGBeaconScore) AS AVGBeaconScore ,
                            AVG(AVGFICOScore) AS AVGFICOScore ,
                            AVG(tib) AS tib ,
                            AVG(CAST(paydex AS FLOAT)) AS paydex
                   FROM     #details s
                            INNER JOIN #employees em ON s.consultantId = em.CRMGuid
                   GROUP BY em.username_group
                            WITH ROLLUP
                 ),
            cte_evaluation
              AS ( SELECT   CASE WHEN GROUPING(em.username_group) = 0
                                 THEN em.username_group
                                 ELSE 'BFC Tot.'
                            END AS username_group ,
                            AVG([Rating]) AS AvgEvaluationRating ,
                            SUM(1) AS EvaluationRatingCount ,
                            AVG(CASE WHEN [EvaluationTypeValue] = 1
                                     THEN [Rating]
                                     ELSE NULL
                                END) AS AvgEvaluationRatingExt ,
                            SUM(CASE WHEN [EvaluationTypeValue] = 1 THEN 1
                                     ELSE 0
                                END) AS EvaluationRatingCountExt ,
                            AVG(CASE WHEN [EvaluationTypeValue] = 1 THEN NULL
                                     ELSE [Rating]
                                END) AS AvgEvaluationRatingIn ,
                            SUM(CASE WHEN [EvaluationTypeValue] = 1 THEN 0
                                     ELSE 1
                                END) AS EvaluationRatingCountIn
                   FROM     #employees em
                            INNER JOIN [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot] ev ON ev.[EvaluateForID] = em.CRMGuid
                   WHERE    [ActualCloseDate] >= @dateFrom
                            AND [ActualCloseDate] <= @dateTo
                   GROUP BY em.username_group
                            WITH ROLLUP
                 ),
            cte_activity
              AS ( SELECT   CASE WHEN GROUPING(em.username_group) = 0
                                 THEN em.username_group
                                 ELSE 'BFC Tot.'
                            END AS username_group ,
                            SUM([TotalActiveHr]) AS totalActiveHours ,
                            SUM([NonWorkHours]) AS [Non Work Hours] ,
                            SUM(TotalHours) AS [WorkHours] ,
                            AVG([DailyStartMin]) AS startdateminute ,
                            AVG([DailyEndMin]) AS enddateminute ,
                            ISNULL(CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                   / 60) + ':'
                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                                   % 60)) = 1
                                          THEN '0'
                                               + CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                               % 60)
                                          ELSE CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                               % 60)
                                     END, 0) AS [Daily Start] ,
                            ISNULL(CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                   / 60) + ':'
                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                                   % 60)) = 1
                                          THEN '0'
                                               + CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                               % 60)
                                          ELSE CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                               % 60)
                                     END, 0) AS [Daily End] ,
                            SUM([PhoneCalls]) AS totalcall ,
                            CASE WHEN COUNT([PhoneCalls]) > 0
                                 THEN SUM([PhoneCalls]) / COUNT([PhoneCalls])
                                 ELSE NULL
                            END AS avgcalls ,
                            SUM([CallDuration]) AS totaldurationmin ,
                            CASE WHEN SUM([PhoneCalls]) > 0
                                 THEN SUM([CallDuration]) / SUM([PhoneCalls])
                                 ELSE NULL
                            END AS avgCallDuration ,
                            CASE WHEN SUM([PhoneCalls]) > 0
                                 THEN SUM([CallDuration]) / SUM([PhoneCalls])
                                      * 60
                                 ELSE NULL
                            END AS avgcalldurationmin ,
                            SUM([TotalInboundCalls]) AS totalcallin ,
                            SUM([TotalOutboundCalls]) AS totalcallout ,
                            SUM([TotalForwardCalls])
                            + SUM([TotalInternalCalls]) AS totalcallint ,
                            SUM([KeyStrokes]) AS keystroke ,
                            SUM([EmailSent]) AS totalemails
                   FROM     #employees em
                            INNER JOIN #SpectorDailyAdminDataSnapShot s ON em.username = s.DirectoryName
                   GROUP BY em.username_group
                            WITH ROLLUP
                 )
        ---########### Select Final Tables ####---------
  SELECT DISTINCT
            emp.[Index] ,
            emp.username_group AS ConsultantUserName ,
            emp.lastname_group AS ConsultantName ,
            emp.CRMguid_group AS ConsultantID ,
            emp.fullname_group AS ConsultantFullName ,
            --emp.UniqueUserId_group AS UniqueUserId ,
            emp.startdate AS StartDateVal ,
            cte_accepted.EquipmentCost AS EquipmentCostVal ,
            cte_accepted.EquipmentCost_avg AS EquipmentCostVal_avg ,
            cte_accepted.totalCount AS DealsVal ,
            ROUND(cte_accepted.annualizedTotalCount, 0) AS AnnualizedDealsVal ,
            ROUND(cte_accepted.portfolioleaseAmt, 0) AS PortofolioOrigVal ,
            ROUND(cte_accepted.portfolioleaseAmt_avg, 0) AS PortofolioOrigVal_avg ,
            cte_accepted.portfolioCount ,
            ROUND(cte_accepted.oneoffleaseAmt, 0) AS OneOffOrigVal ,
            ROUND(cte_accepted.oneoffleaseAmt_avg, 0) AS OneOffOrigVal_avg ,
            cte_accepted.oneoffCount ,
            ROUND(cte_accepted.portofolioOrigPercent, 2) AS PortOrigPercentVal ,
            ROUND(cte_accepted.oneOffOrigPercent, 2) AS OneOffOrigPercentVal ,
            ROUND(cte_accepted.leaseAmt, 0) AS TotalOrigVal ,
            ROUND(cte_accepted.leaseAmt_avg, 0) AS TotalOrigVal_avg ,
            ROUND(cte_accepted.annualizedLeaseAmt, 0) AS AnnualizedTotalOrigVal ,
            ROUND(cte_accepted.annualizedLeaseAmt_avg, 0) AS AnnualizedTotalOrigVal_avg ,
            ROUND(cte_accepted.leaseAmtInsideSales, 0) AS TotalOrigInsideVal ,
            ROUND(cte_accepted.leaseAmtInsideSales_avg, 0) AS TotalOrigInsideVal_avg ,
            ROUND(cte_accepted.leastAmtInsideSalesPercent, 2) AS TotalOrigInsidePercentVal ,
            ROUND(cte_accepted.securityDeposit, 0) AS SecDepMVal ,
            ROUND(cte_accepted.securityDeposit_avg, 0) AS SecDepMVal_avg ,
            ROUND(cte_accepted.securityDepositPercent, 4) AS SecDepPVal ,
            ROUND(cte_accepted.purchaseOption, 0) AS PurchOptVal ,
            ROUND(cte_accepted.purchaseOption_avg, 0) AS PurchOptVal_avg ,
            ROUND(cte_accepted.purchaseOptionPercent, 4) AS PurchOptAvgVal ,
            ROUND(cte_accepted.initialCashPercent, 4) AS InitialCashPercentVal ,
            ROUND(cte_accepted.TotalReferralFee, 0) AS RefFeeVal ,
            ROUND(cte_accepted.TotalReferralFee_avg, 0) AS RefFeeVal_avg ,
            ROUND(cte_accepted.totalReferralFeePts, 2) AS RefFeePtsVal ,
            ROUND(cte_accepted.oneoffProfit, 0) AS OneOffProfitVal ,
            ROUND(cte_accepted.oneoffProfit_avg, 0) AS OneOffProfitVal_avg ,
            ROUND(cte_accepted.oneOffProfitPts, 2) AS OneOffPtsVal ,
            ROUND(cte_accepted.IRR, 4) AS IRRVal ,
            cte_accepted.AVGBeaconScore AS BeaconScoreVal ,
            cte_accepted.AVGFICOScore AS FICOScoreVal ,
            CAST(ROUND(cte_accepted.tib, 2) AS DECIMAL(8, 2)) AS TIBVal ,
            ROUND(cte_accepted.paydex, 2) AS PaydexScoreVal ,
            rd.reviewedDeals AS UniqueDealsReviewedVal ,
            rt.reviewedTerms AS SubmissionsVal ,
            CASE WHEN rd.reviewedDeals > 0
                 THEN ROUND(CAST(rt.reviewedTerms AS FLOAT)
                            / CAST(rd.reviewedDeals AS FLOAT), 2)
                 ELSE NULL
            END AS SubmissionsPerDealVal ,
            app.appPercent AS ApprovalPVal ,
            fund.fundPercent AS ClosedPVal ,
            ol.totalcount AS LeadsNumVal ,
            ol.EquipmentCost AS LeadsVal ,
            ol.EquipmentCost_avg AS LeadsVal_avg ,
            od.totalcount AS OpptyTotalNumVal ,
            od.leaseamount AS OpptyTotalVal ,
            od.leaseamount_avg AS OpptyTotalVal_avg ,
            od2.totalcount AS OpptyDiscoveryNumVal ,
            od2.leaseamount AS OpptyDiscoveryVal ,
            od2.leaseamount_avg AS OpptyDiscoveryVal_avg ,
            od3.totalcount AS OpptyInCreditNumVal ,
            od3.leaseamount AS OpptyInCreditVal ,
            od3.leaseamount_avg AS OpptyInCreditVal_avg ,
            od4.totalcount AS OpptyCreditApprovalNumVal ,
            od4.leaseamount AS OpptyCreditApprovalVal ,
            od4.leaseamount_avg AS OpptyCreditApprovalVal_avg ,
            od5.totalcount AS OpptyCreditDeclinedNumVal ,
            od5.leaseamount AS OpptyCreditDeclinedVal ,
            od5.leaseamount_avg AS OpptyCreditDeclinedVal_avg ,
            od6.totalcount AS OpptyDocumentsNumVal ,
            od6.leaseamount AS OpptyDocumentsVal ,
            od6.leaseamount_avg AS OpptyDocumentsVal_avg ,
            ev.AvgEvaluationRating AS EvaluationRatingsAvgVal ,
            ev.EvaluationRatingCount AS EvaluationRatingsCountVal ,
            ev.AvgEvaluationRatingExt AS EvaluationRatingsExternalCountVal ,
            ev.EvaluationRatingCountExt AS EvaluationRatingsExternalAvgVal ,
            ev.AvgEvaluationRatingIn AS EvaluationRatingsInternalAvgVal ,
            ev.EvaluationRatingCountIn AS EvaluationRatingsInternalCountVal ,
            act.totalActiveHours AS TotalActiveHoursVal ,
            act.[Non Work Hours] AS TotalNonWorkHoursVal ,
            act.[WorkHours] ,
            act.startdateminute ,
            act.enddateminute ,
            act.[Daily Start] AS AvgDailyStart ,
            act.[Daily End] AS AvgDailyEnd ,
            act.totalcall AS TotalCallsVal ,
            act.avgcalls AS AvgCallsPerDayVal ,
            act.totaldurationmin ,
            act.avgCallDuration ,
            act.avgcalldurationmin AS AvgCallDurationVal ,
            act.totalcallin AS IncomingCallsVal ,
            act.totalcallout AS OutgoingCallsVal ,
            act.totalcallint AS InternalCallsVal ,
            act.keystroke AS TotalKeystrokesVal ,
            act.totalemails AS TotalEmailsVal ,
            te.TotalExpense AS TEExpenseVal ,
            0 AS _sc_excluded
  INTO      #final
  FROM      #employees emp
            LEFT JOIN cte_accepted ON cte_accepted.username_group = emp.username_group
            LEFT JOIN #reviewedDeals rd ON rd.username_group = emp.username_group
            LEFT JOIN #reviewedTerms rt ON rt.username_group = emp.username_group
            LEFT JOIN #app app ON app.username_group = emp.username_group
            LEFT JOIN #fund fund ON fund.username_group = emp.username_group
            LEFT JOIN #TinyExpense te ON te.username_group = emp.username_group
            LEFT JOIN #OpenLeads ol ON ol.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 2
                      ) od2 ON od2.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 3
                      ) od3 ON od3.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 4
                      ) od4 ON od4.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 5
                      ) od5 ON od5.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 6
                      ) od6 ON od6.username_group = emp.username_group
            LEFT JOIN ( SELECT  username_group ,
                                totalcount ,
                                LeaseAmount ,
                                LeaseAmount_avg
                        FROM    #OpenDeals
                        WHERE   salesstagecode = 10
                      ) od ON od.username_group = emp.username_group

  --LEFT JOIN testscore_ind te
  --  ON te.username_group = emp.username_group
            LEFT JOIN cte_evaluation ev ON ev.username_group = emp.username_group
            LEFT JOIN cte_activity act ON act.username_group = emp.username_group


    DECLARE @em_count AS INT
    SELECT  @em_count = COUNT(username) - 1--exclude bfc total
    FROM    #employees
  
  
    INSERT  INTO #final
            ( [Index] ,
              ConsultantUserName ,
              ConsultantName ,
              ConsultantID ,
              ConsultantFullName ,
              StartDateVal ,
              EquipmentCostVal ,
              DealsVal ,
              AnnualizedDealsVal ,
              PortofolioOrigVal ,
              portfolioCount ,
              OneOffOrigVal ,
              oneoffCount ,
              PortOrigPercentVal ,
              OneOffOrigPercentVal ,
              TotalOrigVal ,
              AnnualizedTotalOrigVal ,
              TotalOrigInsideVal ,
              TotalOrigInsidePercentVal ,
              SecDepMVal ,
              SecDepPVal ,
              PurchOptVal ,
              PurchOptAvgVal ,
              InitialCashPercentVal ,
              RefFeeVal ,
              RefFeePtsVal ,
              OneOffProfitVal ,
              OneOffPtsVal ,
              IRRVal ,
              BeaconScoreVal ,
              FICOScoreVal ,
              TIBVal ,
              PaydexScoreVal ,
              UniqueDealsReviewedVal ,
              SubmissionsVal ,
              SubmissionsPerDealVal ,
              ApprovalPVal ,
              ClosedPVal ,
              LeadsNumVal ,
              LeadsVal ,
              LeadsVal_avg ,
              OpptyTotalNumVal ,
              OpptyTotalVal ,
              OpptyTotalVal_avg ,
              OpptyDiscoveryNumVal ,
              OpptyDiscoveryVal ,
              OpptyDiscoveryVal_avg ,
              OpptyInCreditNumVal ,
              OpptyInCreditVal ,
              OpptyInCreditVal_avg ,
              OpptyCreditApprovalNumVal ,
              OpptyCreditApprovalVal ,
              OpptyCreditApprovalVal_avg ,
              OpptyCreditDeclinedNumVal ,
              OpptyCreditDeclinedVal ,
              OpptyCreditDeclinedVal_avg ,
              OpptyDocumentsNumVal ,
              OpptyDocumentsVal ,
              OpptyDocumentsVal_avg ,
              EvaluationRatingsAvgVal ,
              EvaluationRatingsCountVal ,
              EvaluationRatingsExternalCountVal ,
              EvaluationRatingsExternalAvgVal ,
              EvaluationRatingsInternalAvgVal ,
              EvaluationRatingsInternalCountVal ,
              TotalActiveHoursVal ,
              TotalNonWorkHoursVal ,
              [WorkHours] ,
              startdateminute ,
              enddateminute ,
              AvgDailyStart ,
              AvgDailyEnd ,
              TotalCallsVal ,
              AvgCallsPerDayVal ,
              totaldurationmin ,
              avgCallDuration ,
              AvgCallDurationVal ,
              IncomingCallsVal ,
              OutgoingCallsVal ,
              InternalCallsVal ,
              TotalKeystrokesVal ,
              TotalEmailsVal ,
              TEExpenseVal ,
              _sc_excluded
            )
            SELECT  1 , -- Index - int
                    'BFC Avg.' , -- ConsultantUserName - varchar(50)
                    'BFC Avg.' , -- ConsultantName - varchar(50)
                    NULL , -- ConsultantID - uniqueidentifier
                    'Beacon Funding Corporation Average' , -- ConsultantFullName - varchar(100)          
                    @avg_startdate , -- StartDateVal - datetime
                    EquipmentCostVal_avg ,
                    DealsVal / @em_count ,
                    AnnualizedDealsVal / @em_count ,
                    PortofolioOrigVal_avg ,
                    portfolioCount / @em_count ,
                    OneOffOrigVal_avg ,
                    oneoffCount / @em_count ,
                    PortOrigPercentVal ,
                    OneOffOrigPercentVal ,
                    TotalOrigVal_avg ,
                    AnnualizedTotalOrigVal_avg ,
                    TotalOrigInsideVal_avg ,
                    TotalOrigInsidePercentVal ,
                    SecDepMVal_avg ,
                    SecDepPVal ,
                    PurchOptVal_avg ,
                    PurchOptAvgVal ,
                    InitialCashPercentVal ,
                    RefFeeVal_avg ,
                    RefFeePtsVal ,
                    OneOffProfitVal_avg ,
                    OneOffPtsVal ,
                    IRRVal ,
                    BeaconScoreVal ,
                    FICOScoreVal ,
                    TIBVal ,
                    PaydexScoreVal ,
                    UniqueDealsReviewedVal / @em_count ,
                    SubmissionsVal / @em_count ,
                    SubmissionsPerDealVal ,
                    ApprovalPVal ,
                    ClosedPVal ,
                    LeadsNumVal / @em_count , -- LeadsNumVal - int
                    LeadsVal_avg , -- LeadsVal - money
                    NULL , -- LeadsVal_avg - money
                    OpptyTotalNumVal / @em_count , -- OpptyTotalNumVal - int
                    OpptyTotalVal_avg , -- OpptyTotalVal - money
                    NULL , -- OpptyTotalVal_avg - money
                    OpptyDiscoveryNumVal / @em_count , -- OpptyDiscoveryNumVal - int
                    OpptyDiscoveryVal_avg , -- OpptyDiscoveryVal - money
                    NULL , -- OpptyDiscoveryVal_avg - money
                    OpptyInCreditNumVal / @em_count , -- OpptyInCreditNumVal - int
                    OpptyInCreditVal_avg , -- OpptyInCreditVal - money
                    NULL , -- OpptyInCreditVal_avg - money
                    OpptyCreditApprovalNumVal / @em_count , -- OpptyCreditApprovalNumVal - int
                    OpptyCreditApprovalVal_avg , -- OpptyCreditApprovalVal - money
                    NULL , -- OpptyCreditApprovalVal_avg - money
                    OpptyCreditDeclinedNumVal / @em_count , -- OpptyCreditDeclinedNumVal - int
                    OpptyCreditDeclinedVal_avg , -- OpptyCreditDeclinedVal - money
                    NULL , -- OpptyCreditDeclinedVal_avg - money
                    OpptyDocumentsNumVal / @em_count , -- OpptyDocumentsNumVal - int
                    OpptyDocumentsVal_avg , -- OpptyDocumentsVal - money
                    NULL ,  -- OpptyDocumentsVal_avg - money            
                    EvaluationRatingsAvgVal ,
                    EvaluationRatingsCountVal / @em_count ,
                    EvaluationRatingsExternalCountVal / @em_count ,
                    EvaluationRatingsExternalAvgVal ,
                    EvaluationRatingsInternalAvgVal ,
                    EvaluationRatingsInternalCountVal / @em_count ,
                    TotalActiveHoursVal / @em_count ,
                    TotalNonWorkHoursVal / @em_count ,
                    [WorkHours] / @em_count ,
                    startdateminute ,
                    enddateminute ,
                    AvgDailyStart ,
                    AvgDailyEnd ,
                    TotalCallsVal / @em_count ,
                    AvgCallsPerDayVal ,
                    totaldurationmin / @em_count ,
                    avgCallDuration ,
                    AvgCallDurationVal ,
                    IncomingCallsVal / @em_count ,
                    OutgoingCallsVal / @em_count ,
                    InternalCallsVal / @em_count ,
                    TotalKeystrokesVal / @em_count ,
                    TotalEmailsVal / @em_count ,
                    TEExpenseVal / @em_count ,
                    1
            FROM    #final
            WHERE   [index] = 0
      
    UPDATE  #final
    SET     StartDateVal = NULL ,
            PortOrigPercentVal = NULL ,
            OneOffOrigPercentVal = NULL ,
            TotalOrigInsidePercentVal = NULL ,
            SecDepPVal = NULL ,
            PurchOptAvgVal = NULL ,
            InitialCashPercentVal = NULL ,
            RefFeePtsVal = NULL ,
            OneOffPtsVal = NULL ,
            IRRVal = NULL ,
            BeaconScoreVal = NULL ,
            FICOScoreVal = NULL ,
            TIBVal = NULL ,
            PaydexScoreVal = NULL ,
            SubmissionsPerDealVal = NULL ,
            ApprovalPVal = NULL ,
            ClosedPVal = NULL ,
            EvaluationRatingsAvgVal = NULL ,
            EvaluationRatingsExternalAvgVal = NULL ,
            EvaluationRatingsInternalAvgVal = NULL ,
            startdateminute = NULL ,
            enddateminute = NULL ,
            AvgDailyStart = NULL ,
            AvgDailyEnd = NULL ,
            AvgCallsPerDayVal = NULL ,
            avgCallDuration = NULL ,
            AvgCallDurationVal = NULL ,
            _sc_excluded = 1
    WHERE   [index] = 0  
    
    UPDATE  #final
    SET     _sc_excluded = 1
    WHERE   ConsultantID = @MiscOutsideSalesID
            OR DATEDIFF(MONTH, StartDateVal, GETDATE()) < 6
    
	ALTER TABLE #final ALTER COLUMN _sc_excluded BIT

    IF @OutsideSalesID IS NULL 
        BEGIN
    
   
    
    
            SELECT  [Index] ,
                    ConsultantUserName ,
                    ConsultantName ,
                    ConsultantID ,
                    ConsultantFullName ,
                    StartDateVal AS StartDateVal ,
                    EquipmentCostVal ,
                    DealsVal ,
                    AnnualizedDealsVal ,
                    PortofolioOrigVal ,
                    portfolioCount ,
                    OneOffOrigVal ,
                    oneoffCount ,
                    PortOrigPercentVal ,
                    OneOffOrigPercentVal ,
                    TotalOrigVal ,
                    AnnualizedTotalOrigVal ,
                    TotalOrigInsideVal ,
                    TotalOrigInsidePercentVal ,
                    SecDepMVal ,
                    SecDepPVal ,
                    PurchOptVal ,
                    PurchOptAvgVal ,
                    InitialCashPercentVal ,
                    RefFeeVal ,
                    RefFeePtsVal ,
                    OneOffProfitVal ,
                    OneOffPtsVal ,
                    IRRVal ,
                    BeaconScoreVal ,
                    FICOScoreVal ,
                    TIBVal ,
                    PaydexScoreVal ,
                    UniqueDealsReviewedVal ,
                    SubmissionsVal ,
                    SubmissionsPerDealVal ,
                    ApprovalPVal ,
                    ClosedPVal ,
                    LeadsNumVal ,
                    LeadsVal ,
                    OpptyTotalNumVal ,
                    OpptyTotalVal ,
                    OpptyDiscoveryNumVal ,
                    OpptyDiscoveryVal ,
                    OpptyInCreditNumVal ,
                    OpptyInCreditVal ,
                    OpptyCreditApprovalNumVal ,
                    OpptyCreditApprovalVal ,
                    OpptyCreditDeclinedNumVal ,
                    OpptyCreditDeclinedVal ,
                    OpptyDocumentsNumVal ,
                    OpptyDocumentsVal ,
                    EvaluationRatingsAvgVal ,
                    EvaluationRatingsCountVal ,
                    EvaluationRatingsExternalCountVal ,
                    EvaluationRatingsExternalAvgVal ,
                    EvaluationRatingsInternalAvgVal ,
                    EvaluationRatingsInternalCountVal ,
                    TotalActiveHoursVal ,
                    TotalNonWorkHoursVal ,
                    [WorkHours] ,
                    startdateminute ,
                    enddateminute ,
                    AvgDailyStart ,
                    AvgDailyEnd ,
                    TotalCallsVal ,
                    AvgCallsPerDayVal ,
                    totaldurationmin ,
                    avgCallDuration ,
                    AvgCallDurationVal ,
                    IncomingCallsVal ,
                    OutgoingCallsVal ,
                    InternalCallsVal ,
                    TotalKeystrokesVal ,
                    TotalEmailsVal ,
                    TEExpenseVal ,
                    _sc_excluded
            FROM    #final  
        END
    ELSE 
        BEGIN
     
     
    
    
            SELECT  CASE WHEN ConsultantID = @outsideSalesid THEN 0 ELSE [index] END AS [Index] ,
                    ConsultantUserName ,
                    ConsultantName ,
                    ConsultantID ,
                    ConsultantFullName ,
                    StartDateVal AS StartDateVal ,
                    EquipmentCostVal ,
                    DealsVal ,
                    AnnualizedDealsVal ,
                    PortofolioOrigVal ,
                    portfolioCount ,
                    OneOffOrigVal ,
                    oneoffCount ,
                    PortOrigPercentVal ,
                    OneOffOrigPercentVal ,
                    TotalOrigVal ,
                    AnnualizedTotalOrigVal ,
                    TotalOrigInsideVal ,
                    TotalOrigInsidePercentVal ,
                    SecDepMVal ,
                    SecDepPVal ,
                    PurchOptVal ,
                    PurchOptAvgVal ,
                    InitialCashPercentVal ,
                    RefFeeVal ,
                    RefFeePtsVal ,
                    OneOffProfitVal ,
                    OneOffPtsVal ,
                    IRRVal ,
                    BeaconScoreVal ,
                    FICOScoreVal ,
                    TIBVal ,
                    PaydexScoreVal ,
                    UniqueDealsReviewedVal ,
                    SubmissionsVal ,
                    SubmissionsPerDealVal ,
                    ApprovalPVal ,
                    ClosedPVal ,
                    LeadsNumVal ,
                    LeadsVal ,
                    OpptyTotalNumVal ,
                    OpptyTotalVal ,
                    OpptyDiscoveryNumVal ,
                    OpptyDiscoveryVal ,
                    OpptyInCreditNumVal ,
                    OpptyInCreditVal ,
                    OpptyCreditApprovalNumVal ,
                    OpptyCreditApprovalVal ,
                    OpptyCreditDeclinedNumVal ,
                    OpptyCreditDeclinedVal ,
                    OpptyDocumentsNumVal ,
                    OpptyDocumentsVal ,
                    EvaluationRatingsAvgVal ,
                    EvaluationRatingsCountVal ,
                    EvaluationRatingsExternalCountVal ,
                    EvaluationRatingsExternalAvgVal ,
                    EvaluationRatingsInternalAvgVal ,
                    EvaluationRatingsInternalCountVal ,
                    TotalActiveHoursVal ,
                    TotalNonWorkHoursVal ,
                    [WorkHours] ,
                    startdateminute ,
                    enddateminute ,
                    AvgDailyStart ,
                    AvgDailyEnd ,
                    TotalCallsVal ,
                    AvgCallsPerDayVal ,
                    totaldurationmin ,
                    avgCallDuration ,
                    AvgCallDurationVal ,
                    IncomingCallsVal ,
                    OutgoingCallsVal ,
                    InternalCallsVal ,
                    TotalKeystrokesVal ,
                    TotalEmailsVal ,
                    TEExpenseVal
            FROM    #final
            WHERE   [index] = 1--bfc avg
                    OR ConsultantID = @outsideSalesid
            UNION ALL
            SELECT  2 ,
                    'Difference' ,
                    'Difference' ,
                    NULL ,
                    'Difference' ,
                   NULL ,
                    fi.EquipmentCostVal - fa.EquipmentCostVal ,
                    fi.DealsVal - fa.DealsVal ,
                    fi.AnnualizedDealsVal - fa.AnnualizedDealsVal ,
                    fi.PortofolioOrigVal - fa.PortofolioOrigVal ,
                    fi.portfolioCount - fa.portfolioCount ,
                    fi.OneOffOrigVal - fa.OneOffOrigVal ,
                    fi.oneoffCount - fa.oneoffCount ,
                    fi.PortOrigPercentVal - fa.PortOrigPercentVal ,
                    fi.OneOffOrigPercentVal - fa.OneOffOrigPercentVal ,
                    fi.TotalOrigVal - fa.TotalOrigVal ,
                    fi.AnnualizedTotalOrigVal - fa.AnnualizedTotalOrigVal ,
                    fi.TotalOrigInsideVal - fa.TotalOrigInsideVal ,
                    fi.TotalOrigInsidePercentVal
                    - fa.TotalOrigInsidePercentVal ,
                    fi.SecDepMVal - fa.SecDepMVal ,
                    fi.SecDepPVal - fa.SecDepPVal ,
                    fi.PurchOptVal - fa.PurchOptVal ,
                    fi.PurchOptAvgVal - fa.PurchOptAvgVal ,
                    fi.InitialCashPercentVal - fa.InitialCashPercentVal ,
                    fi.RefFeeVal - fa.RefFeeVal ,
                    fi.RefFeePtsVal - fa.RefFeePtsVal ,
                    fi.OneOffProfitVal - fa.OneOffProfitVal ,
                    fi.OneOffPtsVal - fa.OneOffPtsVal ,
                    fi.IRRVal - fa.IRRVal ,
                    fi.BeaconScoreVal - fa.BeaconScoreVal ,
                    fi.FICOScoreVal - fa.FICOScoreVal ,
                    fi.TIBVal - fa.TIBVal ,
                    fi.PaydexScoreVal - fa.PaydexScoreVal ,
                    fi.UniqueDealsReviewedVal - fa.UniqueDealsReviewedVal ,
                    fi.SubmissionsVal - fa.SubmissionsVal ,
                    fi.SubmissionsPerDealVal - fa.SubmissionsPerDealVal ,
                    fi.ApprovalPVal - fa.ApprovalPVal ,
                    fi.ClosedPVal - fa.ClosedPVal ,
                    fi.LeadsNumVal - fa.LeadsNumVal ,
                    fi.LeadsVal - fa.LeadsVal ,
                    fi.OpptyTotalNumVal - fa.OpptyTotalNumVal ,
                    fi.OpptyTotalVal - fa.OpptyTotalVal ,
                    fi.OpptyDiscoveryNumVal - fa.OpptyDiscoveryNumVal ,
                    fi.OpptyDiscoveryVal - fa.OpptyDiscoveryVal ,
                    fi.OpptyInCreditNumVal - fa.OpptyInCreditNumVal ,
                    fi.OpptyInCreditVal - fa.OpptyInCreditVal ,
                    fi.OpptyCreditApprovalNumVal
                    - fa.OpptyCreditApprovalNumVal ,
                    fi.OpptyCreditApprovalVal - fa.OpptyCreditApprovalVal ,
                    fi.OpptyCreditDeclinedNumVal
                    - fa.OpptyCreditDeclinedNumVal ,
                    fi.OpptyCreditDeclinedVal - fa.OpptyCreditDeclinedVal ,
                    fi.OpptyDocumentsNumVal - fa.OpptyDocumentsNumVal ,
                    fi.OpptyDocumentsVal - fa.OpptyDocumentsVal ,
                    fi.EvaluationRatingsAvgVal - fa.EvaluationRatingsAvgVal ,
                    fi.EvaluationRatingsCountVal
                    - fa.EvaluationRatingsCountVal ,
                    fi.EvaluationRatingsExternalCountVal
                    - fa.EvaluationRatingsExternalCountVal ,
                    fi.EvaluationRatingsExternalAvgVal
                    - fa.EvaluationRatingsExternalAvgVal ,
                    fi.EvaluationRatingsInternalAvgVal
                    - fa.EvaluationRatingsInternalAvgVal ,
                    fi.EvaluationRatingsInternalCountVal
                    - fa.EvaluationRatingsInternalCountVal ,
                    fi.TotalActiveHoursVal - fa.TotalActiveHoursVal ,
                    fi.TotalNonWorkHoursVal - fa.TotalNonWorkHoursVal ,
                    fi.[WorkHours] - fa.[WorkHours] ,
                    fi.startdateminute - fa.startdateminute ,
                    fi.enddateminute - fa.enddateminute ,
                    CAST(fi.startdateminute - fa.startdateminute AS VARCHAR(10))
                    + ' min' ,
                    CAST(fi.enddateminute - fa.enddateminute AS VARCHAR(10))
                    + ' min' ,
                    fi.TotalCallsVal - fa.TotalCallsVal ,
                    fi.AvgCallsPerDayVal - fa.AvgCallsPerDayVal ,
                    fi.totaldurationmin - fa.totaldurationmin ,
                    fi.avgCallDuration - fa.avgCallDuration ,
                    fi.AvgCallDurationVal - fa.AvgCallDurationVal ,
                    fi.IncomingCallsVal - fa.IncomingCallsVal ,
                    fi.OutgoingCallsVal - fa.OutgoingCallsVal ,
                    fi.InternalCallsVal - fa.InternalCallsVal ,
                    fi.TotalKeystrokesVal - fa.TotalKeystrokesVal ,
                    fi.TotalEmailsVal - fa.TotalEmailsVal ,
                    fi.TEExpenseVal - fa.TEExpenseVal
            FROM    #final fi
                    INNER JOIN #final fa ON fi.ConsultantID = @OutsideSalesID
                                            AND fa.[index] = 1--'BFC Avg.'     
			ORDER BY [Index]
        END
     
    
 


--KeyStats_Sales_LoadOutsideSales '1/01/2015','12/22/2015'
GO
