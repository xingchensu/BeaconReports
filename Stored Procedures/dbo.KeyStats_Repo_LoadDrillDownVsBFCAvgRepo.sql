SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tony Mykhaylovsky
-- Create date: 12/16/2015
-- Description:	Company Repo
-- =============================================
--[dbo].[KeyStats_Repo_LoadDrillDownVsBFCAvgRepo] N'5/20/2015',N'12/20/2015',@SalesPersonGUID = 'c69a9d6f-b204-e011-b009-78e7d1f817f8'
CREATE PROCEDURE [dbo].[KeyStats_Repo_LoadDrillDownVsBFCAvgRepo] --N'5/20/2015',N'12/20/2015',@SalesPersonGUID = 'c69a9d6f-b204-e011-b009-78e7d1f817f8'
	@BeginDate AS DATETIME
	,@EndDate AS DATETIME
	,@RepoTypeID AS INT = NULL
	,@SalesPersonGUID AS VARCHAR(360) = NULL
	,@CollectorGUID AS VARCHAR(36) = NULL
	,@CreditManagerGUID AS VARCHAR(360) = NULL
	,@AmericanStateCode AS VARCHAR(2) = NULL
	,@EquipmentTypeValue AS VARCHAR(360) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET @BeginDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @BeginDate)
	SET @EndDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @EndDate)

	DECLARE @GUID AS VARCHAR(36);
	DECLARE @GroupID as int;
	DECLARE @isMisc AS BIT;
	IF @SalesPersonGUID IS NOT NULL
		BEGIN
			SET @GUID = @SalesPersonGUID;
			SET @GroupID = 1;
		END
	ELSE IF @CollectorGUID IS NOT NULL
		BEGIN
			SET @GUID = @CollectorGUID;
			SET @GroupID = 6;
		END
	ELSE
		BEGIN
			SET @GUID = '-1'
			SET @GroupID = 1;
		END

	--Using GUID from above to get the individual's FULL NAME
	DECLARE @FullName AS VARCHAR(100);
	IF @GUID != '00000000-0000-0000-0000-000000000000'
	BEGIN
	    SET @FullName = 
		(
			SELECT TOP 1 (FirstName + ' ' + LastName) 
			FROM [CRMReplication2013].[dbo].[systemuser]
			WHERE CONVERT(VARCHAR(36),SystemUserId) = @GUID --Converted uniqueidentifier(SystemUserId) to varchar in case no GUID is passed and is -1.
		)
	END
	ELSE
	BEGIN
		SET @isMisc = 1;
		SET @FullName = 
		(
			'Misc.'
		)
	END

	IF OBJECT_ID('tempdb..#AllIndividuals') IS NOT NULL
    DROP TABLE #AllIndividuals
	SELECT e.fname
	,e.lname
	,e.fname + ' ' + e.lname AS fullname
	,e.[lname] + ', ' + e.[fname] AS [fullname2]
	,username
	,startdate
	,[shift]
	,[userid]
	,r.CategoryID
	,Categoryname
	,e.CRMGuid
	,r.IsMiscellaneous
	,e.UniqueUserID
	INTO #AllIndividuals
	FROM[LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
	INNER JOIN dbo.KeyStats_Category_Employee_Relation r 
	ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
	INNER JOIN dbo.KeyStats_Categories c 
	ON c.CategoryID=r.CategoryID
	WHERE c.CategoryID = @GroupID--@GroupNo@isMisc
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
	FROM[LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
	INNER JOIN dbo.KeyStats_Category_Employee_Relation r 
	ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
	INNER JOIN dbo.KeyStats_Categories c 
	ON c.CategoryID=r.CategoryID
	left JOIN dbo.KeyStats_Employee_TestScore ts
	ON ts.UniqueUserId = e.UniqueUserID
	WHERE r.IsMiscellaneous = 1  AND c.CategoryID= @GroupID
	ORDER BY e.[fname]


	DECLARE @TotalIndividualsCount INT = isnull(
	(
		SELECT COUNT(ai.CRMGuid) 
		FROM #AllIndividuals ai
	),0);

	IF OBJECT_ID('tempdb..#ClosedRepos') IS NOT NULL
    DROP TABLE #ClosedRepos 
	SELECT cr.* INTO #ClosedRepos 
	FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),cr.SalesPersonGUID), CONVERT(VARCHAR(360),cr.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%' 
	WHERE cr.closedon >= @BeginDate AND cr.closedon<=@EndDate
	AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue]) 
	AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
	AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
	AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
	AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
	AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#ReposExpenses') IS NOT NULL
	DROP TABLE #ReposExpenses
	SELECT re.* INTO #ReposExpenses 
	FROM [dbo].[KeyStats_Repo_AllReposExpense_DailySnapShot] re
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),re.SalesPersonGUID), CONVERT(VARCHAR(360),re.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%'
	WHERE re.closedon >= @BeginDate and re.closedon<=@EndDate
	AND re.RepoTypeValue = ISNULL(@repoTypeID,re.RepoTypeValue) 
	AND re.SalesPersonGUID like ISNULL(@SalesPersonGUID,re.SalesPersonGUID)
	AND re.CollectorGUID = ISNULL(@CollectorGUID,re.CollectorGUID)
	AND re.CreditManagerGUID like ISNULL(@CreditManagerGUID,re.CreditManagerGUID)
	AND re.[CustomerState] = ISNULL(@americanStateCode,re.[CustomerState])
	AND re.EquipTypes like ISNULL(@equipmentTypeValue,re.EquipTypes)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#OpenRepoAssetPipeline') IS NOT NULL --IF SP is too slow, you can optimize this tempdb more.
	DROP TABLE #OpenRepoAssetPipeline
	SELECT * 
	into #OpenRepoAssetPipeline
	from KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot orap
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),orap.SalesPersonGUID), CONVERT(VARCHAR(360),orap.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%'
	where 
	--CAST(orap.SnapshotDATE as date) = @EndDate AND 
	orap.RepoTypeValue = ISNULL(@repoTypeID,orap.RepoTypeValue) 
	AND orap.SalesPersonGUID like ISNULL(@SalesPersonGUID,orap.SalesPersonGUID)
	AND CONVERT(VARCHAR(36),orap.CollectorGUID) = ISNULL(@CollectorGUID,CONVERT(VARCHAR(36),orap.CollectorGUID))
	AND orap.CreditManagerGUID like ISNULL(@CreditManagerGUID,orap.CreditManagerGUID)
	AND orap.[State] = ISNULL(@americanStateCode,orap.[State])
	AND orap.EquipmentCategory like ISNULL(@equipmentTypeValue,orap.EquipmentCategory)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#ClosedReposBFCAvg') IS NOT NULL
    DROP TABLE #ClosedReposBFCAvg
	SELECT cr.*
	INTO #ClosedReposBFCAvg
	FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),cr.SalesPersonGUID), CONVERT(VARCHAR(360),cr.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%'
	WHERE cr.closedon >= @BeginDate and cr.closedon<=@EndDate
	AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue])
	AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
	AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
	AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#ReposExpensesBFCAvg') IS NOT NULL
	DROP TABLE #ReposExpensesBFCAvg
	SELECT re.* 
	INTO #ReposExpensesBFCAvg 
	FROM [dbo].[KeyStats_Repo_AllReposExpense_DailySnapShot] re
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),re.SalesPersonGUID), CONVERT(VARCHAR(360),re.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%'
	WHERE re.closedon >= @BeginDate and re.closedon<=@EndDate
	AND re.RepoTypeValue = ISNULL(@repoTypeID,re.RepoTypeValue) 
	AND re.CreditManagerGUID like ISNULL(@CreditManagerGUID,re.CreditManagerGUID)
	AND re.[CustomerState] = ISNULL(@americanStateCode,re.[CustomerState])
	AND re.EquipTypes like ISNULL(@equipmentTypeValue,re.EquipTypes)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#OpenRepoAssetPipelineBFCAvg') IS NOT NULL --IF SP is too slow, you can optimize this tempdb more.
	DROP TABLE #OpenRepoAssetPipelineBFCAvg
	select *
	into #OpenRepoAssetPipelineBFCAvg
	from KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot orap
	LEFT JOIN #InactiveIndividuals ii ON ISNULL(CONVERT(VARCHAR(360),orap.SalesPersonGUID), CONVERT(VARCHAR(360),orap.CollectorGUID)) LIKE '%'+CONVERT(VARCHAR(360),ii.CRMGuid)+'%'
	where 
	--CAST(orap.SnapshotDATE as date) = @EndDate AND 
	orap.RepoTypeValue = ISNULL(@repoTypeID,orap.RepoTypeValue) 
	AND orap.CreditManagerGUID like ISNULL(@CreditManagerGUID,orap.CreditManagerGUID)
	AND orap.[State] = ISNULL(@americanStateCode,orap.[State])
	AND orap.EquipmentCategory like ISNULL(@equipmentTypeValue,orap.EquipmentCategory)
	AND ii.IsMiscellaneous = CASE WHEN @GUID = '00000000-0000-0000-0000-000000000000' THEN 1 ELSE ii.IsMiscellaneous END

	IF OBJECT_ID('tempdb..#DrillDownVsBFCAverageStats') IS NOT NULL
      DROP TABLE #DrillDownVsBFCAverageStats
	CREATE TABLE #DrillDownVsBFCAverageStats
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

	SET @header = @FullName + '<br/>'+ CONVERT(VARCHAR(10),@BeginDate,101) + ' - '+CONVERT(VARCHAR(10),@EndDate,101);
	
	-----------------------
	--INDIVIDUAL'S COLUMN--
	-----------------------
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

	INSERT INTO #DrillDownVsBFCAverageStats
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
		ORAP_EstimatedGainLoss,

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
		TS_TypingSpeed  ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore  
	)
	SELECT top 1
	-5,@counter,@header,1,2,3,4,5,66,
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

	null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null
	FROM #ClosedRepos cr

	SET @counter = @counter + 1;

	-----------------------
	---BFC AVERAGE COLUMN--
	-----------------------

	--COMPLETED REPOS
	declare @CR_NumberOfReposBFCAvg int =
	(
		select count(cr.Type) 
		from #ClosedReposBFCAvg cr
		WHERE cr.Type = 'Repo'
	);
	declare @CR_NumberOfProfitOpportunitiesBFCAvg int = 
	(
		select count(cr.Type) 
		from #ClosedReposBFCAvg cr
		WHERE cr.Type = 'Profit Opp'
	);
	declare @CR_NumberOfEndOfLeaseReturnsBFCAvg int =
	(
		select count(cr.Type) 
		from #ClosedReposBFCAvg cr
		WHERE cr.Type = 'End Of Lease Return'
	);
	declare @CR_NumberOfTotalBFCAvg int = 
	(
		@CR_NumberOfRepos + @CR_NumberOfProfitOpportunities + @CR_NumberOfEndOfLeaseReturns
	);

	--REPO TIMELINE (days)
	declare @RT_AverageStartToRecoveryBFCAvg decimal = isnull(
	(
		select avg(DATEdiff(day,cr.new_repostartDATE,cr.ActualPickupDATE))
		from #ClosedReposBFCAvg cr
	),null);
	declare @RT_AverageRecoveryToCompleteBFCAvg decimal = isnull(
	(
		select avg(DATEdiff(day, cr.ActualPickupDATE, cr.closedon))
		from #ClosedReposBFCAvg cr
	),null);
	declare @RT_AverageTotalBFCAvg decimal =
	(
		@RT_AverageStartToRecovery + @RT_AverageRecoveryToComplete
	);

	--EXPENSE TYPE
	declare @ET_LaborBFCAvg decimal = isnull(
	(	
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Labor'
	),0);
	declare @ET_PartsBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Parts'
	),0);
	declare @ET_LegalBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Legal'
	),0);
	declare @ET_CommissionBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Commission'
	),0);
	declare @ET_CratingBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Crating'
	),0);
	declare @ET_ReferralFeeBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Referral Fee'
	),0);
	declare @ET_ShippingBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Shipping'
	),0);
	declare @ET_StorageBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Storage'
	),0);
	declare @ET_TravelBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Travel'
	),0);
	declare @ET_OtherBFCAvg decimal= isnull (
	(
		select sum(re.new_expense) 
		from #ReposExpensesBFCAvg re
		where re.[Type] = 'Other'
	),0)
	declare @ET_TotalBFCAvg decimal=
	(
		@ET_Labor + @ET_Parts + @ET_Legal + @ET_Commission + @ET_Crating + @ET_ReferralFee + @ET_Shipping + @ET_Storage + @ET_Travel + @ET_Other
	);

	--CREDIT QUALITY
	declare @CQ_AverageCBRWhenFinancedBFCAvg int =
	(
		select avg(cr.[RepoBeaconScore])
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @CQ_AverageCBRAtRepossesionBFCAvg int =
	(
		select avg(cr.[OriginalBeaconScore])
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @CQ_AverageCBRChangeBFCAvg int =
	(
		@CQ_AverageCBRWhenFinanced-@CQ_AverageCBRAtRepossesion
	);

	--ORIGINAL TERMS
	declare @OT_AverageAmountFinancedBFCAvg  int =
	(
		select sum(cr.AmountFinanced)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @OT_AverageTermBFCAvg  decimal =
	(
		select sum(cr.[TotalTerm])/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @OT_AverageIRRBFCAvg  decimal =
	(
		select (sum(cr.IRR*cr.AmountFinanced)/nullif(sum(cr.AmountFinanced),0))*100 --weighted by amount financed
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);

	--COLLECTIONS
	declare @C_AverageNumberOfPaymentsRemainingBFCAvg decimal =
	( 
		select sum(cr.PaymentRemaining)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfDaysUponRepoBFCAvg decimal =
	(
		select sum(cr.[DaysPastDueatRepo])/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo'
	);
	declare @C_AverageNumberOfCollectorCommentsBFCAvg decimal =
	(
		select sum(cr.numOfCollectorComments)/nullif(@CR_NumberOfRepos,0)
		from #ClosedReposBFCAvg cr
		where cr.[Type] = 'Repo' 
	);

	--OPEN REPO ASSET PIPELINE
	declare @ORAP_PendingEndingInventoryBFCAvg int = 
	(
		select sum
		(
			case
				when orap.[BVCost]>orap.[ListEstimatedValue]
				then isnull(orap.[ListEstimatedValue],0)
				else isnull(orap.[BVCost],0)
			end
		)
		from #OpenRepoAssetPipelineBFCAvg orap
		where orap.[EUAdminStatus] = 'Available'
	);
	declare @ORAP_AvailableEndingInventoryBFCAvg  int = 
	(
		select sum
		(
			case
				when orap.[BVCost]>orap.[ListEstimatedValue]
				then isnull(orap.[ListEstimatedValue],0)
				else isnull(orap.[BVCost],0)
			end
		)
		from #OpenRepoAssetPipelineBFCAvg orap
		where orap.[EUAdminStatus] = 'Pending'
	);
	declare @ORAP_ContractPendingEndingInventoryBFCAvg int = 
	(
		select sum
		(
			case
				when orap.[BVCost]>orap.[ListEstimatedValue]
				then isnull(orap.[ListEstimatedValue],0)
				else isnull(orap.[BVCost],0)
			end
		)
		from #OpenRepoAssetPipelineBFCAvg orap
		where orap.[EUAdminStatus] = 'Contact Pending'
	);
	declare @ORAP_TotalEndingInventoryBFCAvg int = 
	(
		@ORAP_PendingEndingInventory + @ORAP_AvailableEndingInventory + @ORAP_ContractPendingEndingInventory
	);
	declare @ORAP_ListEstimatedValueBFCAvg int = 
	(
		select sum
		(
			isnull(orap.[ListEstimatedTotalValue],0)
		)
		from #OpenRepoAssetPipelineBFCAvg orap
	);
	declare @ORAP_EstimatedGainLossBFCAvg int = 
	(
		select sum
		(
			isnull(orap.EstNetGainLoss,0)
		)
		from #OpenRepoAssetPipelineBFCAvg orap
	);
	INSERT INTO #DrillDownVsBFCAverageStats
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
		ORAP_EstimatedGainLoss,

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
		TS_TypingSpeed  ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore  
	)
	SELECT top 1
	-5,@counter,'BFC. Avg',1,2,3,4,5,66,
	@fromDate,@toDate,

	--COMPLETED REPOS
	@CR_NumberOfReposBFCAvg/nullif(@TotalIndividualsCount,0) AS CR_NumberOfRepos,
	@CR_NumberOfProfitOpportunitiesBFCAvg/nullif(@TotalIndividualsCount,0) AS CR_NumberOfProfitOpportunities,
	@CR_NumberOfEndOfLeaseReturnsBFCAvg/nullif(@TotalIndividualsCount,0) AS CR_NumberOfEndOfLeaseReturns,
	@CR_NumberOfTotalBFCAvg/nullif(@TotalIndividualsCount,0) AS CR_NumberOfTotal,

	--REPO TIMELINE (days)
	@RT_AverageStartToRecoveryBFCAvg/nullif(@TotalIndividualsCount,0) AS RT_AverageStartToRecovery,
	@RT_AverageRecoveryToCompleteBFCAvg/nullif(@TotalIndividualsCount,0) AS RT_AverageRecoveryToComplete,
	@RT_AverageTotalBFCAvg/nullif(@TotalIndividualsCount,0) AS RT_AverageTotal,

	--GAIN LOSS
	sum(cr.BVCost)/nullif(@TotalIndividualsCount,0) AS GL_BVCost,
	sum(cr.totalExpenses)/nullif(@TotalIndividualsCount,0) AS GL_TotalExpenses,
	sum(cr.miscexpensescredits)/nullif(@TotalIndividualsCount,0) AS GL_MiscCreditsDebits,
	sum(cr.TotalSalesCommission)/nullif(@TotalIndividualsCount,0) AS GL_TotalSalesCommission ,
	sum(cr.breakeven)/nullif(@TotalIndividualsCount,0) AS GL_Breakeven ,
	sum(cr.proceedsfromsale)/nullif(@TotalIndividualsCount,0) AS GL_ActualProceedsFromSales ,
	sum(cr.[settlementreceived])/nullif(@TotalIndividualsCount,0) AS GL_SettlementsReceived ,
	sum(cr.GainLoss)/nullif(@TotalIndividualsCount,0) AS GL_GainLoss ,
	sum(cr.profitopportunitycommission)/nullif(@TotalIndividualsCount,0) AS GL_ProfitOpportunityCommission ,
	sum(cr.NetGainLoss)/nullif(@TotalIndividualsCount,0) AS GL_GainLossNet ,

	--EXPENSE TYPE
	@ET_LaborBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Labor,
	@ET_PartsBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Parts,
	@ET_LegalBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Legal,
	@ET_CommissionBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Commission,
	@ET_CratingBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Crating,
	@ET_ReferralFeeBFCAvg/nullif(@TotalIndividualsCount,0) as ET_ReferralFee,
	@ET_ShippingBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Shipping,
	@ET_StorageBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Storage,
	@ET_TravelBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Travel,
	@ET_OtherBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Other,
	@ET_TotalBFCAvg/nullif(@TotalIndividualsCount,0) as ET_Total,

	--CREDIT QUALITY
	@CQ_AverageCBRWhenFinancedBFCAvg/nullif(@TotalIndividualsCount,0) AS CQ_AverageCBRWhenFinanced,
	@CQ_AverageCBRAtRepossesionBFCAvg/nullif(@TotalIndividualsCount,0) AS CQ_AverageCBRAtRepossesion,
	@CQ_AverageCBRChangeBFCAvg/nullif(@TotalIndividualsCount,0) AS CQ_AverageCBRChange,

	--ORIGINAL TERMS
	@OT_AverageAmountFinancedBFCAvg/nullif(@TotalIndividualsCount,0) AS OT_AverageAmountFinanced,
	@OT_AverageTermBFCAvg/nullif(@TotalIndividualsCount,0) AS OT_AverageTerm,
	@OT_AverageIRRBFCAvg/nullif(@TotalIndividualsCount,0) as OT_AverageIRR,

	--COLLECTIONS
	@C_AverageNumberOfPaymentsRemainingBFCAvg/nullif(@TotalIndividualsCount,0) as C_AverageNumberOfPaymentsRemaining,
	@C_AverageNumberOfDaysUponRepoBFCAvg/nullif(@TotalIndividualsCount,0) as C_AverageNumberOfDaysUponRepo,
	@C_AverageNumberOfCollectorCommentsBFCAvg/nullif(@TotalIndividualsCount,0) as C_AverageNumberOfCollectorComments,

	--OPEN REPO ASSET PIPELINE
	@ORAP_PendingEndingInventoryBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_PendingEndingInventory,
	@ORAP_AvailableEndingInventoryBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_AvailableEndingInventory,
	@ORAP_ContractPendingEndingInventoryBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_ContractPendingEndingInventory,
	@ORAP_TotalEndingInventoryBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_TotalEndingInventory,
	@ORAP_ListEstimatedValueBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_ListEstimatedValue,
	@ORAP_EstimatedGainLossBFCAvg/nullif(@TotalIndividualsCount,0) as ORAP_EstimatedGainLoss,

	null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null
	FROM #ClosedReposBFCAvg cr

	SET @counter = @counter + 1;

	-----------------------
	---DIFFERENCE COLUMN---
	-----------------------
	INSERT INTO #DrillDownVsBFCAverageStats
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
		ORAP_EstimatedGainLoss,

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
		TS_TypingSpeed  ,
		TS_TypingAccuracy ,
		TS_JobSpecificQuestions ,
		TS_BeaconScore ,
		TS_FicoScore  
	)
	SELECT
	-5,@counter,'Difference',1,2,3,4,5,66,
	@fromDate,@toDate,

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
	m2.ORAP_EstimatedGainLoss-m1.ORAP_EstimatedGainLoss,

	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0
	FROM  #DrillDownVsBFCAverageStats m1
	JOIN #DrillDownVsBFCAverageStats m2
	ON m2.G_CurrentIndex=m1.G_CurrentIndex - 1
	WHERE  m2.G_CurrentIndex = 0


	SELECT * FROM #DrillDownVsBFCAverageStats 
END

--[dbo].[KeyStats_Repo_LoadDrillDownVsBFCAvgRepo] N'5/20/2015',N'12/20/2015', @CollectorGUID = 'c69a9d6f-b204-e011-b009-78e7d1f817f8'
GO
