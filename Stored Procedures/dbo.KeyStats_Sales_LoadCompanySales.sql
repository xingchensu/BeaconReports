SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:    	Leonardo Tanoue
--				Ruonan Wen				
-- Create date: 12/15/2015
-- Description:	Loads Key Stats Sales' Company 
--				Sales View Data 
-- Xingchen 12/30/2015 - Add drilldown filters
-- =============================================
--KeyStats_Sales_LoadCompanySales '1/01/2015','12/31/2015',null,'DD9D3EA7-5A44-E011-959E-78E7D1F817F8'
CREATE PROCEDURE [dbo].[KeyStats_Sales_LoadCompanySales]
    @DateFrom DATETIME ,
    @DateTo DATETIME ,
    @fundingMethod AS INT = NULL ,
    @OutsideSalesID AS UNIQUEIDENTIFIER = NULL,
    @InsideSalesID AS UNIQUEIDENTIFIER = NULL,
    @CreditManagerID AS UNIQUEIDENTIFIER = NULL
AS 
/*

DECLARE @DateFrom datetime
DECLARE @DateTo datetime
DECLARE @fundingMethod AS int 
DECLARE @OutsideSalesID AS UNIQUEIDENTIFIER
DECLARE @InsideSalesID AS UNIQUEIDENTIFIER
DECLARE @CreditManagerID AS UNIQUEIDENTIFIER
SET @DateFrom = '1/01/2016'
SET @DateTo = '1/02/2016'
SET @fundingMethod = NULL
SET @OutsideSalesID = NULL --'DD9D3EA7-5A44-E011-959E-78E7D1F817F8'
SET @InsideSalesID = NULL
SET @CreditManagerID = NULL
*/
--Dates
    DECLARE @DateFrom_last AS DATETIME
    DECLARE @DateTo_last AS DATETIME
    DECLARE @DateFrom_preyear AS DATETIME
    DECLARE @DateTo_preyear AS DATETIME
    DECLARE @DateFrom_pre2year AS DATETIME
    DECLARE @DateTo_pre2year AS DATETIME
    SET @DateFrom_last = DATEADD(YEAR, -1, @DateFrom)
    SET @DateTo_last = DATEADD(YEAR, -1, @DateTo)
    SET @DateFrom_preyear = CAST('01/01/'
        + CAST(YEAR(@DateFrom_last) AS CHAR(4)) AS DATETIME)
    SET @DateTo_preyear = CAST('12/31/' + CAST(YEAR(@DateTo_last) AS CHAR(4)) AS DATETIME)
    SET @DateFrom_pre2year = DATEADD(YEAR, -1, @DateFrom_preyear)
    SET @DateTo_pre2year = DATEADD(YEAR, -1, @DateTo_preyear)

	DECLARE @ConsultantName AS VARCHAR(200)
	SET @ConsultantName = 'BFC Total'

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
          fullname VARCHAR(200) ,
          CRMGuid UNIQUEIDENTIFIER ,
          username VARCHAR(20) ,
          UniqueUserId INT ,
          userid INT ,
          IntranetTable VARCHAR(20)
        )
        INSERT  INTO #employees
                ( fullname ,
                    CRMGuid ,
                    username ,
                    UniqueUserId ,
                    userid ,
                    IntranetTable
                )
                SELECT  em.lname + ', ' + em.fname AS fullname ,
                        em.CRMGuid ,
                        em.username ,
                        em.UniqueUserId ,
                        em.userid ,
                        em.IntranetTable
                FROM    dbo.KeyStats_AllEmployees em
                        INNER JOIN dbo.KeyStats_Category_Employee_Relation r ON r.UniqueUserId = em.UniqueUserId
                        INNER JOIN dbo.KeyStats_Categories c ON r.CategoryID = c.CategoryID
                WHERE   c.CategoryID = @categoryID
				AND (em.CRMGuid = @OutsideSalesID OR @OutsideSalesID IS NULL)
				AND (em.CRMGuid = @InsideSalesID OR @InsideSalesID IS NULL)

	IF @OutsideSalesID IS NOT NULL
	BEGIN
		SELECT @ConsultantName = FName + ' ' + LName FROM KeyStats_AllEmployees WHERE CRMGuid = @OutsideSalesID 				
	END
	ELSE IF @InsideSalesID IS NOT NULL
	BEGIN
		SELECT @ConsultantName = FName + ' ' + LName FROM KeyStats_AllEmployees WHERE CRMGuid = @InsideSalesID 				
	END
	ELSE IF @CreditManagerID IS NOT NULL
	BEGIN
		SELECT @ConsultantName = FName + ' ' + LName FROM KeyStats_AllEmployees WHERE CRMGuid = @CreditManagerID 				
	END  
	ELSE
	BEGIN
		SET @ConsultantName = 'BFC Total'  
    END
    
