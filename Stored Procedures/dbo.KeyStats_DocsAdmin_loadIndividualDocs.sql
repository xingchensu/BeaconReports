SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:    Ruonan
-- Create date: 12/15/2015
-- Description:  docs admin key stats loading Individual view
-- =============================================
-- KeyStats_DocsAdmin_loadIndividualDocs '1/1/2015','12/22/2015',null,null,null,null,'00000000-0000-0000-0000-000000000000'
CREATE PROCEDURE [dbo].[KeyStats_DocsAdmin_loadIndividualDocs] 
@dateFrom AS datetime,
@dateTo AS datetime,
@consultantID AS uniqueidentifier = NULL,
@contractType AS int = NULL,
@fundingMethod AS int = NULL,
@isTitled AS bit = NULL,
@docsAdminID uniqueidentifier = NULL

AS
BEGIN
  SET NOCOUNT ON;

declare @MiscDocsAdminID AS UNIQUEIDENTIFIER
SET  @MiscDocsAdminID='00000000-0000-0000-0000-000000000000'

	declare @queryStringdateRange as varchar(100)
	set @queryStringdateRange= 'from='
  +CONVERT(varchar(19), @dateFrom, 101)+'&to='+CONVERT(varchar(19), @dateTo, 101)
  declare @headerdateRange as varchar(100)
	set @headerdateRange=CONVERT(varchar(19), @dateFrom, 101)+' - '+CONVERT(varchar(19), @dateTo, 101)
  
  DECLARE @dateSnapshot AS date
  SET @dateSnapshot = '12/13/2015' -- @dateTo
  --convert to UTC
  SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom)
  SET @dateTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo)

  DECLARE @categoryID AS int
  SET @categoryID = 5--fixed for docs admin


	
  IF OBJECT_ID('tempdb..#employees') IS NOT NULL
  BEGIN
    DROP TABLE #employees
  END
  SELECT
      em.lname + ', ' + em.fname AS fullname,
    em.CRMGuid,
    em.username,
    em.UniqueUserId,
    --for grouping
    CASE
      WHEN r.IsMiscellaneous = 0 THEN em.username
      ELSE 'Misc.'
    END AS username_group 
    , CASE
      WHEN r.IsMiscellaneous = 0 THEN em.CRMGuid
      ELSE @MiscDocsAdminID
    END AS CRMGuid_group 
    , CASE
      WHEN r.IsMiscellaneous = 0 THEN  em.lname + ', ' + em.fname
      ELSE 'Miscellaneous'
    END AS fullname_group 
      , CASE
      WHEN r.IsMiscellaneous = 0 THEN  em.UniqueUserId
      ELSE 999999999
    END AS UniqueUserId_group
    
    ,cast(startdate as datetime) as startdate,
    r.IsMiscellaneous
    INTO #employees
  FROM dbo.KeyStats_AllEmployees em
  INNER JOIN dbo.KeyStats_Category_Employee_Relation r
    ON r.UniqueUserId = em.UniqueUserId
  INNER JOIN dbo.KeyStats_Categories c
    ON r.CategoryID = c.CategoryID
  WHERE c.CategoryID =@categoryID
  
	declare @mis_startdate as date
	select @mis_startdate=CAST(AVG(CAST(startdate AS float)) AS DATETIME) 
	from #employees where 
	IsMiscellaneous=1
	
	update #employees
	set startdate=@mis_startdate
	where 	IsMiscellaneous=1
	
	declare @avg_startdate as date
	select @avg_startdate= CAST(AVG(CAST(startdate AS float)) AS DATETIME) 
	from #employees
	
  INSERT INTO #employees
    SELECT
      'BFC Tot.',
      NULL,
      'Beacon Funding Corporation Total',
      0,
      --for grouping
      'BFC Tot.' AS username_group
      ,null as CRMGuid_group
      ,'Beacon Funding Corporation Total' fullname_group
      ,1 
      ,@avg_startdate
      ,null as IsMiscellaneous
