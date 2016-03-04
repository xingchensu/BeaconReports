SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tony Mykhaylovsky
-- Create date: 12/16/2015
-- Description:	Company Repo
-- =============================================
--[dbo].[KeyStats_Repo_LoadIndividualRepo] @BeginDate=N'5/20/2015',@EndDate=N'12/20/2015', @GroupID = 1 
CREATE PROCEDURE [dbo].[KeyStats_Repo_LoadIndividualRepo] --N'5/20/2015',N'12/20/2015', @GroupID = 1 
	@BeginDate AS DATETIME
	,@EndDate AS DATETIME
	,@GroupID AS INT
	,@DateRangeCode AS CHAR(3) = NULL
	,@RepoTypeID AS INT = NULL
	,@SalesPersonGUID AS VARCHAR(36) = NULL
	,@CollectorGUID AS VARCHAR(36) = NULL
	,@CreditManagerGUID AS VARCHAR(36) = NULL
	,@AmericanStateCode AS VARCHAR(2) = NULL
	,@EquipmentTypeValue AS VARCHAR(36) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	--Convert to UTC
	SET @BeginDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @BeginDate)
	SET @EndDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @EndDate)

	if @DateRangeCode is null 
	begin
		set @DateRangeCode = 'ytd'
	end

	if object_id('tempdb..#TestScores') IS NOT NULL
    drop table #TestScores
	select *
	into #TestScores
	from KeyStats_Employee_TestScore

	--DECLARE @GroupID AS INT = 1
	IF OBJECT_ID('tempdb..#AllIndividuals') IS NOT NULL
    DROP TABLE #AllIndividuals
	SELECT e.fname
	,e.lname
	,e.fname + ' ' + e.lname AS fullname
	,e.[lname] + ', ' + e.[fname] AS [fullname2]
	,username
	,startdate
	,shift
	,userid
	,r.CategoryID
	,Categoryname
	,e.CRMGuid
	,r.IsMiscellaneous
	,e.UniqueUserID
	,ts.[MathTest]
	,ts.[TypingTestWPM]
	,ts.[TypingTestAccuracy]
	,ts.[BeaconScore]
	,ts.[FicoScore]
	INTO #AllIndividuals
	FROM [Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
	INNER JOIN dbo.KeyStats_Category_Employee_Relation r 
	ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
	INNER JOIN dbo.KeyStats_Categories c 
	ON c.CategoryID=r.CategoryID
	left JOIN dbo.KeyStats_Employee_TestScore ts
	ON ts.UniqueUserId = e.UniqueUserID
	WHERE c.CategoryID= @GroupID--@GroupNo@isMisc
	ORDER BY e.[fname]

	IF OBJECT_ID('tempdb..#ActiveIndividuals') IS NOT NULL
    DROP TABLE #ActiveIndividuals
	SELECT 
	1+ROW_NUMBER() OVER (ORDER BY e.lname) As [Counter], 
	e.fname
	,e.lname
	,e.fname + ' ' + e.lname AS fullname
	,e.[lname] + ', ' + e.[fname] AS [fullname2]
	,username
	,startdate
	,shift
	,userid
	,r.CategoryID
	,Categoryname
	,e.CRMGuid as CRMGuid
	,r.IsMiscellaneous
	,e.UniqueUserID
	,ts.[MathTest]
	,ts.[TypingTestWPM]
	,ts.[TypingTestAccuracy]
	,ts.[BeaconScore]
	,ts.[FicoScore]
	INTO #ActiveIndividuals
	FROM [Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
	INNER JOIN dbo.KeyStats_Category_Employee_Relation r 
	ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
	INNER JOIN dbo.KeyStats_Categories c 
	ON c.CategoryID=r.CategoryID
	left JOIN dbo.KeyStats_Employee_TestScore ts
	ON ts.UniqueUserId = e.UniqueUserID
	WHERE r.IsMiscellaneous = 0  AND c.CategoryID= @GroupID--@GroupNo@isMisc
	ORDER BY e.[fname]

	IF OBJECT_ID('tempdb..#InactiveIndividuals') IS NOT NULL
    DROP TABLE #InactiveIndividuals
	SELECT e.fname
	,e.lname
	,e.fname + ' ' + e.lname AS fullname
	,e.[lname] + ', ' + e.[fname] AS [fullname2]
	,username
	,startdate
	,shift
	,userid
	,r.CategoryID
	,Categoryname
	,e.CRMGuid AS CRMGuid
	,r.IsMiscellaneous
	,e.UniqueUserID
	,ts.[MathTest]
	,ts.[TypingTestWPM]
	,ts.[TypingTestAccuracy]
	,ts.[BeaconScore]
	,ts.[FicoScore]
	INTO #InactiveIndividuals
	FROM [Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
	INNER JOIN dbo.KeyStats_Category_Employee_Relation r 
	ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
	INNER JOIN dbo.KeyStats_Categories c 
	ON c.CategoryID=r.CategoryID
	left JOIN dbo.KeyStats_Employee_TestScore ts
	ON ts.UniqueUserId = e.UniqueUserID
	WHERE r.IsMiscellaneous = 1  AND c.CategoryID= @GroupID
	ORDER BY e.[fname]
	
	DECLARE @ActiveIndividualsCount INT = 
	(
		SELECT COUNT(ai.CRMGuid) FROM #ActiveIndividuals ai
	);
	DECLARE @InactiveIndividualsCount INT = 
	(
		SELECT COUNT(ii.CRMGuid) FROM #InactiveIndividuals ii
	);
	DECLARE @TotalIndividuals INT = 
	(
		isnull(@ActiveIndividualsCount,0)+isnull(@InactiveIndividualsCount,0)
	);


	IF OBJECT_ID('tempdb..#ClosedRepos') IS NOT NULL
      DROP TABLE #ClosedRepos
	SELECT cr.*
	INTO #ClosedRepos
	FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
	WHERE cr.closedon >= @BeginDate and cr.closedon<=@EndDate
	AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue])
	--AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
	--AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
	AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
	AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
	AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)

	IF OBJECT_ID('tempdb..#ReposExpenses') IS NOT NULL
    DROP TABLE #ReposExpenses
	SELECT re.* 
	INTO #ReposExpenses 
	FROM [dbo].[KeyStats_Repo_AllReposExpense_DailySnapShot] re
	WHERE re.closedon >= @BeginDate and re.closedon<=@EndDate
	AND re.RepoTypeValue = ISNULL(@repoTypeID,re.RepoTypeValue) 
	--AND re.SalesPersonGUID like ISNULL(@SalesPersonGUID,re.SalesPersonGUID)
	--AND re.CollectorGUID = ISNULL(@CollectorGUID,re.CollectorGUID)
	AND re.CreditManagerGUID like ISNULL(@CreditManagerGUID,re.CreditManagerGUID)
	AND re.[CustomerState] = ISNULL(@americanStateCode,re.[CustomerState])
	AND re.EquipTypes like ISNULL(@equipmentTypeValue,re.EquipTypes)

	IF OBJECT_ID('tempdb..#OpenRepoAssetPipeline') IS NOT NULL --IF SP is too slow, you can optimize this tempdb more.
	DROP TABLE #OpenRepoAssetPipeline
	SELECT * 
	into #OpenRepoAssetPipeline
	from KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot orap
	where 
	--CAST(orap.SnapshotDATE as date) = @EndDate AND 
	orap.RepoTypeValue = ISNULL(@repoTypeID,orap.RepoTypeValue) 
	--AND orap.SalesPersonGUID like ISNULL(@SalesPersonGUID,orap.SalesPersonGUID)
	--AND orap.CollectorGUID = ISNULL(@CollectorGUID,orap.CollectorGUID)
	AND orap.CreditManagerGUID like ISNULL(@CreditManagerGUID,orap.CreditManagerGUID)
	AND orap.[State] = ISNULL(@americanStateCode,orap.[State])
	AND orap.EquipmentCategory like ISNULL(@equipmentTypeValue,orap.EquipmentCategory)

	IF OBJECT_ID('tempdb..#IndividualStats') IS NOT NULL
    DROP TABLE #IndividualStats
	CREATE TABLE #IndividualStats
    (
		-- GENERAL (7)(4)
		G_CSSINDEX INT ,
		G_CurrentIndex INT ,
        G_HeaderName VARCHAR(50) ,
		G_HeaderToolTip VARCHAR(100) ,
		G_HeaderLink VARCHAR(MAX) ,
		G_StartDate VARCHAR(50) ,
		G_TableClass VARCHAR(20) ,
              
		G_UniqueUserId INT ,
        G_Username VARCHAR(20) ,
        G_FromDate DATETIME ,
        G_ToDate DATETIME ,

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
		ORAP_EstimatedGainLoss INT,

		-- ACTIVITY DATA
		AD_AverageDailyStart INT,
		AD_AverageDailyEnd INT,
		AD_TotalHours INT,
		AD_ActiveHours INT,
		AD_ActivePercent INT,
		AD_NumberOfTotalKeystrokes INT,
		AD_NumberOfTotalEmails INT,

		--TEST SCORES
		TS_NumberMatching INT,
		TS_NumberAccuracy INT,
		TS_WordMatching INT,
		TS_MathTest INT,
		TS_MathAccuracy INT,
		TS_TypingSpeed  INT,
		TS_TypingAccuracy INT,
		TS_JobSpecificQuestions INT,
		TS_BeaconScore INT,
		TS_FicoScore INT
	);

	DECLARE @counter AS INT = 0;
	DECLARE @fromDate AS DATE = NULL;
    DECLARE @toDate AS DATE = NULL;
    DECLARE @header AS VARCHAR(MAX) = NULL;

	-------------------------
	---CALCULATE BFC TOTAL---
	-------------------------
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
		isnull(@RT_AverageStartToRecovery,0) + isnull(@RT_AverageRecoveryToComplete,0)
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
		select sum(cr.AmountFinanced)/nullif(@CR_NumberOfRepos,0)
		from #ClosedRepos cr
		where cr.[Type] = 'Repo'
	);
	declare @OT_AverageTerm  decimal =
	(
		select sum(cr.[TotalTerm])/nullif(@CR_NumberOfRepos,0)
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
		select sum(cr.PaymentRemaining)/nullif(@CR_NumberOfRepos,0)
		from #ClosedRepos cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfDaysUponRepo decimal =
	(
		select sum(cr.[DaysPastDueatRepo])/nullif(@CR_NumberOfRepos,0)
		from #ClosedRepos cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfCollectorComments decimal =
	(
		select sum(cr.numOfCollectorComments)/nullif(@CR_NumberOfRepos,0)
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
		where orap.[EUAdminStatus] = 'Contact Pending'
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


	INSERT INTO #IndividualStats
	(
		-- GENERAL
		G_CSSINDEX ,
		G_CurrentIndex ,
		G_HeaderName ,
		G_HeaderToolTip ,
		G_HeaderLink ,
		G_StartDate ,
		G_TableClass ,
              
		G_UniqueUserId ,
		G_Username ,
		G_FromDate ,
		G_ToDate ,

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
		ORAP_EstimatedGainLoss ,

		-- ACTIVITY DATA
		AD_AverageDailyStart ,
		AD_AverageDailyEnd ,
		AD_TotalHours ,
		AD_ActiveHours ,
		AD_ActivePercent ,
		AD_NumberOfTotalKeystrokes ,
		AD_NumberOfTotalEmails ,

		--TEST SCORES
		TS_NumberMatching ,
		TS_NumberAccuracy ,
		TS_WordMatching ,
		TS_MathTest ,
		TS_MathAccuracy ,
		TS_TypingSpeed ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore 
	)
	SELECT top 1
	-5,@counter,'BFC. Total','BFC. Total',2,null,4,5,66,
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
	@ORAP_EstimatedGainLoss as ORAP_EstimatedGainLoss,

	--ACTIVITY DATA
	0,0,0,0,0,0,0,

	--TEST SCORES
	0,0,0,0,0,0,0,0,0,0

	FROM #ClosedRepos cr

	SET @counter = @counter + 1;

	---------------------------
	---CALCULATE BFC AVERAGE---
	---------------------------
	INSERT INTO #IndividualStats
	(
		-- GENERAL
		G_CSSINDEX ,
		G_CurrentIndex ,
		G_HeaderName ,
		G_HeaderToolTip ,
		G_HeaderLink ,
		G_StartDate ,
		G_TableClass ,
              
		G_UniqueUserId ,
		G_Username ,
		G_FromDate ,
		G_ToDate ,

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
		ORAP_EstimatedGainLoss ,

		-- ACTIVITY DATA
		AD_AverageDailyStart ,
		AD_AverageDailyEnd ,
		AD_TotalHours ,
		AD_ActiveHours ,
		AD_ActivePercent ,
		AD_NumberOfTotalKeystrokes ,
		AD_NumberOfTotalEmails ,

		--TEST SCORES
		TS_NumberMatching ,
		TS_NumberAccuracy ,
		TS_WordMatching ,
		TS_MathTest ,
		TS_MathAccuracy ,
		TS_TypingSpeed ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore 
	)
	SELECT
	-5,@counter,'BFC. Avg','BFC. Avg',2,null,4,5,66,
	@fromDate,@toDate,

	--COMPLETED REPOS
	@CR_NumberOfRepos/nullif(@TotalIndividuals,0) AS CR_NumberOfRepos,
	@CR_NumberOfProfitOpportunities/nullif(@TotalIndividuals,0) AS CR_NumberOfProfitOpportunities,
	@CR_NumberOfEndOfLeaseReturns/nullif(@TotalIndividuals,0) AS CR_NumberOfEndOfLeaseReturns,
	@CR_NumberOfTotal/nullif(@TotalIndividuals,0) AS CR_NumberOfTotal,

	--REPO TIMELINE (days)
	@RT_AverageStartToRecovery/nullif(@TotalIndividuals,0) AS RT_AverageStartToRecovery,
	@RT_AverageRecoveryToComplete/nullif(@TotalIndividuals,0) AS RT_AverageRecoveryToComplete,
	@RT_AverageTotal/nullif(@TotalIndividuals,0) AS RT_AverageTotal,

	--GAIN LOSS
	sum(cr.BVCost)/nullif(@TotalIndividuals,0) AS GL_BVCost,
	sum(cr.totalExpenses)/nullif(@TotalIndividuals,0) AS GL_TotalExpenses,
	sum(cr.miscexpensescredits)/nullif(@TotalIndividuals,0) AS GL_MiscCreditsDebits,
	sum(cr.TotalSalesCommission)/nullif(@TotalIndividuals,0) AS GL_TotalSalesCommission ,
	sum(cr.breakeven)/nullif(@TotalIndividuals,0) AS GL_Breakeven ,
	sum(cr.proceedsfromsale)/nullif(@TotalIndividuals,0) AS GL_ActualProceedsFromSales ,
	sum(cr.[settlementreceived])/nullif(@TotalIndividuals,0) AS GL_SettlementsReceived ,
	sum(cr.GainLoss)/nullif(@TotalIndividuals,0) AS GL_GainLoss ,
	sum(cr.profitopportunitycommission)/nullif(@TotalIndividuals,0) AS GL_ProfitOpportunityCommission ,
	sum(cr.NetGainLoss)/nullif(@TotalIndividuals,0) AS GL_GainLossNet ,

	--EXPENSE TYPE
	@ET_Labor/nullif(@TotalIndividuals,0) as ET_Labor,
	@ET_Parts/nullif(@TotalIndividuals,0) as ET_Parts,
	@ET_Legal/nullif(@TotalIndividuals,0) as ET_Legal,
	@ET_Commission/nullif(@TotalIndividuals,0) as ET_Commission,
	@ET_Crating/nullif(@TotalIndividuals,0) as ET_Crating,
	@ET_ReferralFee/nullif(@TotalIndividuals,0) as ET_ReferralFee,
	@ET_Shipping/nullif(@TotalIndividuals,0) as ET_Shipping,
	@ET_Storage/nullif(@TotalIndividuals,0) as ET_Storage,
	@ET_Travel/nullif(@TotalIndividuals,0) as ET_Travel,
	@ET_Other/nullif(@TotalIndividuals,0) as ET_Other,
	@ET_Total/nullif(@TotalIndividuals,0) as ET_Total,

	--CREDIT QUALITY
	@CQ_AverageCBRWhenFinanced/nullif(@TotalIndividuals,0) AS CQ_AverageCBRWhenFinanced,
	@CQ_AverageCBRAtRepossesion/nullif(@TotalIndividuals,0) AS CQ_AverageCBRAtRepossesion,
	@CQ_AverageCBRChange/nullif(@TotalIndividuals,0) AS CQ_AverageCBRChange,

	--ORIGINAL TERMS
	@OT_AverageAmountFinanced/nullif(@TotalIndividuals,0) AS OT_AverageAmountFinanced,
	@OT_AverageTerm/nullif(@TotalIndividuals,0) AS OT_AverageTerm,
	@OT_AverageIRR/nullif(@TotalIndividuals,0) as OT_AverageIRR,

	--COLLECTIONS
	@C_AverageNumberOfPaymentsRemaining/nullif(@TotalIndividuals,0) as C_AverageNumberOfPaymentsRemaining,
	@C_AverageNumberOfDaysUponRepo/nullif(@TotalIndividuals,0) as C_AverageNumberOfDaysUponRepo,
	@C_AverageNumberOfCollectorComments/nullif(@TotalIndividuals,0) as C_AverageNumberOfCollectorComments,

	--OPEN REPO ASSET PIPELINE
	@ORAP_PendingEndingInventory/nullif(@TotalIndividuals,0) as ORAP_PendingEndingInventory,
	@ORAP_AvailableEndingInventory/nullif(@TotalIndividuals,0) as ORAP_AvailableEndingInventory,
	@ORAP_ContractPendingEndingInventory/nullif(@TotalIndividuals,0) as ORAP_ContractPendingEndingInventory,
	@ORAP_TotalEndingInventory/nullif(@TotalIndividuals,0) as ORAP_TotalEndingInventory,
	@ORAP_ListEstimatedValue/nullif(@TotalIndividuals,0) as ORAP_ListEstimatedValue,
	@ORAP_EstimatedGainLoss/nullif(@TotalIndividuals,0) as ORAP_EstimatedGainLoss,

	--ACTIVITY DATA
	0,0,0,0,0,0,0,

	--TEST SCORES
	0,0,0,0,0,0,0,0,0,0

	FROM #ClosedRepos cr

	SET @counter = @counter + 1;

	----------------------------------
	---CALCULATE INDIVIDUAL COLUMNS---
	----------------------------------
	WHILE @counter < (@ActiveIndividualsCount+2) --+2 to account for 
	BEGIN
		DECLARE @startDate as varchar(8);
		DECLARE @_SalesPersonGUID as varchar(72);
		DECLARE @_CollectorGUID as varchar(72);
		DECLARE @headerLink as varchar(150);
		DECLARE @headerToolTip as varchar(100);

		--GET GUID ID from #ActiveIndividuals temp table
		IF @GroupID = 1
		BEGIN
			SET @_SalesPersonGUID = 
			(
				select top 1 ai.CRMGuid
				from #ActiveIndividuals ai
				where ai.Counter = @counter
			);
		END
		ELSE
		BEGIN
			SET @_SalesPersonGUID = null;
		END
		IF @GroupID = 6
		BEGIN
			SET @_CollectorGUID = 
			(
				select top 1 ai.CRMGuid
				from #ActiveIndividuals ai
				where ai.Counter = @counter
			);
		END
		ELSE
		BEGIN
			SET @_CollectorGUID = null;
		END

	
		IF OBJECT_ID('tempdb..#ClosedReposIndividual') IS NOT NULL
		DROP TABLE #ClosedReposIndividual
		SELECT cr.* 
		INTO #ClosedReposIndividual
		FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
		WHERE 
		cr.closedon >= @BeginDate and cr.closedon<=@EndDate 
		AND cr.[TypeValue] = ISNULL(1,cr.[TypeValue]) 
		AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
		AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
		AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
		AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
		AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)
		AND cr.SalesPersonGUID like case when @GroupID = 1 then @_SalesPersonGUID else cr.SalesPersonGUID end
		AND cr.CollectorGUID like case when @GroupID = 6 then @_CollectorGUID else cr.CollectorGUID end

		IF OBJECT_ID('tempdb..#ReposExpensesIndividual') IS NOT NULL
		DROP TABLE #ReposExpensesIndividual
		SELECT re.* 
		INTO #ReposExpensesIndividual
		FROM [dbo].[KeyStats_Repo_AllReposExpense_DailySnapShot] re
		WHERE re.closedon >= @BeginDate and re.closedon<=@EndDate
		AND re.RepoTypeValue = ISNULL(@repoTypeID,re.RepoTypeValue) 
		--AND re.SalesPersonGUID like ISNULL(@SalesPersonGUID,re.SalesPersonGUID)
		--AND re.CollectorGUID = ISNULL(@CollectorGUID,re.CollectorGUID)
		AND re.CreditManagerGUID like ISNULL(@CreditManagerGUID,re.CreditManagerGUID)
		AND re.[CustomerState] = ISNULL(@americanStateCode,re.[CustomerState])
		AND re.EquipTypes like ISNULL(@equipmentTypeValue,re.EquipTypes)
		AND re.SalesPersonGUID like case when @GroupID = 1 then @_SalesPersonGUID else re.SalesPersonGUID end
		AND re.CollectorGUID like case when @GroupID = 6 then @_CollectorGUID else re.CollectorGUID end

		IF OBJECT_ID('tempdb..#OpenRepoAssetPipelineIndividual') IS NOT NULL --IF SP is too slow, you can optimize this tempdb more.
		DROP TABLE #OpenRepoAssetPipelineIndividual
		SELECT * 
		into #OpenRepoAssetPipelineIndividual
		from KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot orap
		where 
		--CAST(orap.SnapshotDATE as date) = @EndDate AND 
		orap.RepoTypeValue = ISNULL(@repoTypeID,orap.RepoTypeValue) 
		--AND orap.SalesPersonGUID like ISNULL(@SalesPersonGUID,orap.SalesPersonGUID)
		--AND orap.CollectorGUID = ISNULL(@CollectorGUID,orap.CollectorGUID)
		AND orap.CreditManagerGUID like ISNULL(@CreditManagerGUID,orap.CreditManagerGUID)
		AND orap.[State] = ISNULL(@americanStateCode,orap.[State])
		AND orap.EquipmentCategory like ISNULL(@equipmentTypeValue,orap.EquipmentCategory)
		AND orap.SalesPersonGUID like case when @GroupID = 1 then @_SalesPersonGUID else orap.SalesPersonGUID end
		AND orap.CollectorGUID like case when @GroupID = 6 then @_CollectorGUID else orap.CollectorGUID end


		SET @fromDate = @beginDate	
		SET @toDate = @endDate 
		
        SET @header =
		(
			select top 1 case when len(ai.lname)>9 then substring(ai.lname, 0, 8) +'..'  else ai.lname end --ai.lname
			from #ActiveIndividuals ai
			where ai.[Counter] = @counter
		);

		SET @headerToolTip =
		(
			select top 1 ai.fullname
			from #ActiveIndividuals ai
			where ai.[Counter] = @counter
		);

		SET @headerLink =
		(
			case when @GroupID = 1 
			then '~/EmployeeMetrics/RepoBuilderStats.aspx?v=IRDD&d='+@DateRangeCode+'&u='+ convert(varchar(36),@_SalesPersonGUID) +'&f=IR' 
			else '~/EmployeeMetrics/RepoBuilderStats.aspx?v=IRDD&d='+@DateRangeCode+'&u='+ convert(varchar(36),@_CollectorGUID) +'&f=IRC'  end
		);

		SET @startDate =
		(
			select top 1 convert(varchar(8),ai.[startdate],1 )
			from #ActiveIndividuals ai
			where ai.[Counter] = @counter
		);

		--#ActiveIndividuals


		declare @CR_NumberOfReposIndividual int =
		(
			select count(cr.Type) 
			from #ClosedReposIndividual cr
			WHERE cr.Type = 'Repo'
		);
		declare @CR_NumberOfProfitOpportunitiesIndividual int = 
		(
			select count(cr.Type) 
			from #ClosedReposIndividual cr
			WHERE cr.Type = 'Profit Opp'
		);
		declare @CR_NumberOfEndOfLeaseReturnsIndividual int =
		(
			select count(cr.Type) 
			from #ClosedReposIndividual cr
			WHERE cr.Type = 'End Of Lease Return'
		);
		declare @CR_NumberOfTotalIndividual int = 
		(
			isnull(@CR_NumberOfReposIndividual,0) + isnull(@CR_NumberOfProfitOpportunitiesIndividual,0) + isnull(@CR_NumberOfEndOfLeaseReturnsIndividual,0)
		);

		--REPO TIMELINE (days)
		declare @RT_AverageStartToRecoveryIndividual decimal =
		(
			select avg(DATEdiff(day,cr.new_repostartDATE,cr.ActualPickupDATE))
			from #ClosedReposIndividual cr
		);
		declare @RT_AverageRecoveryToCompleteIndividual decimal =
		(
			select avg(DATEdiff(day, cr.ActualPickupDATE, cr.closedon))
			from #ClosedReposIndividual cr
		);
		declare @RT_AverageTotalIndividual decimal =
		(
			@RT_AverageStartToRecovery + @RT_AverageRecoveryToComplete
		);

		--EXPENSE TYPE
		declare @ET_LaborIndividual decimal = isnull(
		(	
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Labor'
		),0);
		declare @ET_PartsIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Parts'
		),0);
		declare @ET_LegalIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Legal'
		),0);
		declare @ET_CommissionIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Commission'
		),0);
		declare @ET_CratingIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Crating'
		),0);
		declare @ET_ReferralFeeIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Referral Fee'
		),0);
		declare @ET_ShippingIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Shipping'
		),0);
		declare @ET_StorageIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Storage'
		),0);
		declare @ET_TravelIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Travel'
		),0);
		declare @ET_OtherIndividual decimal= isnull (
		(
			select sum(re.new_expense) 
			from #ReposExpensesIndividual re
			where re.[Type] = 'Other'
		),0)
		declare @ET_TotalIndividual decimal=
		(
			@ET_LaborIndividual + @ET_PartsIndividual + @ET_LegalIndividual + @ET_CommissionIndividual + @ET_CratingIndividual
			 + @ET_ReferralFeeIndividual + @ET_ShippingIndividual + @ET_StorageIndividual + @ET_TravelIndividual + @ET_OtherIndividual
		);

		--CREDIT QUALITY
		declare @CQ_AverageCBRWhenFinancedIndividual int =
		(
			select avg(cr.[RepoBeaconScore])
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @CQ_AverageCBRAtRepossesionIndividual int =
		(
			select avg(cr.[OriginalBeaconScore])
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @CQ_AverageCBRChangeIndividual int =
		(
			@CQ_AverageCBRWhenFinanced-@CQ_AverageCBRAtRepossesion
		);

		--ORIGINAL TERMS
		declare @OT_AverageAmountFinancedIndividual  int =
		(
			select sum(cr.AmountFinanced)/nullif(@CR_NumberOfRepos,0)
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @OT_AverageTermIndividual  decimal =
		(
			select sum(cr.[TotalTerm])/nullif(@CR_NumberOfRepos,0)
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @OT_AverageIRRIndividual  decimal =
		(
			select (sum(cr.IRR*cr.AmountFinanced)/nullif(sum(cr.AmountFinanced),0))*100 --weighted by amount financed
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);

		--COLLECTIONS
		declare @C_AverageNumberOfPaymentsRemainingIndividual decimal =
		( 
			select sum(cr.PaymentRemaining)/nullif(@CR_NumberOfRepos,0)
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @C_AverageNumberOfDaysUponRepoIndividual decimal =
		(
			select sum(cr.[DaysPastDueatRepo])/nullif(@CR_NumberOfRepos,0)
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo'
		);
		declare @C_AverageNumberOfCollectorCommentsIndividual decimal =
		(
			select sum(cr.numOfCollectorComments)/nullif(@CR_NumberOfRepos,0)
			from #ClosedReposIndividual cr
			where cr.[Type] = 'Repo' 
		);

		--OPEN REPO ASSET PIPELINE
		declare @ORAP_PendingEndingInventoryIndividual int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipelineIndividual orap
			where orap.[EUAdminStatus] = 'Available'
		);
		declare @ORAP_AvailableEndingInventoryIndividual  int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipelineIndividual orap
			where orap.[EUAdminStatus] = 'Pending'
		);
		declare @ORAP_ContractPendingEndingInventoryIndividual int = 
		(
			select sum
			(
				case
					when orap.[BVCost]>orap.[ListEstimatedValue]
					then isnull(orap.[ListEstimatedValue],0)
					else isnull(orap.[BVCost],0)
				end
			)
			from #OpenRepoAssetPipelineIndividual orap
			where orap.[EUAdminStatus] = 'Contact Pending'
		);
		declare @ORAP_TotalEndingInventoryIndividual int = 
		(
			isnull(@ORAP_PendingEndingInventory,0) + isnull(@ORAP_AvailableEndingInventory,0) + isnull(@ORAP_ContractPendingEndingInventory,0)
		);
		declare @ORAP_ListEstimatedValueIndividual int = 
		(
			select sum
			(
				isnull(orap.[ListEstimatedTotalValue],0)
			)
			from #OpenRepoAssetPipelineIndividual orap
		);
		declare @ORAP_EstimatedGainLossIndividual int = 
		(
			select sum
			(
				isnull(orap.EstNetGainLoss,0)
			)
			from #OpenRepoAssetPipelineIndividual orap
		);

		--ACTIVITY DATA
		declare @AD_AvgDailyStart int = 
		(
			null
		);
		declare @AD_AvgDailyEnd int = 
		(
			null
		);
		declare @AD_TotalHours int = 
		(
			null
		);
		declare @AD_ActiveHours int = 
		(
			null
		);
		declare @AD_ActivePercent int = 
		(
			null
		);
		declare @AD_NumberOfTotalKeystrokes int = 
		(
			null
		);
		declare @AD_NumberOfTotalEmails int = 
		(
			null
		);

		--TEST SCORES
		declare @TS_NumberMatching int =
		(
			null
		);
		declare @TS_NumberAccuracy int =
		(
			null
		);
		declare @TS_WordMatching int =
		(
			null
		);
		declare @TS_MathTest int =
		(
			null
		);
		declare @TS_MathAccuracy int =
		(
			null
		);
		declare @TS_TypingSpeed int =
		(
			null
		);
		declare @TS_TypingAccuracy int =
		(
			null
		);
		declare @TS_JobSpecificQuestions int =
		(
			null
		);
		declare @TS_BeaconScore int =
		(
			null
		);
		declare @TS_FicoScore int =
		(
			null
		);

		INSERT INTO #IndividualStats
			(
				-- GENERAL
				G_CSSINDEX ,
				G_CurrentIndex ,
				G_HeaderName ,
				G_HeaderToolTip ,
				G_HeaderLink ,
				G_StartDate ,
				G_TableClass ,
              
				G_UniqueUserId ,
				G_Username ,
				G_FromDate ,
				G_ToDate ,

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
				ORAP_EstimatedGainLoss ,

				-- ACTIVITY DATA
				AD_AverageDailyStart ,
				AD_AverageDailyEnd ,
				AD_TotalHours ,
				AD_ActiveHours ,
				AD_ActivePercent ,
				AD_NumberOfTotalKeystrokes ,
				AD_NumberOfTotalEmails,

				--TEST SCORES
				TS_NumberMatching ,
				TS_NumberAccuracy ,
				TS_WordMatching ,
				TS_MathTest ,
				TS_MathAccuracy ,
				TS_TypingSpeed  ,
				TS_TypingAccuracy ,
				TS_JobSpecificQuestions ,
				TS_BeaconScore ,
				TS_FicoScore  
			)
			SELECT top 1 
			0,@counter,@header,@headerToolTip,@headerLink,@startDate,0,0,0,
			@fromDate,@toDate,

			--COMPLETED REPOS
			@CR_NumberOfReposIndividual AS CR_NumberOfRepos,
			@CR_NumberOfProfitOpportunitiesIndividual AS CR_NumberOfProfitOpportunities,
			@CR_NumberOfEndOfLeaseReturnsIndividual AS CR_NumberOfEndOfLeaseReturns,
			@CR_NumberOfTotalIndividual AS CR_NumberOfTotal,

			--REPO TIMELINE (days)
			@RT_AverageStartToRecoveryIndividual AS RT_AverageStartToRecovery,
			@RT_AverageRecoveryToCompleteIndividual AS RT_AverageRecoveryToComplete,
			@RT_AverageTotalIndividual AS RT_AverageTotal,

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
			@ET_LaborIndividual as ET_Labor,
			@ET_PartsIndividual as ET_Parts,
			@ET_LegalIndividual as ET_Legal,
			@ET_CommissionIndividual as ET_Commission,
			@ET_CratingIndividual as ET_Crating,
			@ET_ReferralFeeIndividual as ET_ReferralFee,
			@ET_ShippingIndividual as ET_Shipping,
			@ET_StorageIndividual as ET_Storage,
			@ET_TravelIndividual as ET_Travel,
			@ET_OtherIndividual as ET_Other,
			@ET_TotalIndividual as ET_Total,

			--CREDIT QUALITY
			@CQ_AverageCBRWhenFinancedIndividual AS CQ_AverageCBRWhenFinanced,
			@CQ_AverageCBRAtRepossesionIndividual AS CQ_AverageCBRAtRepossesion,
			@CQ_AverageCBRChangeIndividual AS CQ_AverageCBRChange,

			--ORIGINAL TERMS
			@OT_AverageAmountFinancedIndividual AS OT_AverageAmountFinanced,
			@OT_AverageTermIndividual AS OT_AverageTerm,
			@OT_AverageIRRIndividual as OT_AverageIRR,

			--COLLECTIONS
			@C_AverageNumberOfPaymentsRemainingIndividual as C_AverageNumberOfPaymentsRemaining,
			@C_AverageNumberOfDaysUponRepoIndividual as C_AverageNumberOfDaysUponRepo,
			@C_AverageNumberOfCollectorCommentsIndividual as C_AverageNumberOfCollectorComments,

			--OPEN REPO ASSET PIPELINE
			@ORAP_PendingEndingInventoryIndividual as ORAP_PendingEndingInventory,
			@ORAP_AvailableEndingInventoryIndividual as ORAP_AvailableEndingInventory,
			@ORAP_ContractPendingEndingInventoryIndividual as ORAP_ContractPendingEndingInventory,
			@ORAP_TotalEndingInventoryIndividual as ORAP_TotalEndingInventory,
			@ORAP_ListEstimatedValueIndividual as ORAP_ListEstimatedValue,
			@ORAP_EstimatedGainLossIndividual as ORAP_EstimatedGainLoss,

			--ACTIVITY DATA
			@AD_AvgDailyStart,
			@AD_AvgDailyEnd,
			@AD_TotalHours,
			@AD_ActiveHours,
			@AD_ActivePercent,
			@AD_NumberOfTotalKeystrokes,
			@AD_NumberOfTotalEmails,

			--TEST SCORES
			@TS_NumberMatching,
			@TS_NumberAccuracy,
			@TS_WordMatching,
			@TS_MathTest,
			@TS_MathAccuracy,
			@TS_TypingSpeed,
			@TS_TypingAccuracy,
			@TS_JobSpecificQuestions,
			@TS_BeaconScore,
			@TS_FicoScore

			FROM #ClosedReposIndividual cr

		SET @counter = @counter + 1;
	END


	------------------------
	---CALCULATE BFC MISC---
	------------------------
	IF OBJECT_ID('tempdb..#ClosedReposMisc') IS NOT NULL
    DROP TABLE #ClosedReposMisc
	SELECT cr.*
	INTO #ClosedReposMisc
	FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
	INNER JOIN #InactiveIndividuals ii
	ON cr.SalesPersonGUID like ii.CRMGuid
	WHERE cr.closedon >= '1/1/2015' and cr.closedon<='1/1/2017'
	AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue])
	--AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
	--AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
	AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
	AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
	AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)
	

	declare @CR_NumberOfReposMisc int =
	(
		select count(cr.Type) 
		from #ClosedReposMisc cr
		WHERE cr.Type = 'Repo'
	);
	declare @CR_NumberOfProfitOpportunitiesMisc int = 
	(
		select count(cr.Type) 
		from #ClosedReposMisc cr
		WHERE cr.Type = 'Profit Opp'
	);
	declare @CR_NumberOfEndOfLeaseReturnsMisc int =
	(
		select count(cr.Type) 
		from #ClosedReposMisc cr
		WHERE cr.Type = 'End Of Lease Return'
	);
	declare @CR_NumberOfTotalMisc int = 
	(
		isnull(@CR_NumberOfReposMisc,0) + isnull(@CR_NumberOfProfitOpportunitiesMisc,0) + isnull(@CR_NumberOfEndOfLeaseReturnsMisc,0)
	);

	--REPO TIMELINE (days)
	declare @RT_AverageStartToRecoveryMisc decimal =
	(
		select avg(DATEdiff(day,cr.new_repostartDATE,cr.ActualPickupDATE))
		from #ClosedReposMisc cr
	);
	declare @RT_AverageRecoveryToCompleteMisc decimal =
	(
		select avg(DATEdiff(day, cr.ActualPickupDATE, cr.closedon))
		from #ClosedReposMisc cr
	);
	declare @RT_AverageTotalMisc decimal =
	(
		isnull(@RT_AverageStartToRecoveryMisc,0) + isnull(@RT_AverageRecoveryToCompleteMisc,0)
	);

	--EXPENSE TYPE
	declare @ET_LaborMisc decimal = isnull(
	(	
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Labor'
	),0);
	declare @ET_PartsMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Parts'
	),0);
	declare @ET_LegalMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Legal'
	),0);
	declare @ET_CommissionMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Commission'
	),0);
	declare @ET_CratingMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Crating'
	),0);
	declare @ET_ReferralFeeMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Referral Fee'
	),0);
	declare @ET_ShippingMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Shipping'
	),0);
	declare @ET_StorageMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Storage'
	),0);
	declare @ET_TravelMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Travel'
	),0);
	declare @ET_OtherMisc decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpenses re
		where re.[Type] = 'Other'
	),0)
	declare @ET_TotalMisc decimal=
	(
		@ET_LaborMisc + @ET_PartsMisc + @ET_LegalMisc + @ET_CommissionMisc + @ET_CratingMisc + @ET_ReferralFeeMisc + @ET_ShippingMisc + @ET_StorageMisc + @ET_TravelMisc + @ET_OtherMisc
	);

	--CREDIT QUALITY
	declare @CQ_AverageCBRWhenFinancedMisc int =
	(
		select avg(cr.[RepoBeaconScore])
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @CQ_AverageCBRAtRepossesionMisc int =
	(
		select avg(cr.[OriginalBeaconScore])
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @CQ_AverageCBRChangeMisc int =
	(
		isnull(@CQ_AverageCBRWhenFinancedMisc,0)-isnull(@CQ_AverageCBRAtRepossesionMisc,0)
	);

	--ORIGINAL TERMS
	declare @OT_AverageAmountFinancedMisc  int =
	(
		select sum(cr.AmountFinanced)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @OT_AverageTermMisc  decimal =
	(
		select sum(cr.[TotalTerm])/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @OT_AverageIRRMisc decimal =
	(
		select (sum(cr.IRR*cr.AmountFinanced)/nullif(sum(cr.AmountFinanced),0))*100 --weighted by amount financed
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);

	--COLLECTIONS
	declare @C_AverageNumberOfPaymentsRemainingMisc decimal =
	( 
		select sum(cr.PaymentRemaining)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfDaysUponRepoMisc decimal =
	(
		select sum(cr.[DaysPastDueatRepo])/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfCollectorCommentsMisc decimal =
	(
		select sum(cr.numOfCollectorComments)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposMisc cr
		where cr.[Type] = 'Repo' 
	);

	--OPEN REPO ASSET PIPELINE
	declare @ORAP_PendingEndingInventoryMisc int = 
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
	declare @ORAP_AvailableEndingInventoryMisc  int = 
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
	declare @ORAP_ContractPendingEndingInventoryMisc int = 
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
		where orap.[EUAdminStatus] = 'Contact Pending'
	);
	declare @ORAP_TotalEndingInventoryMisc int = 
	(
		isnull(@ORAP_PendingEndingInventoryMisc,0) + isnull(@ORAP_AvailableEndingInventoryMisc,0) + isnull(@ORAP_ContractPendingEndingInventoryMisc,0)
	);
	declare @ORAP_ListEstimatedValueMisc int = (
		select sum
		(
			isnull(orap.[ListEstimatedTotalValue],0)
		)
		from #OpenRepoAssetPipeline orap
	);
	declare @ORAP_EstimatedGainLossMisc int = 
	(
		select sum
		(
			isnull(orap.EstNetGainLoss,0)
		)
		from #OpenRepoAssetPipeline orap
	);

	INSERT INTO #IndividualStats
	(
		-- GENERAL
		G_CSSINDEX ,
		G_CurrentIndex ,
		G_HeaderName ,
		G_HeaderToolTip ,
		G_HeaderLink ,
		G_StartDate ,
		G_TableClass ,
              
		G_UniqueUserId ,
		G_Username ,
		G_FromDate ,
		G_ToDate ,

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
		ORAP_EstimatedGainLoss ,

		-- ACTIVITY DATA
		AD_AverageDailyStart ,
		AD_AverageDailyEnd ,
		AD_TotalHours ,
		AD_ActiveHours ,
		AD_ActivePercent ,
		AD_NumberOfTotalKeystrokes ,
		AD_NumberOfTotalEmails ,

		--TEST SCORES
		TS_NumberMatching ,
		TS_NumberAccuracy ,
		TS_WordMatching ,
		TS_MathTest ,
		TS_MathAccuracy ,
		TS_TypingSpeed ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore 
	)
	SELECT
	-5,@counter,'Misc.','Misc.'
	,case when @GroupID = 1 
			then '~/EmployeeMetrics/RepoBuilderStats.aspx?v=IRDD&d='+@DateRangeCode+'&u='+ '00000000-0000-0000-0000-000000000000' +'&f=IR' 
			else '~/EmployeeMetrics/RepoBuilderStats.aspx?v=IRDD&d='+@DateRangeCode+'&u='+ '00000000-0000-0000-0000-000000000000' +'&f=IRC'  end
	,null,4,5,66,
	@fromDate,@toDate,

	--COMPLETED REPOS
	@CR_NumberOfReposMisc AS CR_NumberOfRepos,
	@CR_NumberOfProfitOpportunitiesMisc AS CR_NumberOfProfitOpportunities,
	@CR_NumberOfEndOfLeaseReturnsMisc AS CR_NumberOfEndOfLeaseReturns,
	@CR_NumberOfTotalMisc AS CR_NumberOfTotal,

	--REPO TIMELINE (days)
	@RT_AverageStartToRecoveryMisc AS RT_AverageStartToRecovery,
	@RT_AverageRecoveryToCompleteMisc AS RT_AverageRecoveryToComplete,
	@RT_AverageTotalMisc AS RT_AverageTotal,

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
	@ET_LaborMisc as ET_Labor,
	@ET_PartsMisc as ET_Parts,
	@ET_LegalMisc as ET_Legal,
	@ET_CommissionMisc as ET_Commission,
	@ET_CratingMisc as ET_Crating,
	@ET_ReferralFeeMisc as ET_ReferralFee,
	@ET_ShippingMisc as ET_Shipping,
	@ET_StorageMisc as ET_Storage,
	@ET_TravelMisc as ET_Travel,
	@ET_OtherMisc as ET_Other,
	@ET_TotalMisc as ET_Total,

	--CREDIT QUALITY
	@CQ_AverageCBRWhenFinancedMisc AS CQ_AverageCBRWhenFinanced,
	@CQ_AverageCBRAtRepossesionMisc AS CQ_AverageCBRAtRepossesion,
	@CQ_AverageCBRChangeMisc AS CQ_AverageCBRChange,

	--ORIGINAL TERMS
	@OT_AverageAmountFinancedMisc AS OT_AverageAmountFinanced,
	@OT_AverageTermMisc AS OT_AverageTerm,
	@OT_AverageIRRMisc as OT_AverageIRR,

	--COLLECTIONS
	@C_AverageNumberOfPaymentsRemainingMisc as C_AverageNumberOfPaymentsRemaining,
	@C_AverageNumberOfDaysUponRepoMisc as C_AverageNumberOfDaysUponRepo,
	@C_AverageNumberOfCollectorCommentsMisc as C_AverageNumberOfCollectorComments,

	--OPEN REPO ASSET PIPELINE
	@ORAP_PendingEndingInventoryMisc as ORAP_PendingEndingInventory,
	@ORAP_AvailableEndingInventoryMisc as ORAP_AvailableEndingInventory,
	@ORAP_ContractPendingEndingInventoryMisc as ORAP_ContractPendingEndingInventory,
	@ORAP_TotalEndingInventoryMisc as ORAP_TotalEndingInventory,
	@ORAP_ListEstimatedValueMisc as ORAP_ListEstimatedValue,
	@ORAP_EstimatedGainLossMisc as ORAP_EstimatedGainLoss,

	--ACTIVITY DATA
	0,0,0,0,0,0,0,

	--TEST SCORES
	0,0,0,0,0,0,0,0,0,0

	FROM #ClosedReposMisc cr
	
	SELECT * FROM #IndividualStats 

END

--[dbo].[KeyStats_Repo_LoadIndividualRepo] N'5/20/2015',N'12/20/2015', @GroupID = 1 
GO