--Date Range Group or Header Names, Temp Table
    IF OBJECT_ID('tempdb..#DateRangeGroup') IS NOT NULL 
        BEGIN
            DROP TABLE #DateRangeGroup
        END
    CREATE TABLE #DateRangeGroup
        (
          id INT NOT NULL ,
          name [varchar](50) NULL
        )

    INSERT  INTO #DateRangeGroup
            SELECT  0 AS [id] ,
                    @ConsultantName + '<br />'
                    + CONVERT(VARCHAR(4), YEAR(@dateFrom_pre2year)) AS name
            UNION
            SELECT  1 AS [id] ,
                    @ConsultantName + '<br />'
                    + CONVERT(VARCHAR(4), YEAR(@dateFrom_preyear)) AS name
            UNION
            SELECT  2 AS [id] ,
                    @ConsultantName + '<br />' + CONVERT(VARCHAR(10), @dateFrom, 101)
                    + ' - ' + CONVERT(VARCHAR(10), @dateTo, 101) AS name
            UNION
            SELECT  3 AS [id] ,
                    @ConsultantName + '<br />' + CONVERT(VARCHAR(10), @dateFrom_last, 101)
                    + ' - ' + CONVERT(VARCHAR(10), @dateTo_last, 101) AS name
  

--Snapshot dates
    DECLARE @dateSnapshot AS DATE
    DECLARE @dateSnapshot_last AS DATE
    DECLARE @dateSnapshot_preyear AS DATE
    DECLARE @dateSnapshot_pre2year AS DATE

    SET @dateSnapshot = @dateTo
    SET @dateSnapshot_last = @dateTo_last
    SET @dateSnapshot_preyear = @dateTo_preyear
    SET @dateSnapshot_pre2year = @dateTo_pre2year



