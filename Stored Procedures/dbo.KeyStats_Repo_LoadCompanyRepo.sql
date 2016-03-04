SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tony Mykhaylovsky
-- Create DATETIME: 12/16/2015
-- Description:	Company Repo
-- =============================================
--[dbo].[KeyStats_Repo_LoadCompanyRepo] N'5/20/2015',N'12/20/2015'
CREATE PROCEDURE [dbo].[KeyStats_Repo_LoadCompanyRepo] --N'5/20/2015',N'12/20/2015'
	@BeginDate AS DATETIME
	,@EndDate AS DATETIME
	,@RepoTypeID AS INT = NULL
	,@SalesPersonGUID AS VARCHAR(36) = NULL
	,@CollectorGUID AS VARCHAR(36) = NULL
	,@CreditManagerGUID AS VARCHAR(36) = NULL
	,@AmericanStateCode AS VARCHAR(2) = NULL
	,@EquipmentTypeValue AS VARCHAR(36) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TwoYearsBeforeFrom AS DATETIME;
    SET @TwoYearsBeforeFrom = CAST(CAST(YEAR(@BeginDate) - 2 AS VARCHAR(20))
        + '/01/01' AS DATETIME);
    DECLARE @TwoYearsBeforeTo AS DATETIME;
    SET @TwoYearsBeforeTo = CAST(CAST(YEAR(@BeginDate) - 2 AS VARCHAR(20))
        + '/12/31' AS DATETIME);

    DECLARE @LastYearFrom AS DATETIME;
    SET @LastYearFrom = CAST(CAST(YEAR(@BeginDate) - 1 AS VARCHAR(20))
        + '/01/01' AS DATETIME);
    DECLARE @LastYearTo AS DATETIME;
    SET @LastYearTo = CAST(CAST(YEAR(@BeginDate) - 1 AS VARCHAR(20))
        + '/12/31' AS DATETIME);

    DECLARE @LastYearSamePeriodFrom AS DATETIME;
    SET @LastYearSamePeriodFrom = CAST(( YEAR(@BeginDate) - 1 ) AS VARCHAR(20))
        + '/' + CAST(MONTH(@BeginDate) AS VARCHAR(20)) + '/'
        + CAST(DAY(@BeginDate) AS VARCHAR(20));
    DECLARE @LastYearSamePeriodTo AS DATETIME;
    SET @LastYearSamePeriodTo = CAST(( YEAR(@EndDate) - 1 ) AS VARCHAR(20))
        + '/' + CAST(MONTH(@EndDate) AS VARCHAR(20)) + '/'
        + CAST(DAY(@EndDate) AS VARCHAR(20));

	DECLARE @BeginDateLabel date = @BeginDate;
	DECLARE @EndDateLabel date = @EndDate;
	DECLARE @LastYearSamePeriodFromLabel date = @LastYearSamePeriodFrom;
	DECLARE @LastYearSamePeriodToLabel date = @LastYearSamePeriodTo;

	SET @BeginDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@BeginDate))
	SET @EndDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@EndDate))

	SET @TwoYearsBeforeFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@TwoYearsBeforeFrom))
	SET @TwoYearsBeforeTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@TwoYearsBeforeTo))

	SET @LastYearFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@LastYearFrom))
	SET @LastYearTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@LastYearTo))

	SET @LastYearSamePeriodFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@LastYearSamePeriodFrom))
	SET @LastYearSamePeriodTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), CONVERT(DATETIME,@LastYearSamePeriodTo))

	IF OBJECT_ID('tempdb..#CompanyStats') IS NOT NULL
      DROP TABLE #CompanyStats
	CREATE TABLE #CompanyStats
    (
		-- GENERAL (7)(4)
		G_CSSINDEX INT ,
		G_CurrentIndex INT ,
        G_HeaderName VARCHAR(50) ,
		G_HeaderToolTip VARCHAR(100) ,
		G_HeaderLink VARCHAR(MAX) ,
		G_StartDATETIME VARCHAR(50) ,
		G_TableClass VARCHAR(20) ,
              
		G_UniqueUserId INT ,
        G_Username VARCHAR(20) ,
        G_FromDATETIME DATETIME ,
        G_ToDATETIME DATETIME ,

		-- COMPLETED REPOS (4)
        CR_NumberOfRepos INT ,
		CR_NumberOfProfitOpportunities INT ,
        CR_NumberOfEndOfLeaseReturns INT ,
		CR_NumberOfTotal INT ,

		-- REPO TIMELINE (days) (3)
		RT_AverageStartToRecovery DECIMAL(10,2) ,
        RT_AverageRecoveryToComplete DECIMAL(10,2) ,
        RT_AverageTotal DECIMAL(10,2) ,

		-- GAIN LOSS (10)
        GL_BVCost INT ,
        GL_TotalExpenses INT ,
        GL_MiscCreditsDebits INT ,
        GL_TotalSalesCommission INT ,
        GL_Breakeven INT ,
        GL_ActualProceedsFromSales INT ,
		GL_SettlementsReceived INT ,
		GL_GainLoss INT ,
		GL_ProfitOpportunityCommission INT ,
		GL_GainLossNet INT ,

        -- EXPENSE TYPE (11)
        ET_Labor INT ,
        ET_Parts INT ,
		ET_Legal INT ,
		ET_Commission INT ,
		ET_Crating INT ,
		ET_ReferralFee INT ,
		ET_Shipping INT ,
		ET_Storage INT ,
		ET_Travel INT ,
		ET_Other INT ,
		ET_Total INT ,

        -- CREDIT QUALITY (3)
        CQ_AverageCBRWhenFinanced INT ,
		CQ_AverageCBRAtRepossesion INT ,
		CQ_AverageCBRChange INT ,

        -- ORIGINAL TERMS (3)
        OT_AverageAmountFinanced INT ,
		OT_AverageTerm DECIMAL(10,2) ,
		OT_AverageIRR DECIMAL(10,2) ,

        -- COLLECTIONS (3)
        C_AverageNumberOfPaymentsRemaining DECIMAL(10, 1) ,
        C_AverageNumberOfDaysUponRepo DECIMAL(10, 1) ,
		C_AverageNumberOfCollectorComments DECIMAL(10, 1) ,

		-- OPEN REPO ASSET PIPELINE (6)
        ORAP_PendingEndingInventory INT ,
		ORAP_AvailableEndingInventory INT ,
		ORAP_ContractPendingEndingInventory INT ,
		ORAP_TotalEndingInventory INT ,
		ORAP_ListEstimatedValue INT ,
		ORAP_EstimatedGainLoss INT
	);

	DECLARE @counter AS INT = 1;
	DECLARE @fromDate AS DATETIME = NULL;
    DECLARE @toDate AS DATETIME = NULL;
    DECLARE @header AS VARCHAR(MAX) = NULL;

	--FIRST FOUR COLUMNS
	WHILE @counter < 5
	BEGIN
		SET @fromDate = CASE @counter
			WHEN 1 THEN @TwoYearsBeforeFrom
			WHEN 2 THEN @LastYearFrom
			WHEN 3 THEN @beginDate
			WHEN 4 THEN @LastYearSamePeriodFrom
			ELSE NULL
			END;
		SET @toDate = CASE @counter
            WHEN 1 THEN @TwoYearsBeforeTo
            WHEN 2 THEN @LastYearTo
            WHEN 3 THEN @endDate
            WHEN 4 THEN @LastYearSamePeriodTo
            ELSE NULL
            END;  
        SET @header = CASE @counter
			WHEN 1
			THEN 'Repo Total '
					+ CAST(YEAR(@TwoYearsBeforeTo) AS VARCHAR(4))
			WHEN 2
			THEN 'Repo Total '
					+ CAST(YEAR(@LastYearTo) AS VARCHAR(MAX))
			WHEN 3
			THEN 'Repo Total<br/>'
					+ CONVERT(VARCHAR(10), @beginDateLabel, 1)
					+ ' - ' + CONVERT(VARCHAR(10), @endDateLabel, 1)
			WHEN 4
			THEN 'Repo Total<br/>'
					+ CONVERT(VARCHAR(10), @LastYearSamePeriodFromLabel, 1)
					+ ' - '
					+ CONVERT(VARCHAR(10), @LastYearSamePeriodToLabel, 1)
			ELSE NULL
			END;

		IF OBJECT_ID('tempdb..#ClosedRepos') IS NOT NULL
        DROP TABLE #ClosedRepos 
		SELECT cr.* INTO #ClosedRepos 
		FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
		WHERE cr.closedon >= @fromDate and cr.closedon<=@toDate
		AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue]) 
		AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
		AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
		AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
		AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
		AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)

		IF OBJECT_ID('tempdb..#ReposExpenses') IS NOT NULL
		DROP TABLE #ReposExpenses
		SELECT re.* INTO #ReposExpenses 
		FROM [dbo].[KeyStats_Repo_AllReposExpense_DailySnapShot] re
		WHERE re.closedon >= @fromDate and re.closedon<=@toDate
		AND re.RepoTypeValue = ISNULL(@repoTypeID,re.RepoTypeValue) 
		AND re.SalesPersonGUID like ISNULL(@SalesPersonGUID,re.SalesPersonGUID)
		AND re.CollectorGUID = ISNULL(@CollectorGUID,re.CollectorGUID)
		AND re.CreditManagerGUID like ISNULL(@CreditManagerGUID,re.CreditManagerGUID)
		AND re.[CustomerState] = ISNULL(@americanStateCode,re.[CustomerState])
		AND re.EquipTypes like ISNULL(@equipmentTypeValue,re.EquipTypes)

		IF OBJECT_ID('tempdb..#OpenRepoAssetPipeline') IS NOT NULL --IF SP is too slow, you can optimize this tempdb more.
		DROP TABLE #OpenRepoAssetPipeline
		select * 
		into #OpenRepoAssetPipeline
		from KeyStats_Repo_OpenRepoAssetPipeline_DailySnapshot orap
		where 
		--CAST(orap.SnapshotDATE as date) = @toDate AND 
		orap.RepoTypeValue = ISNULL(@repoTypeID,orap.RepoTypeValue) 
		AND orap.SalesPersonGUID like ISNULL(@SalesPersonGUID,orap.SalesPersonGUID)
		AND orap.CollectorGUID = ISNULL(@CollectorGUID,orap.CollectorGUID)
		AND orap.CreditManagerGUID like ISNULL(@CreditManagerGUID,orap.CreditManagerGUID)
		AND orap.[State] = ISNULL(@americanStateCode,orap.[State])
		AND orap.EquipmentCategory like ISNULL(@equipmentTypeValue,orap.EquipmentCategory)

		--COMPLETED REPOS
		declare @CR_NumberOfRepos int =
		(
			select count(cr.Type) 
			from #ClosedRepos cr
			WHERE cr.Type = 'Repo'
		);
		declare @CR_NumberOfProfitOpportunities int = 
		(
			select count(cr.Type) 
			from #ClosedRepos cr
			WHERE cr.Type = 'Profit Opp'
		);
		declare @CR_NumberOfEndOfLeaseReturns int =
		(
			select count(cr.Type) 
			from #ClosedRepos cr
			WHERE cr.Type = 'End Of Lease Return'
		);
		declare @CR_NumberOfTotal int = 
		(
			@CR_NumberOfRepos + @CR_NumberOfProfitOpportunities + @CR_NumberOfEndOfLeaseReturns
		);

		--REPO TIMELINE (days)
		declare @RT_AverageStartToRecovery decimal =
		(
			select avg(DATEdiff(day,cr.new_repostartDATE,cr.ActualPickupDATE))
			from #ClosedRepos cr
		);
		declare @RT_AverageRecoveryToComplete decimal =
		(
			select avg(DATEdiff(day, cr.ActualPickupDATE, cr.closedon))
			from #ClosedRepos cr
		);
		declare @RT_AverageTotal decimal =
		(
			@RT_AverageStartToRecovery + @RT_AverageRecoveryToComplete
		);

		--EXPENSE TYPE
		declare @ET_Labor decimal = isnull(
		(	
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Labor'
		),0);
		declare @ET_Parts decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Parts'
		),0);
		declare @ET_Legal decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Legal'
		),0);
		declare @ET_Commission decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Commission'
		),0);
		declare @ET_Crating decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Crating'
		),0);
		declare @ET_ReferralFee decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Referral Fee'
		),0);
		declare @ET_Shipping decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Shipping'
		),0);
		declare @ET_Storage decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Storage'
		),0);
		declare @ET_Travel decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Travel'
		),0);
		declare @ET_Other decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpenses re
			where re.[Type] = 'Other'
		),0)
		declare @ET_Total decimal=
		(
			@ET_Labor + @ET_Parts + @ET_Legal + @ET_Commission + @ET_Crating + @ET_ReferralFee + @ET_Shipping + @ET_Storage + @ET_Travel + @ET_Other
		);

		--CREDIT QUALITY
		declare @CQ_AverageCBRWhenFinanced int =
		(
			select avg(cr.[RepoBeaconScore])
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @CQ_AverageCBRAtRepossesion int =
		(
			select avg(cr.[OriginalBeaconScore])
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @CQ_AverageCBRChange int =
		(
			@CQ_AverageCBRWhenFinanced-@CQ_AverageCBRAtRepossesion
		);

		--ORIGINAL TERMS
		declare @OT_AverageAmountFinanced  int =
		(
			select sum(cr.AmountFinanced)/nullif(@CR_NumberOfRepos, 0)
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @OT_AverageTerm  decimal =
		(
			select sum(cr.[TotalTerm])/nullif(@CR_NumberOfRepos, 0)
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @OT_AverageIRR  decimal =
		(
			select (sum(cr.IRR*cr.AmountFinanced)/nullif(sum(cr.AmountFinanced),0))*100 --weighted by amount financed
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);

		--COLLECTIONS
		declare @C_AverageNumberOfPaymentsRemaining decimal =
		( 
			select sum(cr.PaymentRemaining)/nullif(@CR_NumberOfRepos, 0)
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @C_AverageNumberOfDaysUponRepo decimal =
		(
			select sum(cr.[DaysPastDueatRepo])/nullif(@CR_NumberOfRepos, 0)
			from #ClosedRepos cr
			where cr.[Type] = 'Repo'
		);
		declare @C_AverageNumberOfCollectorComments decimal =
		(
			select sum(cr.numOfCollectorComments)/nullif(@CR_NumberOfRepos, 0)
			from #ClosedRepos cr
			where cr.[Type] = 'Repo' 
		);

		--OPEN REPO ASSET PIPELINE
		declare @ORAP_PendingEndingInventory int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipeline orap
			where orap.[EUAdminStatus] = 'Available'
		);
		declare @ORAP_AvailableEndingInventory  int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipeline orap
			where orap.[EUAdminStatus] = 'Pending'
		);
		declare @ORAP_ContractPendingEndingInventory int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipeline orap
			where orap.[EUAdminStatus] = 'Contract Pending'
		);
		declare @ORAP_TotalEndingInventory int = 
		(
			@ORAP_PendingEndingInventory + @ORAP_AvailableEndingInventory + @ORAP_ContractPendingEndingInventory
		);
		declare @ORAP_ListEstimatedValue int = 
		(
			select sum
			(
				isnull(orap.[ListEstimatedTotalValue],0)
			)
			from #OpenRepoAssetPipeline orap
		);
		declare @ORAP_EstimatedGainLoss int = 
		(
			select sum
			(
				isnull(orap.EstNetGainLoss,0)
			)
			from #OpenRepoAssetPipeline orap
		);

		INSERT INTO #CompanyStats
			(
				-- GENERAL
				G_CSSINDEX ,
				G_CurrentIndex ,
				G_HeaderName ,
				G_HeaderToolTip ,
				G_HeaderLink ,
				G_StartDATETIME ,
				G_TableClass ,
              
				G_UniqueUserId ,
				G_Username ,
				G_FromDATETIME ,
				G_ToDATETIME ,

				-- COMPLETED REPOS
				CR_NumberOfRepos ,
				CR_NumberOfProfitOpportunities ,
				CR_NumberOfEndOfLeaseReturns ,
				CR_NumberOfTotal ,

				-- REPO TIMELINE (days)
				RT_AverageStartToRecovery ,
				RT_AverageRecoveryToComplete ,
				RT_AverageTotal ,

				-- GAIN LOSS
				GL_BVCost ,
				GL_TotalExpenses ,
				GL_MiscCreditsDebits ,
				GL_TotalSalesCommission ,
				GL_Breakeven ,
				GL_ActualProceedsFromSales ,
				GL_SettlementsReceived ,
				GL_GainLoss ,
				GL_ProfitOpportunityCommission ,
				GL_GainLossNet ,

				-- EXPENSE TYPE
				ET_Labor ,
				ET_Parts ,
				ET_Legal ,
				ET_Commission ,
				ET_Crating ,
				ET_ReferralFee ,
				ET_Shipping ,
				ET_Storage ,
				ET_Travel ,
				ET_Other ,
				ET_Total ,

				-- CREDIT QUALITY
				CQ_AverageCBRWhenFinanced ,
				CQ_AverageCBRAtRepossesion ,
				CQ_AverageCBRChange ,

				-- ORIGINAL TERMS
				OT_AverageAmountFinanced ,
				OT_AverageTerm ,
				OT_AverageIRR ,

				-- COLLECTIONS
				C_AverageNumberOfPaymentsRemaining ,
				C_AverageNumberOfDaysUponRepo ,
				C_AverageNumberOfCollectorComments ,

				-- OPEN REPO ASSET PIPELINE
				ORAP_PendingEndingInventory ,
				ORAP_AvailableEndingInventory ,
				ORAP_ContractPendingEndingInventory ,
				ORAP_TotalEndingInventory ,
				ORAP_ListEstimatedValue ,
				ORAP_EstimatedGainLoss
			)

			SELECT top 1
			0,@counter-1,@header,0,0,0,0,0,0,
			@fromDate,@toDate,
			--COMPLETED REPOS
			@CR_NumberOfRepos AS CR_NumberOfRepos,
			@CR_NumberOfProfitOpportunities AS CR_NumberOfProfitOpportunities,
			@CR_NumberOfEndOfLeaseReturns AS CR_NumberOfEndOfLeaseReturns,
			@CR_NumberOfTotal AS CR_NumberOfTotal,

			--REPO TIMELINE (days)
			@RT_AverageStartToRecovery AS RT_AverageStartToRecovery,
			@RT_AverageRecoveryToComplete AS RT_AverageRecoveryToComplete,
			@RT_AverageTotal AS RT_AverageTotal,

			--GAIN LOSS
			sum(cr.BVCost) AS GL_BVCost,
			sum(cr.totalExpenses) AS GL_TotalExpenses,
			sum(cr.miscexpensescredits) AS GL_MiscCreditsDebits,
			sum(cr.TotalSalesCommission) AS GL_TotalSalesCommission ,
			sum(cr.breakeven) AS GL_Breakeven ,
			sum(cr.proceedsfromsale) AS GL_ActualProceedsFromSales ,
			sum(cr.[settlementreceived]) AS GL_SettlementsReceived ,
			sum(cr.GainLoss) AS GL_GainLoss ,
			sum(cr.profitopportunitycommission) AS GL_ProfitOpportunityCommission ,
			sum(cr.NetGainLoss) AS GL_GainLossNet ,

			--EXPENSE TYPE
			@ET_Labor as ET_Labor,
			@ET_Parts as ET_Parts,
			@ET_Legal as ET_Legal,
			@ET_Commission as ET_Commission,
			@ET_Crating as ET_Crating,
			@ET_ReferralFee as ET_ReferralFee,
			@ET_Shipping as ET_Shipping,
			@ET_Storage as ET_Storage,
			@ET_Travel as ET_Travel,
			@ET_Other as ET_Other,
			@ET_Total as ET_Total,

			--CREDIT QUALITY
			@CQ_AverageCBRWhenFinanced AS CQ_AverageCBRWhenFinanced,
			@CQ_AverageCBRAtRepossesion AS CQ_AverageCBRAtRepossesion,
			@CQ_AverageCBRChange AS CQ_AverageCBRChange,

			--ORIGINAL TERMS
			@OT_AverageAmountFinanced AS OT_AverageAmountFinanced,
			@OT_AverageTerm AS OT_AverageTerm,
			@OT_AverageIRR as OT_AverageIRR,

			--COLLECTIONS
			@C_AverageNumberOfPaymentsRemaining as C_AverageNumberOfPaymentsRemaining,
			@C_AverageNumberOfDaysUponRepo as C_AverageNumberOfDaysUponRepo,
			@C_AverageNumberOfCollectorComments as C_AverageNumberOfCollectorComments,

			--OPEN REPO ASSET PIPELINE
			@ORAP_PendingEndingInventory as ORAP_PendingEndingInventory,
			@ORAP_AvailableEndingInventory as ORAP_AvailableEndingInventory,
			@ORAP_ContractPendingEndingInventory as ORAP_ContractPendingEndingInventory,
			@ORAP_TotalEndingInventory as ORAP_TotalEndingInventory,
			@ORAP_ListEstimatedValue as ORAP_ListEstimatedValue,
			@ORAP_EstimatedGainLoss as ORAP_EstimatedGainLoss

			from #ClosedRepos cr
		SET @counter = @counter + 1;
	END

	SELECT * FROM #CompanyStats 
	UNION ALL
	SELECT 0,
	4,
	'Difference',
	0,
	0,
	0,
	0,
	0,
	0,
	@fromDate,
	@toDate,
	-- COMPLETED REPOS
	m2.CR_NumberOfRepos - m1.CR_NumberOfRepos ,
	m2.CR_NumberOfProfitOpportunities-m1.CR_NumberOfProfitOpportunities ,
	m2.CR_NumberOfEndOfLeaseReturns-m1.CR_NumberOfEndOfLeaseReturns ,
	m2.CR_NumberOfTotal-m1.CR_NumberOfTotal ,

	-- REPO TIMELINE (days)
	m2.RT_AverageStartToRecovery -m1.RT_AverageStartToRecovery,
	m2.RT_AverageRecoveryToComplete-m1.RT_AverageRecoveryToComplete,
	m2.RT_AverageTotal-m1.RT_AverageTotal ,

	-- GAIN LOSS
	m2.GL_BVCost -m1.GL_BVCost,
	m2.GL_TotalExpenses-m1.GL_TotalExpenses ,
	m2.GL_MiscCreditsDebits -m1.GL_MiscCreditsDebits,
	m2.GL_TotalSalesCommission-m1.GL_TotalSalesCommission ,
	m2.GL_Breakeven-m1.GL_Breakeven ,
	m2.GL_ActualProceedsFromSales -m1.GL_ActualProceedsFromSales,
	m2.GL_SettlementsReceived -m1.GL_SettlementsReceived,
	m2.GL_GainLoss -m1.GL_GainLoss,
	m2.GL_ProfitOpportunityCommission -m1.GL_ProfitOpportunityCommission,
	m2.GL_GainLossNet-m1.GL_GainLossNet ,

	-- EXPENSE TYPE
	m2.ET_Labor-m1.ET_Labor,
	m2.ET_Parts -m1.ET_Parts,
	m2.ET_Legal -m1.ET_Legal,
	m2.ET_Commission -m1.ET_Commission,
	m2.ET_Crating -m1.ET_Crating,
	m2.ET_ReferralFee -m1.ET_ReferralFee,
	m2.ET_Shipping -m1.ET_Shipping,
	m2.ET_Storage -m1.ET_Storage,
	m2.ET_Travel -m1.ET_Travel,
	m2.ET_Other-m1.ET_Other ,
	m2.ET_Total -m1.ET_Total,

	-- CREDIT QUALITY
	m2.CQ_AverageCBRWhenFinanced -m1.CQ_AverageCBRWhenFinanced,
	m2.CQ_AverageCBRAtRepossesion-m1.CQ_AverageCBRAtRepossesion ,
	m2.CQ_AverageCBRChange -m1.CQ_AverageCBRChange,

	-- ORIGINAL TERMS
	m2.OT_AverageAmountFinanced-m1.OT_AverageAmountFinanced,
	m2.OT_AverageTerm -m1.OT_AverageTerm,
	m2.OT_AverageIRR -m1.OT_AverageIRR,

	-- COLLECTIONS
	m2.C_AverageNumberOfPaymentsRemaining-m1.C_AverageNumberOfPaymentsRemaining ,
	m2.C_AverageNumberOfDaysUponRepo -m1.C_AverageNumberOfDaysUponRepo,
	m2.C_AverageNumberOfCollectorComments-m1.C_AverageNumberOfCollectorComments ,

	-- OPEN REPO ASSET PIPELINE
	m2.ORAP_PendingEndingInventory -m1.ORAP_PendingEndingInventory,
	m2.ORAP_AvailableEndingInventory -m1.ORAP_AvailableEndingInventory,
	m2.ORAP_ContractPendingEndingInventory -m1.ORAP_ContractPendingEndingInventory,
	m2.ORAP_TotalEndingInventory -m1.ORAP_TotalEndingInventory,
	m2.ORAP_ListEstimatedValue -m1.ORAP_ListEstimatedValue,
	m2.ORAP_EstimatedGainLoss-m1.ORAP_EstimatedGainLoss

	FROM  #CompanyStats m1
	JOIN #CompanyStats m2
	ON m2.G_CurrentIndex=m1.G_CurrentIndex - 1
	WHERE  m2.G_CurrentIndex = 2

	
END
GO