--select * from #employees

 DECLARE @docsAdmin AS varchar(160)
  IF @docsAdminID IS not NULL --and @docsAdminID<>@MiscDocsAdminID
  BEGIN
     SELECT
      @docsAdmin = fullname_group
    FROM #employees
    WHERE CRMGuid_group = @docsAdminID
  END
 


  DECLARE @filter_accepted AS varchar(1000)
  DECLARE @filter_open AS varchar(1000)
  SET @filter_accepted = 'where [acceptanceDate]>='''
  + CONVERT(varchar(19), @dateFrom, 121)
  + ''' and [acceptanceDate]<=''' + CONVERT(varchar(19), @dateTo, 121) + ''' '
  SET @filter_open = 'where SnapshotDate='''
  + CONVERT(varchar(19), @dateSnapshot) + ''' '
  --select @filter_accepted,@filter_open
  DECLARE @filter AS varchar(1000)
  SET @filter = ''

  IF @consultantID IS NOT NULL
  BEGIN
    SET @filter = @filter + 'and [consultantId] = ''' + CAST(@consultantID AS varchar(40)) + ''' '
  END
  IF @fundingMethod IS NOT NULL
  BEGIN
    SET @filter = @filter + 'and [FundingMethodValue] = ' + CAST(@fundingMethod AS varchar(1)) + ' '
  END
  IF @isTitled IS NOT NULL
  BEGIN
    SET @filter = @filter + 'and [isTitled] = ' + CAST(@isTitled AS varchar(1)) + ' '
  END
  IF @contractType IS NOT NULL
  BEGIN
    SET @filter = @filter + 'and [ContractType] = ' + CAST(@contractType AS varchar(1)) + ' '
  END
  SET @filter_accepted = @filter_accepted + @filter
  SET @filter_open = @filter_open + @filter


  --accepted opportunities
  IF OBJECT_ID('tempdb..#details') IS NOT NULL
  BEGIN
    DROP TABLE #details
  END
  CREATE TABLE #details (
    opid [uniqueidentifier] NOT NULL,
    [Appid] [varchar](15) NULL,
    [consultant] [varchar](160) NULL,
    [consultantId] [uniqueidentifier] NOT NULL,
    [companyName] [varchar](250) NULL,
    [acceptanceDate] [datetime2](2) NULL,
    [leaseAmt] [money] NULL,
    [FundingMethodValue] [tinyint] NULL,
    [FundingMethod] [varchar](200) NULL,
    [isTitled] [bit] NOT NULL,
    [equipmentType] [varchar](20) NOT NULL,
    [New_LeaseAdministratorId] [uniqueidentifier] NULL,
    [New_LeaseAdministratorIdName] [varchar](200) NULL,
    [oppStatus] [varchar](150) NULL,
    [distributionmethod] [varchar](150) NULL,
    [NoOfEnvelopesSent] [int] NULL,
    [DocsPendingDate] [datetime2](2) NULL,
    [DocsSent] [datetime2](2) NULL,
    [DocumentsReceivedDate] [datetime2](2) NULL,
    [InitialPurchaseOrderDate] [datetime2](2) NULL,
    [ContractType] [tinyint] NULL,
    NoOfDocsAdded int null,
    NoOfDocsRemoved int null
  )
  EXEC ('
  insert into #details
  (opid,[Appid]
      ,[consultant]
      ,[consultantId]
      ,[companyName]
      ,[acceptanceDate]
      ,[leaseAmt]
      ,[FundingMethodValue]
      ,[FundingMethod]    
      ,[isTitled]
      ,[equipmentType]
      ,[New_LeaseAdministratorId]
      ,[New_LeaseAdministratorIdName]
      ,[oppStatus]
      ,[distributionmethod]
      ,[NoOfEnvelopesSent]
      ,[DocsPendingDate]
      ,[DocsSent]
      ,[DocumentsReceivedDate]
      ,[InitialPurchaseOrderDate]
      ,[ContractType]
      ,  NoOfDocsAdded 
      , NoOfDocsRemoved )
  select opid,[Appid]
      ,[consultant]
      ,[consultantId]
      ,[companyName]
      ,[acceptanceDate]
      ,[leaseAmt]
      ,[FundingMethodValue]
      ,[FundingMethod]    
      ,[isTitled]
      ,[equipmentType]
      ,[New_LeaseAdministratorId]
      ,[New_LeaseAdministratorIdName]
      ,[oppStatus]
      ,[distributionmethod]
      ,[NoOfEnvelopesSent]
      ,[DocsPendingDate]
      ,[DocsSent]
      ,[DocumentsReceivedDate]
      ,[InitialPurchaseOrderDate]
      ,[ContractType],
      NoOfDocsAdded,NoOfDocsRemoved
      FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] ' + @filter_accepted
  )

  IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL
    DROP TABLE #SpectorDailyAdminDataSnapShot

  SELECT
    DirectoryName,
    [TotalActiveHr],
    [NonWorkHours],
    TotalHours,
    [DailyStartMin],
    [DailyEndMin],
    [PhoneCalls],
    [CallDuration],
    [TotalInboundCalls],
    [TotalOutboundCalls],
    [TotalForwardCalls],
    [TotalInternalCalls],
    [KeyStrokes],
    [EmailSent] INTO #SpectorDailyAdminDataSnapShot
  FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
  WHERE [SnapshotDate] >= @dateFrom
  AND [SnapshotDate] <= @dateTo
  AND DirectoryName IN (SELECT
    username
  FROM #employees)

  --open opportunities, 
  IF OBJECT_ID('tempdb..#OpenDeals') IS NOT NULL
  BEGIN
    DROP TABLE #OpenDeals
  END
  CREATE TABLE #OpenDeals (
    [new_appid] [varchar](50) NULL,
    [OpportunityId] [uniqueidentifier] NOT NULL,
    [SnapshotDate] [date] NOT NULL,
    [salesstagecode] [tinyint] NULL,
    [statuscode] [tinyint] NULL,
    [new_fundingmethod] [tinyint] NULL,
    [ownerid] [uniqueidentifier] NULL,
    [LeaseAmount] [money] NULL,
    [New_LeaseAdministratorId] [uniqueidentifier] NULL,
    [new_contracttype] [tinyint] NULL,
    [isDocusigned] [bit] NULL,
    [isTitled] [bit] NULL,
    acceptanceDate datetime2(2) NULL
  )
  EXEC ('
  insert into #OpenDeals
  ([new_appid]
      ,[OpportunityId]
      ,[SnapshotDate]
      ,[salesstagecode]
      ,[statuscode]
      ,[new_fundingmethod]
      ,[ownerid]
      ,[LeaseAmount]
      ,[New_LeaseAdministratorId]
      ,[new_contracttype]
      ,[isDocusigned]
      ,[isTitled],acceptanceDate)
  select [new_appid]
      ,[OpportunityId]
      ,[SnapshotDate]
      ,[salesstagecode]
      ,[statuscode]
      ,[fundingmethodvalue]
      ,[consultantId]
      ,[LeaseAmount]
      ,[New_LeaseAdministratorId]
      ,[contracttype]
      ,[isDocusigned]
      ,[isTitled],acceptanceDate
      FROM [dbo].KeyStats_OpenOpportunityPipeline_DailySnapshot ' + @filter_open
  )

  --1. sales details 
  if @docsAdminID is null
  begin
  
  SELECT  
   opid as OpportunityId,
    [Appid],
    [consultant] as Owner,
    [companyName] as account,
    [acceptanceDate],
    [leaseAmt] as AmountFinanced,
    [FundingMethod] as Funding_Source,
    [equipmentType] as EquipmentTypes,
    [New_LeaseAdministratorIdName] as LeaseAdmin,
    [oppStatus],
    [distributionmethod] as DocDistributionMethod,
    [NoOfEnvelopesSent],
    [DocsPendingDate]  
  FROM #details
  end
  else 
  begin
  IF @docsAdminID<>@MiscDocsAdminID
  BEGIN
   SELECT  
   opid as OpportunityId,
    [Appid],
    [consultant] as Owner,
    [companyName] as account,
    [acceptanceDate],
    [leaseAmt] as AmountFinanced,
    [FundingMethod] as Funding_Source,
    [equipmentType] as EquipmentTypes,
    [New_LeaseAdministratorIdName] as LeaseAdmin,
    [oppStatus],
    [distributionmethod] as DocDistributionMethod,
    [NoOfEnvelopesSent],
    [DocsPendingDate]  
  FROM #details
   where [New_LeaseAdministratorId]=@docsAdminID
  END
  ELSE
  BEGIN
   SELECT  
   opid as OpportunityId,
    [Appid],
    [consultant] as Owner,
    [companyName] as account,
    [acceptanceDate],
    [leaseAmt] as AmountFinanced,
    [FundingMethod] as Funding_Source,
    [equipmentType] as EquipmentTypes,
    [New_LeaseAdministratorIdName] as LeaseAdmin,
    [oppStatus],
    [distributionmethod] as DocDistributionMethod,
    [NoOfEnvelopesSent],
    [DocsPendingDate]  
  FROM #details
   where [New_LeaseAdministratorId]IN
   (SELECT CRMGUID FROM
   	 #employees
	where 	IsMiscellaneous=1)
  
  END
  end
 ;


  --2. individual docs admin

  IF OBJECT_ID('tempdb..#final') IS NOT NULL
  BEGIN
    DROP TABLE #final
  END;
	

  --individual.
  WITH accepted_ind
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
      ELSE 0
    END) AS [portfolioleaseAmt],
    AVG(CASE
      WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
      ELSE NULL
    END) AS [portfolioleaseAmt_avg],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 1
      ELSE 0
    END) AS [portfolioCount],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE [leaseAmt]
    END) AS [oneoffleaseAmt],
    AVG(CASE
      WHEN [FundingMethodValue] = 1 THEN NULL
      ELSE [leaseAmt]
    END) AS [oneoffleaseAmt_avg],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE 1
    END) AS [oneoffCount],
    SUM([leaseAmt]) AS [leaseAmt],
    AVG([leaseAmt]) AS [leaseAmt_avg],
    SUM(1) AS [totalCount],
    SUM(CASE
      WHEN isTitled = 1 THEN [leaseAmt]
      ELSE 0
    END) AS [TitledleaseAmt],
    AVG(CASE
      WHEN isTitled = 1 THEN [leaseAmt]
      ELSE NULL
    END) AS [TitledleaseAmt_avg],
    SUM(CASE
      WHEN isTitled = 1 THEN 1
      ELSE 0
    END) AS [TitledCount],
    AVG(DATEDIFF(DAY, DocsPendingDate, DocsSent)) AS TimeToSend,
    AVG(DATEDIFF(DAY, DocsSent, DocumentsReceivedDate)) AS TimeToReceive,
    AVG(DATEDIFF(DAY, DocumentsReceivedDate, InitialPurchaseOrderDate)) AS TimeToPO,
    AVG(DATEDIFF(DAY, InitialPurchaseOrderDate, [acceptanceDate])) AS TimeToFund,
    AVG(DATEDIFF(DAY, DocsPendingDate, [acceptanceDate])) AS TotalTime,
    sum([NoOfEnvelopesSent]) as DocBuilder,
      avg([NoOfEnvelopesSent]) as DocBuilder_avg,
     sum(ISNULL(NoOfDocsAdded,0)+ISNULL(NoOfDocsRemoved,0)) as ManuallyDocs,
       avg(ISNULL(NoOfDocsAdded,0)+ISNULL(NoOfDocsRemoved,0)) as ManuallyDocs_avg
  FROM #details s
  INNER JOIN #employees em
    ON s.[New_LeaseAdministratorId] = em.CRMGuid
  GROUP BY em.username_group WITH ROLLUP),
  open_ind
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN LeaseAmount
      ELSE 0
    END) AS [portfolioLeaseAmount],
    AVG(CASE
      WHEN new_fundingmethod = 1 THEN LeaseAmount
      ELSE NULL
    END) AS [portfolioLeaseAmount_avg],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 1
      ELSE 0
    END) AS [portfolioCount],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 0
      ELSE LeaseAmount
    END) AS [oneoffLeaseAmount],
    AVG(CASE
      WHEN new_fundingmethod = 1 THEN NULL
      ELSE LeaseAmount
    END) AS [oneoffLeaseAmount_avg],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 0
      ELSE 1
    END) AS [oneoffCount],
    SUM(LeaseAmount) AS LeaseAmount,
    AVG(LeaseAmount) AS LeaseAmount_avg,
    SUM(1) AS TotalCount,
    SUM(CASE
      WHEN isTitled = 1 THEN LeaseAmount
      ELSE 0
    END) AS [TitledLeaseAmount],
    AVG(CASE
      WHEN isTitled = 1 THEN LeaseAmount
      ELSE NULL
    END) AS [TitledLeaseAmount_avg],
    SUM(CASE
      WHEN isTitled = 1 THEN 1
      ELSE 0
    END) AS [TitledCount],
    SUM(CASE
      WHEN New_LeaseAdministratorId IS NULL THEN LeaseAmount
      ELSE 0
    END) AS [UnassignedLeaseAmount],
    AVG(CASE
      WHEN New_LeaseAdministratorId IS NULL THEN LeaseAmount
      ELSE NULL
    END) AS [UnassignedLeaseAmount_avg],
    SUM(CASE
      WHEN New_LeaseAdministratorId IS NULL THEN 1
      ELSE 0
    END) AS [UnassignedCount],
    SUM(CASE
      WHEN isDocusigned = 1 THEN LeaseAmount
      ELSE 0
    END) AS [DocusignedLeaseAmount],
    AVG(CASE
      WHEN isDocusigned = 1 THEN LeaseAmount
      ELSE NULL
    END) AS [DocusignedLeaseAmount_avg],
    SUM(CASE
      WHEN isDocusigned = 1 THEN 1
      ELSE 0
    END) AS [DocusignedCount],
    SUM(CASE
      WHEN statuscode = 9 THEN LeaseAmount
      ELSE 0
    END) AS [ActivatedLeaseAmount],
    AVG(CASE
      WHEN statuscode = 9 THEN LeaseAmount
      ELSE NULL
    END) AS [ActivatedLeaseAmount_avg],
    SUM(CASE
      WHEN statuscode = 9 THEN 1
      ELSE 0
    END) AS [ActivatedCount],
    AVG(DATEDIFF(DAY, acceptanceDate, GETDATE())) AS ActivatedAvgDays
  FROM #employees em
  INNER JOIN #OpenDeals s
    ON s.New_LeaseAdministratorId = em.CRMGuid
  GROUP BY em.username_group WITH ROLLUP),
  testscore_ind
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    AVG([MathTest]) AS [Math Test],
    AVG([MathTestAttempt]) AS [Math Test Attempt],
    AVG([ProofReadingTestA]) AS [Proof Reading Test A],
    AVG([ProofReadingTestAAttempt]) AS [Proof Reading Test A Attempt],
    AVG([ProofReadingTestB]) AS [Proof Reading Test B],
    AVG([ProofReadingTestBAttepmt]) AS [Proof Reading Test B Attepmt],
    AVG([TypingTestWPM]) AS [Typing Test - WPM],
    AVG([TypingTestAccuracy]) AS [Typing Test - Accuracy],
    AVG([TypingTestKeyStrokes]) AS [TypingTest KeyStrokes],
    AVG([BeaconScore]) AS [Beacon Score],
    AVG([FicoScore]) AS [Fico Score]
  FROM #employees em
  INNER JOIN [dbo].[KeyStats_Employee_TestScore] t
    ON em.[UniqueUserId] = t.[UniqueUserId]
  GROUP BY em.username_group WITH ROLLUP),
  evaluation_ind
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    AVG([Rating]) AS AvgEvaluationRating,
    SUM(1) AS AvgEvaluationRatingCount,
    AVG(CASE
      WHEN [EvaluationTypeValue] = 1 THEN [Rating]
      ELSE NULL
    END) AS AvgEvaluationRatingExt,
    SUM(CASE
      WHEN [EvaluationTypeValue] = 1 THEN 1
      ELSE 0
    END) AS AvgEvaluationRatingCountExt,
    AVG(CASE
      WHEN [EvaluationTypeValue] = 1 THEN NULL
      ELSE [Rating]
    END) AS AvgEvaluationRatingIn,
    SUM(CASE
      WHEN [EvaluationTypeValue] = 1 THEN 0
      ELSE 1
    END) AS AvgEvaluationRatingCountIn
  FROM #employees em
  INNER JOIN [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot] ev
    ON ev.[EvaluateForID] = em.CRMGuid
  WHERE [ActualCloseDate] >= @dateFrom
  AND [ActualCloseDate] <= @dateTo
  GROUP BY em.username_group WITH ROLLUP),
  activity_ind
  AS (SELECT
    CASE
      WHEN GROUPING(em.username_group) = 0 THEN em.username_group
      ELSE 'BFC Tot.'
    END AS username_group,
    SUM([TotalActiveHr]) AS totalActiveHours,
    SUM([NonWorkHours]) AS [Non Work Hours],
    SUM(TotalHours) AS [WorkHours],
    AVG([DailyStartMin]) AS startdateminute,
    AVG([DailyEndMin]) AS enddateminute,
    ISNULL(

    CONVERT(varchar(10), AVG([DailyStartMin]) / 60) + ':' +

                                                           CASE

                                                             WHEN

                                                               LEN(CONVERT(varchar(10), AVG([DailyStartMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG([DailyStartMin]) % 60)

                                                             ELSE CONVERT(varchar(10), AVG([DailyStartMin]) % 60)

                                                           END, 0) AS [Daily Start],

    ISNULL(

    CONVERT(varchar(10), AVG([DailyEndMin]) / 60) + ':' +

                                                         CASE

                                                           WHEN

                                                             LEN(CONVERT(varchar(10), AVG([DailyEndMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG([DailyEndMin]) % 60)

                                                           ELSE CONVERT(varchar(10), AVG([DailyEndMin]) % 60)

                                                         END, 0) AS [Daily End],
    SUM([PhoneCalls]) AS totalcall,
    CASE

      WHEN COUNT([PhoneCalls]) > 0 THEN SUM([PhoneCalls]) / COUNT([PhoneCalls])

      ELSE NULL

    END AS avgcalls,
    SUM([CallDuration]) AS totaldurationmin,
    CASE
      WHEN SUM([PhoneCalls]) > 0 THEN SUM([CallDuration]) / SUM([PhoneCalls])
      ELSE NULL
    END AS avgCallDuration,
    CASE
      WHEN SUM([PhoneCalls]) > 0 THEN SUM([CallDuration]) / SUM([PhoneCalls]) * 60
      ELSE NULL
    END AS avgcalldurationmin,
    SUM([TotalInboundCalls]) AS totalcallin,
    SUM([TotalOutboundCalls]) AS totalcallout,
    SUM([TotalForwardCalls]) + SUM([TotalInternalCalls]) AS totalcallint,
    SUM([KeyStrokes]) AS keystroke,
    SUM([EmailSent]) AS totalemails
  FROM #employees em
  INNER JOIN #SpectorDailyAdminDataSnapShot s
    ON em.username = s.DirectoryName
  GROUP BY em.username_group WITH ROLLUP)


  SELECT
  DISTINCT
    emp.username_group AS username,
      emp.CRMguid_group AS CRMguid,
        emp.fullname_group AS fullname,
         emp.UniqueUserId_group AS UniqueUserId,
    emp.startdate,
    acc.[portfolioleaseAmt] AS portfolioleaseAmt_accepted,
    acc.[portfolioleaseAmt_avg] AS portfolioleaseAmt_avg_accepted,
    acc.[portfolioCount] AS portfolioCount_accepted,
    acc.[oneoffleaseAmt] AS oneoffleaseAmt_accepted,
    acc.[oneoffleaseAmt_avg] AS oneoffleaseAmt_avg_accepted,
    acc.[oneoffCount] AS oneoffCount_accepted,
    acc.[leaseAmt] AS leaseAmt_accepted,
    acc.[leaseAmt_avg] AS leaseAmt_avg_accepted,
    acc.[totalCount] AS totalCount_accepted,
    acc.[TitledleaseAmt] AS TitledleaseAmt_accepted,
    acc.[TitledleaseAmt_avg] AS TitledleaseAmt_avg_accepted,
    acc.[TitledCount] AS TitledCount_accepted,
    acc.TimeToSend AS TimeToSend_accepted,
    acc.TimeToReceive AS TimeToReceive_accepted,
    acc.TimeToPO AS TimeToPO_accepted,
    acc.TimeToFund AS TimeToFund_accepted,
    acc.TotalTime AS TotalTime_accepted,
    op.portfolioLeaseAmount AS portfolioLeaseAmount_open,
    op.portfolioLeaseAmount_avg AS portfolioLeaseAmount_avg_open,
    op.portfolioCount AS portfolioCount_open,
    op.oneoffLeaseAmount AS oneoffLeaseAmount_open,
    op.oneoffLeaseAmount_avg AS oneoffLeaseAmount_avg_open,
    op.oneoffCount AS oneoffCount_open,
    op.LeaseAmount AS LeaseAmount_open,
    op.LeaseAmount_avg AS LeaseAmount_avg_open,
    op.TotalCount AS TotalCount_open,
    op.TitledLeaseAmount AS TitledLeaseAmount_open,
    op.TitledLeaseAmount_avg AS TitledLeaseAmount_avg_open,
    op.TitledCount AS TitledCount_open,
    op.UnassignedLeaseAmount AS UnassignedLeaseAmount_open,
    op.UnassignedLeaseAmount_avg AS UnassignedLeaseAmount_avg_open,
    op.UnassignedCount AS UnassignedCount_open,
    op.DocusignedLeaseAmount AS DocusignedLeaseAmount_open,
    op.DocusignedLeaseAmount_avg AS DocusignedLeaseAmount_avg_open,
    op.DocusignedCount AS DocusignedCount_open,
    op.ActivatedLeaseAmount AS ActivatedLeaseAmount_open,
    op.ActivatedLeaseAmount_avg AS ActivatedLeaseAmount_avg_open,
    op.ActivatedCount AS ActivatedCount_open,
    op.ActivatedAvgDays AS ActivatedAvgDays_open,
    te.[Math Test],
    te.[Math Test Attempt],
    te.[Proof Reading Test A],
    te.[Proof Reading Test A Attempt],
    te.[Proof Reading Test B],
    te.[Proof Reading Test B Attepmt],
    te.[Typing Test - WPM],
    te.[Typing Test - Accuracy],
    te.[TypingTest KeyStrokes],
    te.[Beacon Score],
    te.[Fico Score],
    ev.AvgEvaluationRating,
    ev.AvgEvaluationRatingCount,
    ev.AvgEvaluationRatingExt,
    ev.AvgEvaluationRatingCountExt,
    ev.AvgEvaluationRatingIn,
    ev.AvgEvaluationRatingCountIn,
    act.totalActiveHours,
    act.[Non Work Hours],
    act.[WorkHours],
    act.startdateminute,
    act.enddateminute,
    act.[Daily Start],
    act.[Daily End],
    act.totalcall,
    act.avgcalls,
    act.totaldurationmin,
    act.avgCallDuration,
    act.avgcalldurationmin,
    act.totalcallin,
    act.totalcallout,
    act.totalcallint,
    act.keystroke,
    act.totalemails
    ,acc.ManuallyDocs ,acc.ManuallyDocs_avg
    ,acc.DocBuilder   ,acc.DocBuilder_avg
    INTO #final
  FROM #employees emp
  LEFT JOIN accepted_ind acc
    ON acc.username_group = emp.username_group
  LEFT JOIN open_ind op
    ON op.username_group = emp.username_group
  LEFT JOIN testscore_ind te
    ON te.username_group = emp.username_group
  LEFT JOIN evaluation_ind ev
    ON ev.username_group = emp.username_group
  LEFT JOIN activity_ind act
    ON act.username_group = emp.username_group
    

  DECLARE @em_count AS int
  SELECT
    @em_count = COUNT(uniqueuserid)
  FROM #employees

--ALTER TABLE #final
--ALTER COLUMN TableClass varchar(10)

  INSERT INTO #final
    SELECT    
      'BFC Avg.' AS username,
      null as crmguid,
      'Beacon Funding Corporation Average' AS fullname, 
      2 as UniqueUserId,
      startdate as startdate,
      portfolioleaseAmt_avg_accepted,
      NULL,
      portfolioCount_accepted / @em_count,
      oneoffleaseAmt_avg_accepted,
      NULL,
      oneoffCount_accepted / @em_count,
      leaseAmt_avg_accepted,
      NULL,
      totalCount_accepted / @em_count,
      TitledleaseAmt_avg_accepted,
      NULL,
      TitledCount_accepted / @em_count,
      TimeToSend_accepted,
      TimeToReceive_accepted,
      TimeToPO_accepted,
      TimeToFund_accepted,
      TotalTime_accepted,
      portfolioLeaseAmount_avg_open,
      NULL,
      portfolioCount_open / @em_count,
      oneoffLeaseAmount_avg_open,
      NULL,
      oneoffCount_open / @em_count,
      LeaseAmount_avg_open,
      NULL,
      TotalCount_open / @em_count,
      TitledLeaseAmount_avg_open,
      NULL,
      TitledCount_open / @em_count,
      UnassignedLeaseAmount_avg_open,
      NULL,
      UnassignedCount_open / @em_count,
      DocusignedLeaseAmount_avg_open,
      NULL,
      DocusignedCount_open / @em_count,
      ActivatedLeaseAmount_avg_open,
      NULL,
      ActivatedCount_open / @em_count,
      ActivatedAvgDays_open,
      [Math Test],
      [Math Test Attempt],
      [Proof Reading Test A],
      [Proof Reading Test A Attempt],
      [Proof Reading Test B],
      [Proof Reading Test B Attepmt],
      [Typing Test - WPM],
      [Typing Test - Accuracy],
      [TypingTest KeyStrokes],
      [Beacon Score],
      [Fico Score],
      AvgEvaluationRating,
      AvgEvaluationRatingCount / @em_count,
      AvgEvaluationRatingExt,
      AvgEvaluationRatingCountExt / @em_count,
      AvgEvaluationRatingIn,
      AvgEvaluationRatingCountIn / @em_count,
      totalActiveHours,
      [Non Work Hours],
      [WorkHours],
      startdateminute,
      enddateminute,
      [Daily Start],
      [Daily End],
      totalcall,
      avgcalls,
      totaldurationmin,
      avgCallDuration,
      avgcalldurationmin,
      totalcallin,
      totalcallout,
      totalcallint,
      keystroke,
      totalemails
       ,ManuallyDocs_avg,null
    ,DocBuilder_avg,null
    FROM #final
    WHERE username = 'BFC Tot.'

  UPDATE #final
  SET 
  startdate=null,
  TimeToSend_accepted = NULL,
      TimeToReceive_accepted = NULL,
      TimeToPO_accepted = NULL,
      TimeToFund_accepted = NULL,
      TotalTime_accepted = NULL,
      ActivatedAvgDays_open = NULL,
      [Math Test] = NULL,
      [Math Test Attempt] = NULL,
      [Proof Reading Test A] = NULL,
      [Proof Reading Test A Attempt] = NULL,
      [Proof Reading Test B] = NULL,
      [Proof Reading Test B Attepmt] = NULL,
      [Typing Test - WPM] = NULL,
      [Typing Test - Accuracy] = NULL,
      [TypingTest KeyStrokes] = NULL,
      [Beacon Score] = NULL,
      [Fico Score] = NULL,
      AvgEvaluationRating = NULL,
      AvgEvaluationRatingExt = NULL,
      AvgEvaluationRatingIn = NULL,
      startdateminute = NULL,
      enddateminute = NULL,
      [Daily Start] = NULL,
      [Daily End] = NULL,
      avgcalls = NULL,
      avgCallDuration = NULL,
      avgcalldurationmin = NULL
  WHERE username = 'BFC Tot.'

if @docsAdminID is null 
begin

  SELECT
  username,
  case when username in ('BFC Tot.','BFC Avg.') then '../EmployeeMetrics/DocAdminStats.aspx?v=CS&'+@queryStringdateRange
  
 
 
  
  else '../EmployeeMetrics/DocAdminStats.aspx?v=IDD&u='+cast(CRMGuid as  varchar(40)) +'&'+  @queryStringdateRange
    end as HeaderLink,
  
   case when username='BFC Tot.' then 'BFC_Total'
  when username='BFC Avg.' then 'BFC_Avg'
  else ''
  end  as TableClass,
  
   fullname    as  HeaderToolTip,
  
    case when  username in ('BFC Tot.' ,'BFC Avg.' ,'Misc.') then username
    else case when 
    
    
    
    len(fullname)<=7 then fullname
    else
    left(fullname,7)+'.'end
    end as HeaderName,
    convert(varchar(10),startdate,1) as startdate,
    portfolioleaseAmt_accepted as CompletedPortfolioAmount,
    portfolioCount_accepted as CompletedPortfolioCount,
    oneoffleaseAmt_accepted as CompletedOneOffAmount,
    oneoffCount_accepted as CompletedOneOffCount,
    leaseAmt_accepted as CompletedTotalAmount,
    totalCount_accepted as CompletedTotalCount,
    TitledleaseAmt_accepted as CompletedTitledAmount,
    TitledCount_accepted as CompletedTitledCount,
    TimeToSend_accepted as TimeToSend,
    TimeToReceive_accepted  as TimeToReceive,
    TimeToPO_accepted as TimeToPO,
    TimeToFund_accepted as TimeToFund,
    TotalTime_accepted as TotalTime,
    portfolioLeaseAmount_open as OpenPortfolioAmount,
    portfolioCount_open as OpenPortfolioCount,
    oneoffLeaseAmount_open as OpenOneOffAmount,
    oneoffCount_open as OpenOneOffCount,
    LeaseAmount_open as OpenTotalAmount,
    TotalCount_open as OpenTotalCount,
    TitledLeaseAmount_open as OpenTitledAmount,
    TitledCount_open as OpenTitledCount,
    UnassignedLeaseAmount_open as UnassignedAmount,
    UnassignedCount_open as UnassignedCount,
    DocusignedLeaseAmount_open as DocuSignAmount,
    DocusignedCount_open as DocuSignCount,
    ActivatedLeaseAmount_open as ActivatedFollowUpAmount,
    ActivatedCount_open as ActivatedFollowUpCount,
    ActivatedAvgDays_open as ActivatedAvgDays,
    [Math Test] as MathTest,
    [Math Test Attempt],
    [Proof Reading Test A] as NoMatching,
    [Proof Reading Test A Attempt],
    [Proof Reading Test B]as WordMatching,
    [Proof Reading Test B Attepmt],
    [Typing Test - WPM] as TypingSpeed,
    [Typing Test - Accuracy] as TypingAccuracy,
    [TypingTest KeyStrokes],
    [Beacon Score] as BeaconScore,
    [Fico Score] as FICOScore,
    AvgEvaluationRating,
    AvgEvaluationRatingCount,
    AvgEvaluationRatingExt as EvalExternal,
    AvgEvaluationRatingCountExt,
    AvgEvaluationRatingIn as EvalInternal,
    AvgEvaluationRatingCountIn,
    totalActiveHours as TotalActiveHrs,
    [Non Work Hours] as TotalNoOfKeystrokes,
    [WorkHours] as TotalNonWorkHrs,
    startdateminute,
    enddateminute,
    [Daily Start] as AvgDailyStart,
    [Daily End] as AvgDailyEnd,
    totalcall as NoOfTotalCalls,
    avgcalls as NoOfAvgCallsPerDay,
    totaldurationmin,
    avgCallDuration,
    avgcalldurationmin as AvgCallDurationMin,
    totalcallin as NoOfIncomingCalls,
    totalcallout as NoOfOutgiongCalls,
    totalcallint as NoOfInternalForwardedCalls,
    keystroke as TotalNoOfKeystrokes,
    totalemails as TotalNoOfEmails,
    ManuallyDocs,
    DocBuilder
  FROM #final
  order by UniqueUserId
end
else
begin
	SELECT
  username,
  case when username ='BFC Avg.' then 2
 else 1
  end as [index],
case when username ='BFC Avg.' then username+ '<br />' + @headerdateRange
 else  @docsAdmin + '<br />' + @headerdateRange
 end AS HeaderName,
    --convert(varchar(10),startdate,1) as startdate,
    portfolioleaseAmt_accepted as CompletedPortfolioAmount,
    portfolioCount_accepted as CompletedPortfolioCount,
    oneoffleaseAmt_accepted as CompletedOneOffAmount,
    oneoffCount_accepted as CompletedOneOffCount,
    leaseAmt_accepted as CompletedTotalAmount,
    totalCount_accepted as CompletedTotalCount,
    TitledleaseAmt_accepted as CompletedTitledAmount,
    TitledCount_accepted as CompletedTitledCount,
    TimeToSend_accepted as TimeToSend,
    TimeToReceive_accepted  as TimeToReceive,
    TimeToPO_accepted as TimeToPO,
    TimeToFund_accepted as TimeToFund,
    TotalTime_accepted as TotalTime,
    portfolioLeaseAmount_open as OpenPortfolioAmount,
    portfolioCount_open as OpenPortfolioCount,
    oneoffLeaseAmount_open as OpenOneOffAmount,
    oneoffCount_open as OpenOneOffCount,
    LeaseAmount_open as OpenTotalAmount,
    TotalCount_open as OpenTotalCount,
    TitledLeaseAmount_open as OpenTitledAmount,
    TitledCount_open as OpenTitledCount,
    UnassignedLeaseAmount_open as UnassignedAmount,
    UnassignedCount_open as UnassignedCount,
    DocusignedLeaseAmount_open as DocuSignAmount,
    DocusignedCount_open as DocuSignCount,
    ActivatedLeaseAmount_open as ActivatedFollowUpAmount,
    ActivatedCount_open as ActivatedFollowUpCount,
    ActivatedAvgDays_open as ActivatedAvgDays,
    [Math Test] as MathTest,
    [Math Test Attempt],
    [Proof Reading Test A] as NoMatching,
    [Proof Reading Test A Attempt],
    [Proof Reading Test B]as WordMatching,
    [Proof Reading Test B Attepmt],
    [Typing Test - WPM] as TypingSpeed,
    [Typing Test - Accuracy] as TypingAccuracy,
    [TypingTest KeyStrokes],
    [Beacon Score] as BeaconScore,
    [Fico Score] as FICOScore,
    AvgEvaluationRating,
    AvgEvaluationRatingCount,
    AvgEvaluationRatingExt as EvalExternal,
    AvgEvaluationRatingCountExt,
    AvgEvaluationRatingIn as EvalInternal,
    AvgEvaluationRatingCountIn,
    totalActiveHours as TotalActiveHrs,
    [Non Work Hours] as TotalNoOfKeystrokes,
    [WorkHours] as TotalNonWorkHrs,
    startdateminute,
    enddateminute,
    [Daily Start] as AvgDailyStart,
    [Daily End] as AvgDailyEnd,
    totalcall as NoOfTotalCalls,
    avgcalls as NoOfAvgCallsPerDay,
    totaldurationmin,
    avgCallDuration,
    avgcalldurationmin as AvgCallDurationMin,
    totalcallin as NoOfIncomingCalls,
    totalcallout as NoOfOutgiongCalls,
    totalcallint as NoOfInternalForwardedCalls,
    keystroke as TotalNoOfKeystrokes,
    totalemails as TotalNoOfEmails,
    ManuallyDocs,
    DocBuilder
  FROM #final
 where username ='BFC Avg.'
 or crmguid= @docsAdminID
 
 
 union
 
 
 SELECT
  'Difference' as username,
 3 as [index],
  'Difference'  AS HeaderName,
    --convert(varchar(10),startdate,1) as startdate,
     fi.portfolioleaseAmt_accepted-fa.portfolioleaseAmt_accepted as CompletedPortfolioAmount,
    fi.portfolioCount_accepted-fa.portfolioCount_accepted as CompletedPortfolioCount,
    fi.oneoffleaseAmt_accepted-fa.oneoffleaseAmt_accepted as CompletedOneOffAmount,
     fi.oneoffCount_accepted-fa.oneoffCount_accepted as CompletedOneOffCount,
      fi.leaseAmt_accepted-fa.leaseAmt_accepted as CompletedTotalAmount,
     fi.totalCount_accepted-fa.totalCount_accepted as CompletedTotalCount,
   fi.TitledleaseAmt_accepted-fa.TitledleaseAmt_accepted as CompletedTitledAmount,
     fi.TitledCount_accepted-fa.TitledCount_accepted as CompletedTitledCount,
    fi.TimeToSend_accepted-fa.TimeToSend_accepted as TimeToSend,
     fi.TimeToReceive_accepted-fa.TimeToReceive_accepted as TimeToReceive,
   fi.TimeToPO_accepted-fa.TimeToPO_accepted as TimeToPO,
  fi.TimeToFund_accepted-fa.TimeToFund_accepted as TimeToFund,
   fi.TotalTime_accepted-fa.TotalTime_accepted as TotalTime,
    fi.portfolioLeaseAmount_open-fa.portfolioLeaseAmount_open as OpenPortfolioAmount,
    fi.portfolioCount_open-fa.portfolioCount_open as OpenPortfolioCount,
    fi.oneoffLeaseAmount_open-fa.oneoffLeaseAmount_open as OpenOneOffAmount,
    fi.oneoffCount_open-fa.oneoffCount_open as OpenOneOffCount,
     fi.LeaseAmount_open-fa.LeaseAmount_open as OpenTotalAmount,
   fi.TotalCount_open-fa.TotalCount_open as OpenTotalCount,
   fi.TitledLeaseAmount_open-fa.TitledLeaseAmount_open as OpenTitledAmount,
     fi.TitledCount_open-fa.TitledCount_open as OpenTitledCount,
     fi.UnassignedLeaseAmount_open-fa.UnassignedLeaseAmount_open as UnassignedAmount,
    fi.UnassignedCount_open-fa.UnassignedCount_open as UnassignedCount,
   fi.DocusignedLeaseAmount_open-fa.DocusignedLeaseAmount_open as DocuSignAmount,
    fi.DocusignedCount_open-fa.DocusignedCount_open as DocuSignCount,
   fi.ActivatedLeaseAmount_open-fa.ActivatedLeaseAmount_open as ActivatedFollowUpAmount,
     fi.ActivatedCount_open-fa.ActivatedCount_open as ActivatedFollowUpCount,
     fi.ActivatedAvgDays_open-fa.ActivatedAvgDays_open as ActivatedAvgDays,
    fi.[Math Test]-fa.[Math Test] as MathTest,
      fi.[Math Test Attempt]-fa.[Math Test Attempt] as [Math Test Attempt],
   fi.[Proof Reading Test A]-fa.[Proof Reading Test A] as NoMatching,
   fi.[Proof Reading Test A Attempt]-fa.[Proof Reading Test A Attempt] as [Proof Reading Test A Attempt],
    fi.[Proof Reading Test B]-fa.[Proof Reading Test B] as WordMatching,
    fi.[Proof Reading Test B Attepmt]-fa.[Proof Reading Test B Attepmt] as [Proof Reading Test B Attepmt],
      fi.[Typing Test - WPM]-fa.[Typing Test - WPM] as TypingSpeed,
       fi.[Typing Test - Accuracy]-fa.[Typing Test - Accuracy] as TypingAccuracy,
     fi.[TypingTest KeyStrokes]-fa.[TypingTest KeyStrokes] as [TypingTest KeyStrokes],
    fi.[Beacon Score]-fa.[Beacon Score] as BeaconScore,
    fi.[Fico Score]-fa.[Fico Score] as FICOScore,
     fi.AvgEvaluationRating-fa.AvgEvaluationRating as AvgEvaluationRating,
     fi.AvgEvaluationRatingCount-fa.AvgEvaluationRating as AvgEvaluationRatingCount,
      fi.AvgEvaluationRatingExt-fa.AvgEvaluationRatingExt as EvalExternal,
    fi.AvgEvaluationRatingCountExt-fa.AvgEvaluationRatingCountExt as AvgEvaluationRatingCountExt,
    fi.AvgEvaluationRatingIn-fa.AvgEvaluationRatingIn as EvalInternal,
    fi.AvgEvaluationRatingCountIn-fa.AvgEvaluationRatingCountIn as AvgEvaluationRatingCountIn,
   fi.totalActiveHours-fa.totalActiveHours as TotalActiveHrs,
    fi.[Non Work Hours]-fa.[Non Work Hours] as TotalNoOfKeystrokes,
     fi.[WorkHours]-fa.[WorkHours] as TotalNonWorkHrs,
     fi.startdateminute-fa.startdateminute as startdateminute,
     fi.enddateminute-fa.enddateminute as enddateminute,
      CAST(fi.startdateminute - fa.startdateminute AS varchar(10)) + ' min',
    CAST(fi.enddateminute - fa.enddateminute AS varchar(10)) + ' min',    
     
      fi.totalcall-fa.totalcall as NoOfTotalCalls,
     fi.avgcalls-fa.avgcalls as NoOfAvgCallsPerDay,
     fi.totaldurationmin-fa.totaldurationmin as totaldurationmin,
     fi.avgCallDuration-fa.avgCallDuration as avgCallDuration,
     fi.avgcalldurationmin-fa.avgcalldurationmin as AvgCallDurationMin,
     fi.totalcallin-fa.totalcallin as NoOfIncomingCalls,
     fi.totalcallout-fa.totalcallout as NoOfOutgiongCalls,
     fi.totalcallint-fa.totalcallint as NoOfInternalForwardedCalls,
      fi.keystroke-fa.keystroke as TotalNoOfKeystrokes,
    fi.totalemails-fa.totalemails as TotalNoOfEmails,
      fi.ManuallyDocs-fa.ManuallyDocs as ManuallyDocs,
   fi.DocBuilder-fa.DocBuilder as DocBuilder
    
     FROM #final fi
  INNER JOIN #final fa
    ON fi.crmguid=@docsAdminID
    AND fa.username ='BFC Avg.'  
 
 
end
select top 1
        STUFF(( select distinct '; ' + [New_LeaseAdministratorIdName]

                                    FROM #details 

                    FOR XML PATH('')),1,1,'')

                     AS leaseadmin 
 FROM #details
END
GO
