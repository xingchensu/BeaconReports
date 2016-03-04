SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:    Ruonan
-- Create date: 12/15/2015
-- Description:  docs admin key stats loading campany Docs view
-- =============================================
-- KeyStats_DocsAdmin_loadCompanyDocs '1/1/2016','12/16/2016',null,null,null,null,'00000000-0000-0000-0000-000000000000'
CREATE PROCEDURE [dbo].[KeyStats_DocsAdmin_loadCompanyDocs] 
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

  DECLARE @DateFrom_last AS datetime
  DECLARE @DateTo_last AS datetime

  DECLARE @DateFrom_preyear AS datetime
  DECLARE @DateTo_preyear AS datetime

  DECLARE @DateFrom_pre2year AS datetime
  DECLARE @DateTo_pre2year AS datetime

  SET @DateFrom_last = DATEADD(YEAR, -1, @DateFrom)
  SET @DateTo_last = DATEADD(YEAR, -1, @DateTo)
  SET @DateFrom_preyear = CAST('01/01/' + CAST(YEAR(@DateFrom_last) AS char(4)) AS datetime)
  SET @DateTo_preyear = CAST('12/31/' + CAST(YEAR(@DateTo_last) AS char(4)) AS datetime)
  SET @DateFrom_pre2year = DATEADD(YEAR, -1, @DateFrom_preyear)
  SET @DateTo_pre2year = DATEADD(YEAR, -1, @DateTo_preyear)

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
    em.UniqueUserId 
    ,r.IsMiscellaneous INTO #employees
  FROM dbo.KeyStats_AllEmployees em
  INNER JOIN dbo.KeyStats_Category_Employee_Relation r
    ON r.UniqueUserId = em.UniqueUserId
  INNER JOIN dbo.KeyStats_Categories c
    ON r.CategoryID = c.CategoryID
  WHERE c.CategoryID = @categoryID