--convert to UTC
    SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                            @dateFrom)
    SET @dateTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo)

    SET @dateFrom_last = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                                 @dateFrom_last)
    SET @dateTo_last = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                               @dateTo_last)

    SET @dateFrom_preyear = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                                    @dateFrom_preyear)
    SET @dateTo_preyear = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                                  @dateTo_preyear)

    SET @dateFrom_pre2year = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                                     @dateFrom_pre2year)
    SET @dateTo_pre2year = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),
                                   @dateTo_pre2year)

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
          OtherIncomeExpense MONEY NULL ,
          DateRangeGroup INT NULL
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
		[consultantId],OtherIncomeExpense,
		DateRangeGroup)
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
		[consultantId],OtherIncomeExpense,
		0
	FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] 
    where [acceptanceDate]>= @dateFrom_pre2year AND [acceptanceDate] <= @dateTo_pre2year
			AND (FundingMethodValue = @fundingMethod OR @fundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	UNION ALL
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
		[consultantId],OtherIncomeExpense,
		1
	FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] 
	where [acceptanceDate]>= @dateFrom_preyear AND [acceptanceDate] <= @dateTo_preyear
			AND (FundingMethodValue = @fundingMethod OR @fundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	UNION ALL 
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
		[consultantId],OtherIncomeExpense,
		2
	FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot]
    where [acceptanceDate]>= @dateFrom AND [acceptanceDate] <= @dateTo
			AND (FundingMethodValue = @fundingMethod OR @fundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	UNION ALL 
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
		[consultantId],OtherIncomeExpense,
		3
	FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot]  
	where [acceptanceDate]>= @dateFrom_last AND [acceptanceDate] <= @dateTo_last
			AND (FundingMethodValue = @fundingMethod OR @fundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	

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
            [oneoffProfitPts] ,
            [IRR] ,
            [AVGBeaconScore] ,
            [AVGFICOScore] ,
            [tib] ,
            [paydex] ,
            [insideSales] ,
            [consultant] AS Owner
    FROM    #details
    WHERE   DateRangeGroup = 2;

-- ********** Accepted Opportunities (sales details data) **********

--open lead 
    IF OBJECT_ID('tempdb..#OpenLeads') IS NOT NULL 
        BEGIN
            DROP TABLE #OpenLeads
        END
    CREATE TABLE #OpenLeads
        (
          totalcount INT NULL ,
          EquipmentCost [money] NULL ,
          DateRangeGroup INT NULL
        )
    
    insert into #OpenLeads
    (totalcount,
    EquipmentCost,
    DateRangeGroup)
    select sum(1),sum(EquipmentCost),0
    from [KeyStats_OpenLeadPipeline_DailySnapshot]
	where [SnapshotDate] = @dateSnapshot_pre2year
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
    union all
    select sum(1),sum(EquipmentCost),1
    from [KeyStats_OpenLeadPipeline_DailySnapshot]
	where [SnapshotDate] = @dateSnapshot_preyear
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
    union all
    select sum(1),sum(EquipmentCost),2
    from [KeyStats_OpenLeadPipeline_DailySnapshot]
	where [SnapshotDate] = @dateSnapshot
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
    union all
    select sum(1),sum(EquipmentCost),3
    from [KeyStats_OpenLeadPipeline_DailySnapshot]
	where [SnapshotDate] = @dateSnapshot_last
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)

    IF OBJECT_ID('tempdb..#OpenDeals') IS NOT NULL 
        BEGIN
            DROP TABLE #OpenDeals
        END
    CREATE TABLE #OpenDeals
        (
          totalcount INT NULL ,
          [salesstagecode] [tinyint] NULL ,
          [LeaseAmount] [money] NULL ,
          DateRangeGroup INT NULL
        )
    
    INSERT INTO #OpenDeals
    (totalcount,
    [salesstagecode],		
    [LeaseAmount],		
    DateRangeGroup)
    SELECT
    sum(1),
    [salesstagecode], 
    sum([LeaseAmount]),
    0
    FROM [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot] 
	where [SnapshotDate] = @dateSnapshot_pre2year
			AND (fundingmethodvalue = @FundingMethod OR @FundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	group by salesstagecode
    UNION ALL 
    SELECT
    sum(1),
    [salesstagecode], 
    sum([LeaseAmount]),
    1
    FROM [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot] 	
	where [SnapshotDate] = @dateSnapshot_preyear
			AND (fundingmethodvalue = @FundingMethod OR @FundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	group by salesstagecode
    UNION ALL 
    SELECT
    sum(1),
    [salesstagecode], 
    sum([LeaseAmount]),
    2
    FROM [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot] 	
	where [SnapshotDate] = @dateSnapshot
			AND (fundingmethodvalue = @FundingMethod OR @FundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)	
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
	group by salesstagecode
    UNION ALL 
    SELECT
    sum(1),
    [salesstagecode], 
    sum([LeaseAmount]),
    3
    FROM [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot] 
	where [SnapshotDate] = @dateSnapshot_last
			AND (fundingmethodvalue = @FundingMethod OR @FundingMethod IS NULL)
			AND (consultantId = @OutsideSalesID OR @OutsideSalesID IS NULL)
			AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
			AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
    group by salesstagecode

      
---- ********** Activity **********
    IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot_all') IS NOT NULL 
        BEGIN
            DROP TABLE #SpectorDailyAdminDataSnapShot_all
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
    INTO    #SpectorDailyAdminDataSnapShot_all
    FROM    LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
    WHERE   [SnapshotDate] >= @dateFrom_pre2year
            AND [SnapshotDate] <= @dateTo
            AND DirectoryName IN ( SELECT   username
                                   FROM     #employees )
   
    IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL 
        BEGIN
            DROP TABLE #SpectorDailyAdminDataSnapShot
        END

    SELECT  * ,
            0 AS DateRangeGroup
    INTO    #SpectorDailyAdminDataSnapShot
    FROM    #SpectorDailyAdminDataSnapShot_all
    WHERE   [SnapshotDate] >= @dateFrom_pre2year
            AND [SnapshotDate] <= @dateTo_pre2year    

    INSERT  INTO #SpectorDailyAdminDataSnapShot
            SELECT  * ,
                    1 AS DateRangeGroup
            FROM    #SpectorDailyAdminDataSnapShot_all
            WHERE   [SnapshotDate] >= @dateFrom_preyear
                    AND [SnapshotDate] <= @dateTo_preyear
            UNION ALL
            SELECT  * ,
                    2 AS DateRangeGroup
            FROM    #SpectorDailyAdminDataSnapShot_all
            WHERE   [SnapshotDate] >= @dateFrom
                    AND [SnapshotDate] <= @dateTo
            UNION ALL
            SELECT  * ,
                    3 AS DateRangeGroup
            FROM    #SpectorDailyAdminDataSnapShot_all
            WHERE   [SnapshotDate] >= @dateFrom_last
                    AND [SnapshotDate] <= @dateTo_last
 

---- ********** Evaluation **********

    IF OBJECT_ID('tempdb..#evaluation') IS NOT NULL 
        BEGIN	
            DROP TABLE #evaluation
        END

    SELECT  [Rating] ,
            [EvaluationTypeValue] ,
            0 AS DateRangeGroup
    INTO    #evaluation
    FROM    [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
    WHERE   [EvaluateForID] IN ( SELECT CRMGuid
                                 FROM   #employees )
            AND [ActualCloseDate] >= @dateFrom_pre2year
            AND [ActualCloseDate] <= @dateTo_pre2year

    INSERT  INTO #evaluation
            SELECT  [Rating] ,
                    [EvaluationTypeValue] ,
                    1 AS DateRangeGroup
            FROM    [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
            WHERE   [EvaluateForID] IN ( SELECT CRMGuid
                                         FROM   #employees )
                    AND [ActualCloseDate] >= @dateFrom_preyear
                    AND [ActualCloseDate] <= @dateTo_preyear
            UNION ALL
            SELECT  [Rating] ,
                    [EvaluationTypeValue] ,
                    2 AS DateRangeGroup
            FROM    [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
            WHERE   [EvaluateForID] IN ( SELECT CRMGuid
                                         FROM   #employees )
                    AND [ActualCloseDate] >= @dateFrom
                    AND [ActualCloseDate] <= @dateTo
            UNION ALL
            SELECT  [Rating] ,
                    [EvaluationTypeValue] ,
                    3 AS DateRangeGroup
            FROM    [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
            WHERE   [EvaluateForID] IN ( SELECT CRMGuid
                                         FROM   #employees )
                    AND [ActualCloseDate] >= @dateFrom_last
                    AND [ActualCloseDate] <= @dateTo_last
  
  
  --t&e
		

    IF OBJECT_ID('tempdb..#TinyExpense') IS NOT NULL 
        BEGIN

            DROP TABLE #TinyExpense

        END
  
    SELECT  SUM(expenseAmount) AS TotalExpense ,
            ExpenseDate
    INTO    #TinyExpense
    FROM    intranet_beaconfunding.dbo.Exp_Expenses ex
            LEFT JOIN intranet_beaconfunding.dbo.Exp_Reports r ON r.ReportID = ex.ReportID
            LEFT JOIN intranet_beaconfunding.dbo.Exp_ExpenseTypes t ON ex.ExpenseTypeID = t.ExpenseTypeID
            LEFT JOIN intranet_beaconfunding.dbo.Exp_StatusReasons s ON r.StatusReasonId = s.StatusReasonId
    WHERE   ExpenseID NOT IN ( 1794, 1803, 1807, 1823 )
            AND GLAccount IN ( 6040, 6090, 6220, 6287, 6634 )
            AND StatusReason LIKE 'Approved'
            AND ExpenseDate >= @dateFrom_pre2year
            AND ExpenseDate <= @dateTo
            AND r.UserID IN ( SELECT    userid
                              FROM      #employees
                              WHERE     IntranetTable = 'Beacon' )
    GROUP BY ExpenseDate

  
-- ********** Company Sales **********
  
    IF OBJECT_ID('tempdb..#final') IS NOT NULL 
        BEGIN
            DROP TABLE #final
        END;

    WITH    cte_accepted
              AS ( SELECT   daterangegroup ,
                            SUM(1) AS [totalCount] ,	--Number of Deals
                            ( SUM(1) * @AnnualizedRate ) AS [annualizedTotalCount] , --Annulaized totalCount
                            SUM([EquipmentCost]) AS [EquipmentCost] , --Equipment Cost
                            SUM(CASE WHEN [FundingMethodValue] = 1
                                     THEN [leaseAmt]
                                     ELSE 0
                                END) AS [portfolioleaseAmt] , --Portofolio Originations
                            SUM(CASE WHEN [FundingMethodValue] = 1 THEN 1
                                     ELSE 0
                                END) AS [portfolioCount] , --Portofolio Count
                            SUM(CASE WHEN [FundingMethodValue] = 1 THEN 0
                                     ELSE [leaseAmt]
                                END) AS [oneoffleaseAmt] , --One-Off Originations
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
                            SUM([leaseAmt] * @AnnualizedRate) AS [annualizedLeaseAmt] , --Annualized Total Originations
                            SUM(CASE WHEN [insideSalesid] IS NOT NULL
                                     THEN [leaseAmt]
                                     ELSE 0
                                END) AS [leaseAmtInsideSales] , --Total Originations - Inside Sales
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( SUM(CASE WHEN [insideSalesid] IS NOT NULL
                                                 THEN [leaseAmt]
                                                 ELSE 0
                                            END) / SUM(ISNULL([leaseAmt], 0)) )
                            END AS [leastAmtInsideSalesPercent] , --Total Originations - Inside Sales %
                            SUM([securityDeposit]) AS [securityDeposit] , --Security Deposit $, regardless of eligibility
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
                            CASE WHEN SUM(ISNULL([leaseAmt], 0)) <= 0
                                 THEN NULL
                                 ELSE ( ( SUM([TotalReferralFee])
                                          / SUM(ISNULL([leaseAmt], 0)) ) * 100 )
                            END AS [totalReferralFeePts] , --[TotalReferralFee] Referral Fee Points
                            SUM([oneoffProfit]) AS [oneoffProfit] , --One Off Profit $
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
                                 ELSE ( SUM(( [IRR] / 100 ) * [leaseAmt])
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
                   GROUP BY daterangegroup
                 ),
            cte_reviewedDeals
              AS ( SELECT   COUNT(DISTINCT opportunityid) AS UniqueDealsReviewed ,
                            3 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    reviewedon >= @DateFrom_last
                            AND reviewedon <= @DateTo_last
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT(DISTINCT opportunityid) AS UniqueDealsReviewed ,
                            2 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    reviewedon >= @DateFrom
                            AND reviewedon <= @DateTo
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT(DISTINCT opportunityid) AS UniqueDealsReviewed ,
                            1 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    reviewedon >= @DateFrom_preyear
                            AND reviewedon <= @DateTo_preyear
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT(DISTINCT opportunityid) AS UniqueDealsReviewed ,
                            0 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    reviewedon >= @DateFrom_pre2year
                            AND reviewedon <= @DateTo_pre2year
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                 ),
            cte_submittedTerms
              AS ( SELECT   COUNT([termid]) AS TermsSubmitted ,
                            3 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    [submission date] >= @DateFrom_last
                            AND [submission date] <= @DateTo_last
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT([termid]) AS TermsSubmitted ,
                            2 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    [submission date] >= @DateFrom
                            AND [submission date] <= @DateTo
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT([termid]) AS TermsSubmitted ,
                            1 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    [submission date] >= @DateFrom_preyear
                            AND [submission date] <= @DateTo_preyear
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   COUNT([termid]) AS TermsSubmitted ,
                            0 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
                   WHERE    [submission date] >= @DateFrom_pre2year
                            AND [submission date] <= @DateTo_pre2year
							AND (consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                 ),
            cte_app
              AS ( SELECT   CAST(SUM(CASE WHEN a.ApprovalDate IS NULL
                                               OR a.ApprovalDate > @DateTo
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS appPercent ,
                            2 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] s
                            LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a ON s.[opid] = a.[opid]
                   WHERE    s.[SubmitDate] >= DATEADD(year, -1, @DateTo)
                            AND s.[SubmitDate] <= @DateTo
							AND (s.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (s.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (s.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN a.ApprovalDate IS NULL
                                               OR a.ApprovalDate > @DateTo_last
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS appPercent ,
                            3 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] s
                            LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a ON s.[opid] = a.[opid]
                   WHERE    s.[SubmitDate] >= DATEADD(year, -1, @DateTo_last)
                            AND s.[SubmitDate] <= @DateTo_last
							AND (s.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (s.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (s.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN a.ApprovalDate IS NULL
                                               OR a.ApprovalDate > @DateTo_preyear
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS appPercent ,
                            1 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] s
                            LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a ON s.[opid] = a.[opid]
                   WHERE    s.[SubmitDate] >= DATEADD(year, -1,
                                                      @DateTo_preyear)
                            AND s.[SubmitDate] <= @DateTo_preyear
							AND (s.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (s.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (s.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN a.ApprovalDate IS NULL
                                               OR a.ApprovalDate > @DateTo_pre2year
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS appPercent ,
                            0 AS DateRangeGroup
                   FROM     [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] s
                            LEFT JOIN dbo.KeyStats_ApprovedOpportunity_HourlySnapshot a ON s.[opid] = a.[opid]
                   WHERE    s.[SubmitDate] >= DATEADD(year, -1,
                                                      @DateTo_pre2year)
                            AND s.[SubmitDate] <= @DateTo_pre2year
							AND (s.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (s.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (s.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                 ),
            cte_fund
              AS ( SELECT   CAST(SUM(CASE WHEN f.FundDate IS NULL
                                               OR f.FundDate > @DateTo THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS fundPercent ,
                            2 AS DateRangeGroup
                   FROM     [dbo].KeyStats_ApprovedOpportunity_HourlySnapshot a
                            LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f ON a.[opid] = f.[opid]
                   WHERE    a.ApprovalDate >= DATEADD(year, -1, @DateTo)
                            AND a.ApprovalDate <= @DateTo
							AND (a.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (a.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (a.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN f.FundDate IS NULL
                                               OR f.FundDate > @DateTo_last
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS fundPercent ,
                            3 AS DateRangeGroup
                   FROM     [dbo].KeyStats_ApprovedOpportunity_HourlySnapshot a
                            LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f ON a.[opid] = f.[opid]
                   WHERE    a.ApprovalDate >= DATEADD(year, -1, @DateTo_last)
                            AND a.ApprovalDate <= @DateTo_last
							AND (a.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (a.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (a.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN f.FundDate IS NULL
                                               OR f.FundDate > @DateTo_preyear
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS fundPercent ,
                            1 AS DateRangeGroup
                   FROM     [dbo].KeyStats_ApprovedOpportunity_HourlySnapshot a
                            LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f ON a.[opid] = f.[opid]
                   WHERE    a.ApprovalDate >= DATEADD(year, -1,
                                                      @DateTo_preyear)
                            AND a.ApprovalDate <= @DateTo_preyear
							AND (a.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (a.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (a.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                   UNION ALL
                   SELECT   CAST(SUM(CASE WHEN f.FundDate IS NULL
                                               OR f.FundDate > @DateTo_pre2year
                                          THEN 0
                                          ELSE 1
                                     END) AS FLOAT) / CAST(SUM(1) AS FLOAT) AS fundPercent ,
                            0 AS DateRangeGroup
                   FROM     [dbo].KeyStats_ApprovedOpportunity_HourlySnapshot a
                            LEFT JOIN dbo.KeyStats_FundOpportunity_HourlySnapshot f ON a.[opid] = f.[opid]
                   WHERE    a.ApprovalDate >= DATEADD(year, -1,
                                                      @DateTo_pre2year)
                            AND a.ApprovalDate <= @DateTo_pre2year
							AND (a.consultantid = @OutsideSalesID OR @OutsideSalesID IS NULL)
							AND (a.consultantId = @InsideSalesID OR @InsideSalesID IS NULL)
							AND (a.CreditManagerid = @CreditManagerID OR @CreditManagerID IS NULL)
                 ),
            cte_evaluation
              AS ( SELECT   daterangegroup ,
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
                   FROM     #evaluation
                   GROUP BY daterangegroup
                 ),
            cte_activity
              AS ( SELECT   daterangegroup ,
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
                   FROM     #SpectorDailyAdminDataSnapShot
                   GROUP BY daterangegroup
                 ),
            cte_te
              AS ( SELECT   0 AS DateRangeGroup ,
                            SUM(totalexpense) AS totalexpense
                   FROM     #TinyExpense
                   WHERE    expensedate >= @datefrom_pre2year
                            AND expensedate <= @dateto_pre2year
                   UNION ALL
                   SELECT   1 AS DateRangeGroup ,
                            SUM(totalexpense) AS totalexpense
                   FROM     #TinyExpense
                   WHERE    expensedate >= @datefrom_preyear
                            AND expensedate <= @dateto_preyear
                   UNION ALL
                   SELECT   2 AS DateRangeGroup ,
                            SUM(totalexpense) AS totalexpense
                   FROM     #TinyExpense
                   WHERE    expensedate >= @datefrom
                            AND expensedate <= @dateto
                   UNION ALL
                   SELECT   3 AS DateRangeGroup ,
                            SUM(totalexpense) AS totalexpense
                   FROM     #TinyExpense
                   WHERE    expensedate >= @datefrom_last
                            AND expensedate <= @dateto_last
                 )
        SELECT  drg.name ,
                drg.[id] AS daterangegroup ,
                cte_accepted.EquipmentCost ,
                cte_accepted.totalCount ,
                CAST(ROUND(cte_accepted.annualizedTotalCount, 0) AS INT) AS annualizedTotalCount ,
                ROUND(cte_accepted.portfolioleaseAmt, 0) AS portfolioleaseAmt ,
                cte_accepted.portfolioCount ,
                ROUND(cte_accepted.oneoffleaseAmt, 0) AS oneoffleaseAmt ,
                cte_accepted.oneoffCount ,
                ROUND(cte_accepted.portofolioOrigPercent, 2) AS portofolioOrigPercent ,
                ROUND(cte_accepted.oneOffOrigPercent, 2) AS oneOffOrigPercent ,
                ROUND(cte_accepted.leaseAmt, 0) AS leaseAmt ,
                ROUND(cte_accepted.annualizedLeaseAmt, 0) AS annualizedLeaseAmt ,
                ROUND(cte_accepted.leaseAmtInsideSales, 0) AS leaseAmtInsideSales ,
                ROUND(cte_accepted.leastAmtInsideSalesPercent, 2) AS leastAmtInsideSalesPercent ,
                ROUND(cte_accepted.securityDeposit, 0) AS securityDeposit ,
                ROUND(cte_accepted.securityDepositPercent, 4) AS securityDepositPercent ,
                ROUND(cte_accepted.purchaseOption, 0) AS purchaseOption ,
                ROUND(cte_accepted.purchaseOptionPercent, 4) AS purchaseOptionPercent ,
                ROUND(cte_accepted.initialCashPercent, 4) initialCashPercent ,
                ROUND(cte_accepted.TotalReferralFee, 0) AS TotalReferralFee ,
                ROUND(cte_accepted.totalReferralFeePts, 2) totalReferralFeePts ,
                ROUND(cte_accepted.oneoffProfit, 0) AS oneoffProfit ,
                ROUND(cte_accepted.oneOffProfitPts, 2) oneOffProfitPts ,
                ROUND(cte_accepted.IRR, 4) IRR ,
                cte_accepted.AVGBeaconScore ,
                cte_accepted.AVGFICOScore ,
                CAST(ROUND(cte_accepted.tib, 2) AS DECIMAL(8, 2)) AS tib ,
                ROUND(cte_accepted.paydex, 2) AS paydex ,
                cte_reviewedDeals.UniqueDealsReviewed ,
                cte_submittedTerms.TermsSubmitted ,
                CASE WHEN cte_reviewedDeals.UniqueDealsReviewed > 0
                     THEN ROUND(CAST (cte_submittedTerms.TermsSubmitted AS FLOAT)
                                / CAST(cte_reviewedDeals.UniqueDealsReviewed AS FLOAT),
                                2)
                     ELSE NULL
                END AS submissionPerDeal ,
                ROUND(cte_app.appPercent, 4) AS appPercent ,
                ROUND(cte_fund.fundPercent, 4) AS fundPercent ,
                ev.AvgEvaluationRating ,
                ev.EvaluationRatingCount ,
                ev.AvgEvaluationRatingExt AS AvgEvaluationRatingExt ,
                ev.EvaluationRatingCountExt ,
                ev.AvgEvaluationRatingIn AS AvgEvaluationRatingIn ,
                ev.EvaluationRatingCountIn ,
                act.totalActiveHours AS TotalActiveHrs ,
                act.[Non Work Hours] AS TotalNonWorkHrs ,
                act.[WorkHours] ,
                act.startdateminute ,
                act.enddateminute ,
                act.[Daily Start] AS AvgDailyStart ,
                act.[Daily End] AS AvgDailyEnd ,
                act.totalcall AS NoOfTotalCalls ,
                act.avgcalls AS NoOfAvgCallsPerDay ,
                act.totaldurationmin ,
                act.avgCallDuration ,
                act.avgcalldurationmin AS AvgCallDurationMin ,
                act.totalcallin AS NoOfIncomingCalls ,
                act.totalcallout AS NoOfOutgiongCalls ,
                act.totalcallint AS NoOfInternalForwardedCalls ,
                act.keystroke AS TotalNoOfKeystrokes ,
                act.totalemails AS TotalNoOfEmails ,
                te.totalexpense ,
                ol.totalcount AS openLeadsCount ,
                ol.EquipmentCost AS openLeadsEquipmentCost ,
                od.totalcount AS openOppCountAll ,
                od.leaseamount AS openOppleaseamountAll ,
                od2.totalcount AS openOppCountDis ,
                od2.leaseamount AS openOppleaseamountDis ,
                od3.totalcount AS openOppCountInCredit ,
                od3.leaseamount AS openOppleaseamountInCredit ,
                od4.totalcount AS openOppCountCreditApp ,
                od4.leaseamount AS openOppleaseamountCreditApp ,
                od5.totalcount AS openOppCountCreditDec ,
                od5.leaseamount AS openOppleaseamountCreditDec ,
                od6.totalcount AS openOppCountDocs ,
                od6.leaseamount AS openOppleaseamountDocs
        INTO    #final
        FROM    #DateRangeGroup drg
                LEFT JOIN cte_accepted ON cte_accepted.DateRangeGroup = drg.id
                LEFT JOIN cte_reviewedDeals ON cte_reviewedDeals.DateRangeGroup = drg.id
                LEFT JOIN cte_submittedTerms ON cte_submittedTerms.DateRangeGroup = drg.id
                LEFT JOIN cte_app ON cte_app.DateRangeGroup = drg.id
                LEFT JOIN cte_fund ON cte_fund.DateRangeGroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                          ) od ON od.daterangegroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                            WHERE   salesstagecode = 2
                          ) od2 ON od2.daterangegroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                            WHERE   salesstagecode = 3
                          ) od3 ON od3.daterangegroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                            WHERE   salesstagecode = 4
                          ) od4 ON od4.daterangegroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                            WHERE   salesstagecode = 5
                          ) od5 ON od5.daterangegroup = drg.id
                LEFT JOIN ( SELECT  totalcount ,
                                    leaseamount ,
                                    daterangegroup
                            FROM    #OpenDeals
                            WHERE   salesstagecode = 6
                          ) od6 ON od6.daterangegroup = drg.id
                LEFT JOIN cte_evaluation ev ON ev.DateRangeGroup = drg.id
                LEFT JOIN cte_activity act ON act.DateRangeGroup = drg.id
                LEFT JOIN cte_te te ON te.DateRangeGroup = drg.id
                LEFT JOIN #OpenLeads ol ON ol.DateRangeGroup = drg.id
	
	----######## Select the final result ##--------	
    SELECT  name AS ConsultantName ,
            daterangegroup AS [index] ,
            totalCount AS DealsVal ,
            EquipmentCost AS EquipmentCostVal ,
            annualizedTotalCount AS AnnualizedDealsVal ,
            portfolioleaseAmt AS PortofolioOrigVal ,
            portfolioCount ,
            oneoffleaseAmt AS OneOffOrigVal ,
            oneoffCount ,
            portofolioOrigPercent AS PortOrigPercentVal ,
            oneOffOrigPercent AS OneOffOrigPercentVal ,
            leaseAmt AS TotalOrigVal ,
            annualizedLeaseAmt AS AnnualizedTotalOrigVal ,
            leaseAmtInsideSales AS TotalOrigInsideVal ,
            leastAmtInsideSalesPercent AS TotalOrigInsidePercentVal ,
            securityDeposit AS SecDepMVal ,
            securityDepositPercent AS SecDepPVal ,
            purchaseOption AS PurchOptVal ,
            purchaseOptionPercent AS PurchOptAvgVal ,
            initialCashPercent AS InitialCashPercentVal ,
            TotalReferralFee AS RefFeeVal ,
            totalReferralFeePts AS RefFeePtsVal ,
            oneoffProfit AS OneOffProfitVal ,
            oneOffProfitPts AS OneOffPtsVal ,
            IRR AS IRRVal ,
            AVGBeaconScore AS BeaconScoreVal ,
            AVGFICOScore AS FICOScoreVal ,
            tib AS TIBVal ,
            paydex AS PaydexScoreVal ,
            UniqueDealsReviewed AS UniqueDealsReviewedVal ,
            TermsSubmitted AS SubmissionsVal ,
            submissionPerDeal AS SubmissionsPerDealVal ,
            appPercent AS ApprovalPVal ,
            fundPercent AS ClosedPVal ,
            openLeadsCount AS LeadsNumVal ,
            openLeadsEquipmentCost AS LeadsVal ,
            openOppCountAll AS OpptyTotalNumVal ,
            openOppleaseamountAll AS OpptyTotalVal ,
            openOppCountDis AS OpptyDiscoveryNumVal ,
            openOppleaseamountDis AS OpptyDiscoveryVal ,
            openOppCountInCredit AS OpptyInCreditNumVal ,
            openOppleaseamountInCredit AS OpptyInCreditVal ,
            openOppCountCreditApp AS OpptyCreditApprovalNumVal ,
            openOppleaseamountCreditApp AS OpptyCreditApprovalVal ,
            openOppCountCreditDec AS OpptyCreditDeclinedNumVal ,
            openOppleaseamountCreditDec AS OpptyCreditDeclinedVal ,
            openOppCountDocs AS OpptyDocumentsNumVal ,
            openOppleaseamountDocs AS OpptyDocumentsVal ,
            AvgEvaluationRating AS EvaluationRatingsAvgVal ,
            EvaluationRatingCount AS EvaluationRatingsCountVal ,
            AvgEvaluationRatingExt AS EvaluationRatingsExternalAvgVal ,
            EvaluationRatingCountExt AS EvaluationRatingsExternalCountVal ,
            AvgEvaluationRatingIn AS EvaluationRatingsInternalAvgVal ,
            EvaluationRatingCountIn AS EvaluationRatingsInternalCountVal ,
            CAST(TotalActiveHrs AS DECIMAL(18,2)) AS TotalActiveHoursVal ,
            CAST(TotalNonWorkHrs AS DECIMAL(18,2)) AS TotalNonWorkHoursVal ,
            [WorkHours] ,
            startdateminute ,
            enddateminute ,
            AvgDailyStart AS AvgDailyStart ,
            AvgDailyEnd AS AvgDailyEnd ,
            NoOfTotalCalls AS TotalCallsVal ,
            NoOfAvgCallsPerDay AS AvgCallsPerDayVal ,
            totaldurationmin ,
            avgCallDuration ,
            AvgCallDurationMin AS AvgCallDurationVal ,
            NoOfIncomingCalls AS IncomingCallsVal ,
            NoOfOutgiongCalls AS OutgoingCallsVal ,
            NoOfInternalForwardedCalls AS InternalCallsVal ,
            TotalNoOfKeystrokes AS TotalKeystrokesVal ,
            TotalNoOfEmails AS TotalEmailsVal ,
            totalexpense AS TEExpenseVal
    FROM    #final
    UNION ALL
    SELECT  'Difference<br/>' AS ConsultantName ,
            4 AS [index] ,
            f3.totalCount - f4.totalCount ,
            f3.EquipmentCost - f4.EquipmentCost AS EquipmentCostVal ,
            f3.annualizedTotalCount - f4.annualizedTotalCount ,
            f3.portfolioleaseAmt - f4.portfolioleaseAmt ,
            f3.portfolioCount - f4.portfolioCount ,
            f3.oneoffleaseAmt - f4.oneoffleaseAmt ,
            f3.oneoffCount - f4.oneoffCount ,
            f3.portofolioOrigPercent - f4.portofolioOrigPercent ,
            f3.oneOffOrigPercent - f4.oneOffOrigPercent ,
            f3.leaseAmt - f4.leaseAmt ,
            f3.annualizedLeaseAmt - f4.annualizedLeaseAmt ,
            f3.leaseAmtInsideSales - f4.leaseAmtInsideSales ,
            f3.leastAmtInsideSalesPercent - f4.leastAmtInsideSalesPercent ,
            f3.securityDeposit - f4.securityDeposit ,
            f3.securityDepositPercent - f4.securityDepositPercent ,
            f3.purchaseOption - f4.purchaseOption ,
            f3.purchaseOptionPercent - f4.purchaseOptionPercent ,
            f3.initialCashPercent - f4.initialCashPercent ,
            f3.TotalReferralFee - f4.TotalReferralFee ,
            f3.totalReferralFeePts - f4.totalReferralFeePts ,
            f3.oneoffProfit - f4.oneoffProfit ,
            f3.oneOffProfitPts - f4.oneOffProfitPts ,
            f3.IRR - f4.IRR ,
            f3.AVGBeaconScore - f4.AVGBeaconScore ,
            f3.AVGFICOScore - f4.AVGFICOScore ,
            f3.tib - f4.tib ,
            f3.paydex - f4.paydex ,
            f3.UniqueDealsReviewed - f4.UniqueDealsReviewed ,
            f3.TermsSubmitted - f4.TermsSubmitted ,
            f3.submissionPerDeal - f4.submissionPerDeal ,
            f3.appPercent - f4.appPercent ,
            f3.fundPercent - f4.fundPercent ,
            f3.openLeadsCount - f4.openLeadsCount ,
            f3.openLeadsEquipmentCost - f4.openLeadsEquipmentCost ,
            f3.openOppCountAll - f4.openOppCountAll AS OpptyTotalNumVal ,
            f3.openOppleaseamountAll - f4.openOppleaseamountAll AS OpptyTotalVal ,
            f3.openOppCountDis - f4.openOppCountDis AS OpptyDiscoveryNumVal ,
            f3.openOppleaseamountDis - f4.openOppleaseamountDis AS OpptyDiscoveryVal ,
            f3.openOppCountInCredit - f4.openOppCountInCredit AS OpptyInCreditNumVal ,
            f3.openOppleaseamountInCredit - f4.openOppleaseamountInCredit AS OpptyInCreditVal ,
            f3.openOppCountCreditApp - f4.openOppCountCreditApp AS OpptyCreditApprovalNumVal ,
            f3.openOppleaseamountCreditApp - f4.openOppleaseamountCreditApp AS OpptyCreditApprovalVal ,
            f3.openOppCountCreditDec - f4.openOppCountCreditDec AS OpptyCreditDeclinedNumVal ,
            f3.openOppleaseamountCreditDec - f4.openOppleaseamountCreditDec AS OpptyCreditDeclinedVal ,
            f3.openOppCountDocs - f4.openOppCountDocs AS OpptyDocumentsNumVal ,
            f3.openOppleaseamountDocs - f4.openOppleaseamountDocs AS OpptyDocumentsVal ,
            f3.AvgEvaluationRating - f4.AvgEvaluationRating ,
            f3.EvaluationRatingCount - f4.EvaluationRatingCount ,
            f3.AvgEvaluationRatingExt - f4.AvgEvaluationRatingExt ,
            f3.EvaluationRatingCountExt - f4.EvaluationRatingCountExt ,
            f3.AvgEvaluationRatingIn - f4.AvgEvaluationRatingIn ,
            f3.EvaluationRatingCountIn - f4.EvaluationRatingCountIn ,
            f3.TotalActiveHrs - f4.TotalActiveHrs ,
            f3.TotalNonWorkHrs - f4.TotalNonWorkHrs ,
            f3.[WorkHours] - f4.[WorkHours] ,
            f3.startdateminute - f4.startdateminute ,
            f3.enddateminute - f4.enddateminute ,
            CAST(f3.startdateminute - f4.startdateminute AS VARCHAR(10))
            + ' min' ,
            CAST(f3.enddateminute - f4.enddateminute AS VARCHAR(10)) + ' min' ,
            f3.NoOfTotalCalls - f4.NoOfTotalCalls ,
            f3.NoOfAvgCallsPerDay - f4.NoOfAvgCallsPerDay ,
            f3.totaldurationmin - f4.totaldurationmin ,
            f3.avgCallDuration - f4.avgCallDuration ,
            f3.AvgCallDurationMin - f4.AvgCallDurationMin ,
            f3.NoOfIncomingCalls - f4.NoOfIncomingCalls ,
            f3.NoOfOutgiongCalls - f4.NoOfOutgiongCalls ,
            f3.NoOfInternalForwardedCalls - f4.NoOfInternalForwardedCalls ,
            f3.TotalNoOfKeystrokes - f4.TotalNoOfKeystrokes ,
            f3.TotalNoOfEmails - f4.TotalNoOfEmails ,
            f3.totalexpense - f4.totalexpense
    FROM    #final f3
            INNER JOIN #final f4 ON f3.daterangegroup = 2
                                    AND f4.daterangegroup = 3
		
		
-- KeyStats_Sales_LoadCompanySales '1/01/2015','12/22/2015'
GO