declare @MiscDocsAdminID AS UNIQUEIDENTIFIER
SET  @MiscDocsAdminID='00000000-0000-0000-0000-000000000000'

  DECLARE @docsAdmin AS varchar(160)
  IF @docsAdminID IS NULL
  BEGIN
    SET @docsAdmin = 'BFC Total'
  END
  ELSE
  BEGIN
	if @docsAdminID=@MiscDocsAdminID
	begin
		set @docsAdmin='Misc.'
	end
	else
	begin
    SELECT
      @docsAdmin = fullname
    FROM #employees
    WHERE CRMGuid = @docsAdminID
    end
  END

  --DateRangeGroup
  --1: pre 2 year
  --2: pre year
  --3: current
  --4: last

  IF OBJECT_ID('tempdb..#DateRangeGroup') IS NOT NULL
  BEGIN
    DROP TABLE #DateRangeGroup
  END
  CREATE TABLE #DateRangeGroup (
    id int NOT NULL,
    name [varchar](50) NULL
  )

  INSERT INTO #DateRangeGroup
    SELECT
      3 AS [id],
      @docsAdmin + '<br />' + CONVERT(varchar(10), @dateFrom, 101) + ' - ' + CONVERT(varchar(10), @dateTo, 101) AS name
    UNION
    SELECT
      4,
      @docsAdmin + '<br />' + CONVERT(varchar(10), @dateFrom_last, 101) + ' - ' + CONVERT(varchar(10), @dateTo_last, 101) AS name

    UNION
    SELECT
      2,
      @docsAdmin + '<br />' + CONVERT(varchar(4), YEAR(@dateFrom_preyear))
    UNION
    SELECT
      1,
      @docsAdmin + '<br />' + CONVERT(varchar(4), YEAR(@dateFrom_pre2year))
  --select * from #DateRangeGroup



  DECLARE @dateSnapshot AS date
  DECLARE @dateSnapshot_last AS date
  DECLARE @dateSnapshot_preyear AS date
  DECLARE @dateSnapshot_pre2year AS date

  SET @dateSnapshot = @dateTo--'12/13/2015'
  SET @dateSnapshot_last = @dateTo_last
  SET @dateSnapshot_preyear = @dateTo_preyear
  SET @dateSnapshot_pre2year = @dateTo_pre2year

  --convert to UTC
  SET @dateFrom = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom)
  SET @dateTo = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo)

  SET @dateFrom_last = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom_last)
  SET @dateTo_last = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo_last)

  SET @dateFrom_preyear = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom_preyear)
  SET @dateTo_preyear = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo_preyear)

  SET @dateFrom_pre2year = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateFrom_pre2year)
  SET @dateTo_pre2year = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @dateTo_pre2year)


  DECLARE @filter_accepted AS varchar(1000)
  DECLARE @filter_open AS varchar(1000)
  SET @filter_accepted = 'where [acceptanceDate]>='''
  + CONVERT(varchar(19), @dateFrom, 121)
  + ''' and [acceptanceDate]<=''' + CONVERT(varchar(19), @dateTo, 121) + ''' '
  SET @filter_open = 'where SnapshotDate='''
  + CONVERT(varchar(19), @dateSnapshot) + ''' '

  DECLARE @filter_accepted_last AS varchar(1000)
  DECLARE @filter_open_last AS varchar(1000)
  SET @filter_accepted_last = 'where [acceptanceDate]>='''
  + CONVERT(varchar(19), @dateFrom_last, 121)
  + ''' and [acceptanceDate]<=''' + CONVERT(varchar(19), @dateTo_last, 121) + ''' '
  SET @filter_open_last = 'where SnapshotDate='''
  + CONVERT(varchar(19), @dateSnapshot_last) + ''' '

  DECLARE @filter_accepted_preyear AS varchar(1000)
  DECLARE @filter_open_preyear AS varchar(1000)
  SET @filter_accepted_preyear = 'where [acceptanceDate]>='''
  + CONVERT(varchar(19), @dateFrom_preyear, 121)
  + ''' and [acceptanceDate]<=''' + CONVERT(varchar(19), @dateTo_preyear, 121) + ''' '
  SET @filter_open_preyear = 'where SnapshotDate='''
  + CONVERT(varchar(19), @dateSnapshot_preyear) + ''' '

  DECLARE @filter_accepted_pre2year AS varchar(1000)
  DECLARE @filter_open_pre2year AS varchar(1000)
  SET @filter_accepted_pre2year = 'where [acceptanceDate]>='''
  + CONVERT(varchar(19), @dateFrom_pre2year, 121)
  + ''' and [acceptanceDate]<=''' + CONVERT(varchar(19), @dateTo_pre2year, 121) + ''' '
  SET @filter_open_pre2year = 'where SnapshotDate='''
  + CONVERT(varchar(19), @dateSnapshot_pre2year) + ''' '


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
  IF @docsAdminID IS NOT NULL
  BEGIN
	if @docsAdminID=@MiscDocsAdminID
	begin
		set @filter=@filter+ 'and New_LeaseAdministratorId in 
		(select CRMGuid from #employees where IsMiscellaneous=1 ) '
	end
	else
	begin
		SET @filter = @filter + 'and [New_LeaseAdministratorId] = ''' + CAST(@docsAdminID AS varchar(40)) + ''' '
	end
  END
  SET @filter_accepted = @filter_accepted + @filter
  SET @filter_open = @filter_open + @filter

  SET @filter_accepted_last = @filter_accepted_last + @filter
  SET @filter_open_last = @filter_open_last + @filter

  SET @filter_accepted_preyear = @filter_accepted_preyear + @filter
  SET @filter_open_preyear = @filter_open_preyear + @filter

  SET @filter_accepted_pre2year = @filter_accepted_pre2year + @filter
  SET @filter_open_pre2year = @filter_open_pre2year + @filter

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
    DateRangeGroup int NULL,
    NoOfDocsAdded int NULL,
    NoOfDocsRemoved int NULL
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
      ,[ContractType],DateRangeGroup,  NoOfDocsAdded,
    NoOfDocsRemoved)
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
      ,[ContractType],3,  NoOfDocsAdded,
    NoOfDocsRemoved
      FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] ' + @filter_accepted

  + '
  union all
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
      ,[ContractType],4,  NoOfDocsAdded,
    NoOfDocsRemoved
      FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] ' + @filter_accepted_last

  + '
 union all
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
      ,[ContractType],2,  NoOfDocsAdded,
    NoOfDocsRemoved
      FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] ' + @filter_accepted_preyear

  +
  '
  union all
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
      ,[ContractType],1,  NoOfDocsAdded,
    NoOfDocsRemoved
      FROM [dbo].[KeyStats_AcceptedOpportunity_HourlySnapshot] ' + @filter_accepted_pre2year
  )



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
    acceptanceDate datetime2(2) NULL,
    DateRangeGroup int NULL
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
      ,[isTitled],acceptanceDate,DateRangeGroup)
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
      ,[isTitled],acceptanceDate,3
      FROM [dbo].KeyStats_OpenOpportunityPipeline_DailySnapshot ' + @filter_open
  +
  '
      union all
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
      ,[isTitled],acceptanceDate,4
      FROM [dbo].KeyStats_OpenOpportunityPipeline_DailySnapshot ' + @filter_open_last
  +
  '
      union all
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
      ,[isTitled],acceptanceDate,2
      FROM [dbo].KeyStats_OpenOpportunityPipeline_DailySnapshot ' + @filter_open_preyear
  +
  '
      union all
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
      ,[isTitled],acceptanceDate,1
      FROM [dbo].KeyStats_OpenOpportunityPipeline_DailySnapshot ' + @filter_open_pre2year

  )




  --1. sales details 
  SELECT
    opid AS OpportunityId,
    [Appid],
    [consultant] AS Owner,
    [companyName] AS account,
    [acceptanceDate],
    [leaseAmt] AS AmountFinanced,
    [FundingMethod] AS Funding_Source,
    [equipmentType] AS EquipmentTypes,
    [New_LeaseAdministratorIdName] AS LeaseAdmin,
    [oppStatus],
    [distributionmethod] AS DocDistributionMethod,
    [NoOfEnvelopesSent],
    [DocsPendingDate]
  FROM #details
  WHERE DateRangeGroup = 3;--current


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
    [EmailSent],
    1 AS DateRangeGroup INTO #SpectorDailyAdminDataSnapShot
  FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
  WHERE [SnapshotDate] >= @dateFrom
  AND [SnapshotDate] <= @dateTo
  AND DirectoryName IN (SELECT
    username
  FROM #employees)

  INSERT INTO #SpectorDailyAdminDataSnapShot
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
      [EmailSent],
      2 AS DateRangeGroup
    FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
    WHERE [SnapshotDate] >= @dateFrom_last
    AND [SnapshotDate] <= @dateTo_last
    AND DirectoryName IN (SELECT
      username
    FROM #employees)
    UNION ALL

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
      [EmailSent],
      3 AS DateRangeGroup
    FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
    WHERE [SnapshotDate] >= @dateFrom_preyear
    AND [SnapshotDate] <= @dateTo_preyear
    AND DirectoryName IN (SELECT
      username
    FROM #employees)

    UNION ALL

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
      [EmailSent],
      4 AS DateRangeGroup
    FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
    WHERE [SnapshotDate] >= @dateFrom_pre2year
    AND [SnapshotDate] <= @dateTo_pre2year
    AND DirectoryName IN (SELECT
      username
    FROM #employees)



  --evaluation
  IF OBJECT_ID('tempdb..#evaluation') IS NOT NULL
    DROP TABLE #evaluation

  SELECT
    [Rating],
    [EvaluationTypeValue],
    1 AS DateRangeGroup INTO #evaluation
  FROM [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
  WHERE [EvaluateForID] IN (SELECT
    CRMGuid
  FROM #employees)
  AND [ActualCloseDate] >= @dateFrom
  AND [ActualCloseDate] <= @dateTo

  INSERT INTO #evaluation
    SELECT
      [Rating],
      [EvaluationTypeValue],
      2 AS DateRangeGroup
    FROM [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
    WHERE [EvaluateForID] IN (SELECT
      CRMGuid
    FROM #employees)
    AND [ActualCloseDate] >= @dateFrom_last
    AND [ActualCloseDate] <= @dateTo_last
    UNION ALL

    SELECT
      [Rating],
      [EvaluationTypeValue],
      3 AS DateRangeGroup
    FROM [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
    WHERE [EvaluateForID] IN (SELECT
      CRMGuid
    FROM #employees)
    AND [ActualCloseDate] >= @dateFrom_preyear
    AND [ActualCloseDate] <= @dateTo_preyear
    UNION ALL

    SELECT
      [Rating],
      [EvaluationTypeValue],
      4 AS DateRangeGroup
    FROM [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
    WHERE [EvaluateForID] IN (SELECT
      CRMGuid
    FROM #employees)
    AND [ActualCloseDate] >= @dateFrom_pre2year
    AND [ActualCloseDate] <= @dateTo_pre2year


  --2. company docs admin

  IF OBJECT_ID('tempdb..#final') IS NOT NULL
  BEGIN
    DROP TABLE #final
  END;

  --individual.
  WITH accepted_com
  AS (SELECT
    daterangegroup,
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN [leaseAmt]
      ELSE 0
    END) AS [portfolioleaseAmt],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 1
      ELSE 0
    END) AS [portfolioCount],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE [leaseAmt]
    END) AS [oneoffleaseAmt],
    SUM(CASE
      WHEN [FundingMethodValue] = 1 THEN 0
      ELSE 1
    END) AS [oneoffCount],
    SUM([leaseAmt]) AS [leaseAmt],
    SUM(1) AS [totalCount],
    SUM(CASE
      WHEN isTitled = 1 THEN [leaseAmt]
      ELSE 0
    END) AS [TitledleaseAmt],
    SUM(CASE
      WHEN isTitled = 1 THEN 1
      ELSE 0
    END) AS [TitledCount],
    AVG(DATEDIFF(DAY, DocsPendingDate, DocsSent)) AS TimeToSend,
    AVG(DATEDIFF(DAY, DocsSent, DocumentsReceivedDate)) AS TimeToReceive,
    AVG(DATEDIFF(DAY, DocumentsReceivedDate, InitialPurchaseOrderDate)) AS TimeToPO,
    AVG(DATEDIFF(DAY, InitialPurchaseOrderDate, [acceptanceDate])) AS TimeToFund,
    AVG(DATEDIFF(DAY, DocsPendingDate, [acceptanceDate])) AS TotalTime,
    SUM([NoOfEnvelopesSent]) AS DocBuilder,
    SUM(ISNULL(NoOfDocsAdded, 0) + ISNULL(NoOfDocsRemoved, 0)) AS ManuallyDocs

  FROM #details s
  GROUP BY daterangegroup),
  open_com
  AS (SELECT
    daterangegroup,
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN LeaseAmount
      ELSE 0
    END) AS [portfolioLeaseAmount],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 1
      ELSE 0
    END) AS [portfolioCount],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 0
      ELSE LeaseAmount
    END) AS [oneoffLeaseAmount],
    SUM(CASE
      WHEN new_fundingmethod = 1 THEN 0
      ELSE 1
    END) AS [oneoffCount],
    SUM(LeaseAmount) AS LeaseAmount,
    SUM(1) AS TotalCount,
    SUM(CASE
      WHEN isTitled = 1 THEN LeaseAmount
      ELSE 0
    END) AS [TitledLeaseAmount],
    SUM(CASE
      WHEN isTitled = 1 THEN 1
      ELSE 0
    END) AS [TitledCount],
    SUM(CASE
      WHEN New_LeaseAdministratorId IS NULL THEN LeaseAmount
      ELSE 0
    END) AS [UnassignedLeaseAmount],
    SUM(CASE
      WHEN New_LeaseAdministratorId IS NULL THEN 1
      ELSE 0
    END) AS [UnassignedCount],
    SUM(CASE
      WHEN isDocusigned = 1 THEN LeaseAmount
      ELSE 0
    END) AS [DocusignedLeaseAmount],
    SUM(CASE
      WHEN isDocusigned = 1 THEN 1
      ELSE 0
    END) AS [DocusignedCount],
    SUM(CASE
      WHEN statuscode = 9 THEN LeaseAmount
      ELSE 0
    END) AS [ActivatedLeaseAmount],
    SUM(CASE
      WHEN statuscode = 9 THEN 1
      ELSE 0
    END) AS [ActivatedCount],
    AVG(DATEDIFF(DAY, acceptanceDate, GETDATE())) AS ActivatedAvgDays
  FROM #OpenDeals s
  GROUP BY daterangegroup),
  testscore_com
  AS (SELECT
    AVG([MathTest]) AS [MathTest],
    AVG([MathTestAttempt]) AS [MathTestAttempt],
    AVG([ProofReadingTestA]) AS [ProofReadingTestA],
    AVG([ProofReadingTestAAttempt]) AS [ProofReadingTestAAttempt],
    AVG([ProofReadingTestB]) AS [ProofReadingTestB],
    AVG([ProofReadingTestBAttepmt]) AS [ProofReadingTestBAttepmt],
    AVG([TypingTestWPM]) AS [TypingTestWPM],
    AVG([TypingTestAccuracy]) AS [TypingTestAccuracy],
    AVG([TypingTestKeyStrokes]) AS [TypingTestKeyStrokes],
    AVG([BeaconScore]) AS [BeaconScore],
    AVG([FicoScore]) AS [FicoScore],
    3 AS daterangegroup
  FROM [dbo].[KeyStats_Employee_TestScore] t
  WHERE t.[UniqueUserId] IN (SELECT
    [UniqueUserId]
  FROM #employees)),
  evaluation_com
  AS (SELECT
    daterangegroup,
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
  FROM #evaluation
  GROUP BY daterangegroup),
  activity_com
  AS (SELECT
    daterangegroup,
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
  FROM #SpectorDailyAdminDataSnapShot
  GROUP BY daterangegroup)


  SELECT
  DISTINCT
    drg.id AS [index],
    drg.name AS HeaderName,
    acc.[portfolioleaseAmt] AS CompletedPortfolioAmount,
    acc.[portfolioCount] AS CompletedPortfolioCount,
    acc.[oneoffleaseAmt] AS CompletedOneOffAmount,
    acc.[oneoffCount] AS CompletedOneOffCount,
    acc.[leaseAmt] AS CompletedTotalAmount,
    acc.[totalCount] AS CompletedTotalCount,
    acc.[TitledleaseAmt] AS CompletedTitledAmount,
    acc.[TitledCount] AS CompletedTitledCount,
    acc.TimeToSend,
    acc.TimeToReceive,
    acc.TimeToPO,
    acc.TimeToFund,
    acc.TotalTime,
    op.portfolioLeaseAmount AS OpenPortfolioAmount,
    op.portfolioCount AS OpenPortfolioCount,
    op.oneoffLeaseAmount AS OpenOneOffAmount,
    op.oneoffCount AS OpenOneOffCount,
    op.LeaseAmount AS OpenTotalAmount,
    op.TotalCount AS OpenTotalCount,
    op.TitledLeaseAmount AS OpenTitledAmount,
    op.TitledCount AS OpenTitledCount,
    op.UnassignedLeaseAmount AS UnassignedAmount,
    op.UnassignedCount AS UnassignedCount,
    op.DocusignedLeaseAmount AS DocuSignAmount,
    op.DocusignedCount AS DocuSignCount,
    op.ActivatedLeaseAmount AS ActivatedFollowUpAmount,
    op.ActivatedCount AS ActivatedFollowUpCount,
    op.ActivatedAvgDays AS ActivatedAvgDays,
    te.[MathTest] AS MathTest,
    te.[MathTestAttempt],
    te.[ProofReadingTestA] AS NoMatching,
    te.[ProofReadingTestAAttempt],
    te.[ProofReadingTestB] AS WordMatching,
    te.[ProofReadingTestBAttepmt],
    te.[TypingTestWPM] AS TypingSpeed,
    te.[TypingTestAccuracy] AS TypingAccuracy,
    te.[TypingTestKeyStrokes],
    te.[BeaconScore] AS BeaconScore,
    te.[FicoScore] AS FICOScore,
    ev.AvgEvaluationRating,
    ev.AvgEvaluationRatingCount,
    ev.AvgEvaluationRatingExt AS EvalExternal,
    ev.AvgEvaluationRatingCountExt,
    ev.AvgEvaluationRatingIn AS EvalInternal,
    ev.AvgEvaluationRatingCountIn,
    act.totalActiveHours AS TotalActiveHrs,
    act.[Non Work Hours] AS TotalNonWorkHrs,
    act.[WorkHours],
    act.startdateminute,
    act.enddateminute,
    act.[Daily Start] AS AvgDailyStart,
    act.[Daily End] AS AvgDailyEnd,
    act.totalcall AS NoOfTotalCalls,
    act.avgcalls AS NoOfAvgCallsPerDay,
    act.totaldurationmin,
    act.avgCallDuration,
    act.avgcalldurationmin AS AvgCallDurationMin,
    act.totalcallin AS NoOfIncomingCalls,
    act.totalcallout AS NoOfOutgiongCalls,
    act.totalcallint AS NoOfInternalForwardedCalls,
    act.keystroke AS TotalNoOfKeystrokes,
    act.totalemails AS TotalNoOfEmails,
    acc.DocBuilder,
    acc.ManuallyDocs INTO #final
  FROM #DateRangeGroup drg
  LEFT JOIN accepted_com acc
    ON acc.DateRangeGroup = drg.id
  LEFT JOIN open_com op
    ON op.DateRangeGroup = drg.id
  LEFT JOIN testscore_com te
    ON te.DateRangeGroup = drg.id
  LEFT JOIN evaluation_com ev
    ON ev.DateRangeGroup = drg.id
  LEFT JOIN activity_com act
    ON act.DateRangeGroup = drg.id

  DECLARE @em_count AS int
  SELECT
    @em_count = COUNT(uniqueuserid)
  FROM #employees

  SELECT
    *
  FROM #final

  UNION ALL

  SELECT
    --f1.[index] + f2.[index] 
    5 AS [index],
    'Difference' AS HeaderName,
    f1.CompletedPortfolioAmount - f2.CompletedPortfolioAmount,
    f1.CompletedPortfolioCount - f2.CompletedPortfolioCount,
    f1.CompletedOneOffAmount - f2.CompletedOneOffAmount,
    f1.CompletedOneOffCount - f2.CompletedOneOffCount,
    f1.CompletedTotalAmount - f2.CompletedTotalAmount,
    f1.CompletedTotalCount - f2.CompletedTotalCount,
    f1.CompletedTitledAmount - f2.CompletedTitledAmount,
    f1.CompletedTitledCount - f2.CompletedTitledCount,
    f1.TimeToSend - f2.TimeToSend,
    f1.TimeToReceive - f2.TimeToReceive,
    f1.TimeToPO - f2.TimeToPO,
    f1.TimeToFund - f2.TimeToFund,
    f1.TotalTime - f2.TotalTime,
    f1.OpenPortfolioAmount - f2.OpenPortfolioAmount,
    f1.OpenPortfolioCount - f2.OpenPortfolioCount,
    f1.OpenOneOffAmount - f2.OpenOneOffAmount,
    f1.OpenOneOffCount - f2.OpenOneOffCount,
    f1.OpenTotalAmount - f2.OpenTotalAmount,
    f1.OpenTotalCount - f2.OpenTotalCount,
    f1.OpenTitledAmount - f2.OpenTitledAmount,
    f1.OpenTitledCount - f2.OpenTitledCount,
    f1.UnassignedAmount - f2.UnassignedAmount,
    f1.UnassignedCount - f2.UnassignedCount,
    f1.DocuSignAmount - f2.DocuSignAmount,
    f1.DocuSignCount - f2.DocuSignCount,
    f1.ActivatedFollowUpAmount - f2.ActivatedFollowUpAmount,
    f1.ActivatedFollowUpCount - f2.ActivatedFollowUpCount,
    f1.ActivatedAvgDays - f2.ActivatedAvgDays,
    NULL AS [Math Test],
    NULL AS [Math Test Attempt],
    NULL AS [Proof Reading Test A],
    NULL AS [Proof Reading Test A Attempt],
    NULL AS [Proof Reading Test B],
    NULL AS [Proof Reading Test B Attepmt],
    NULL AS [Typing Test - WPM],
    NULL AS [Typing Test - Accuracy],
    NULL AS [TypingTest KeyStrokes],
    NULL AS [Beacon Score],
    NULL AS [Fico Score],
    f1.AvgEvaluationRating - f2.AvgEvaluationRating,
    f1.AvgEvaluationRatingCount - f2.AvgEvaluationRatingCount,
    f1.EvalExternal - f2.EvalExternal,
    f1.AvgEvaluationRatingCountExt - f2.AvgEvaluationRatingCountExt,
    f1.EvalInternal - f2.EvalInternal,
    f1.AvgEvaluationRatingCountIn - f2.AvgEvaluationRatingCountIn,
    f1.TotalActiveHrs - f2.TotalActiveHrs,
    f1.TotalNonWorkHrs - f2.TotalNonWorkHrs,
    f1.WorkHours - f2.WorkHours,
    f1.startdateminute - f2.startdateminute,
    f1.enddateminute - f2.enddateminute,
    CAST(f1.startdateminute - f2.startdateminute AS varchar(10)) + ' min',
    CAST(f1.enddateminute - f2.enddateminute AS varchar(10)) + ' min',
    f1.NoOfTotalCalls - f2.NoOfTotalCalls,
    f1.NoOfAvgCallsPerDay - f2.NoOfAvgCallsPerDay,
    f1.totaldurationmin - f2.totaldurationmin,
    f1.avgCallDuration - f2.avgCallDuration,
    f1.AvgCallDurationMin - f2.AvgCallDurationMin,
    f1.NoOfIncomingCalls - f2.NoOfIncomingCalls,
    f1.NoOfOutgiongCalls - f2.NoOfOutgiongCalls,
    f1.NoOfInternalForwardedCalls - f2.NoOfInternalForwardedCalls,
    f1.TotalNoOfKeystrokes - f2.TotalNoOfKeystrokes,
    f1.TotalNoOfEmails - f2.TotalNoOfEmails,
    f1.ManuallyDocs - f2.ManuallyDocs AS ManuallyDocs,
    f1.DocBuilder - f2.DocBuilder AS DocBuilder

  FROM #final f1
  INNER JOIN #final f2
    ON f1.[index] = 3
    AND f2.[index] = 4
    
     IF @docsAdminID IS NULL
  BEGIN
  
select top 1
        STUFF(( select distinct '; ' + [New_LeaseAdministratorIdName]

                                    FROM #details WHERE DateRangeGroup = 3

                    FOR XML PATH('')),1,1,'')

                     AS leaseadmin 
 FROM #details WHERE DateRangeGroup = 3
 end

END
GO
