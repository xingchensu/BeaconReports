SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/11/2015
-- Description:	To load the drill down stats for Web Help Desk

-- Test: [dbo].[KeyStats_WHD_LoadDrillDownStats] '01/01/2015', '01/06/2016', 'ytd', 291159, 1
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_WHD_LoadDrillDownStats]
    @BEGINDATE AS DATETIME ,
    @ENDDATE AS DATETIME ,
    @dateFormate AS VARCHAR(10) ,
    @UniqueID AS INT = NULL ,
    @IsMisc AS BIT = NULL ,
    @Location AS VARCHAR(50) = NULL ,
    @Status AS VARCHAR(50) = NULL ,
    @RequestType AS VARCHAR(50) = NULL ,
    @ClientName AS VARCHAR(50) = NULL
AS 
    BEGIN
        SET NOCOUNT ON;
		
		-- Convert date formate to lower case
		SET @dateFormate = LOWER(@dateFormate);

		-- Get the Top 5 Problem Types & assign it to variables
        IF OBJECT_ID('tempdb..#TopCategory') IS NOT NULL 
            BEGIN  
                DROP TABLE #TopCategory
            END
            
        SELECT TOP 5
                ROW_NUMBER() OVER ( ORDER BY COUNT(*) DESC ) AS [RowNo] ,
                p.ProblemType ,
                COUNT(*) AS [COUNT]
        INTO    #TopCategory
        FROM    [dbo].[KeyStats_WHD_OpenTickets_Pipeline] p
        WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
                AND p.Tech_UniqueUserId = ISNULL(@UniqueID,
                                                 p.Tech_UniqueUserId)
                AND p.[Tech_IsMisc] = ISNULL(@IsMisc, p.[Tech_IsMisc])
                AND p.LocationName = ISNULL(@Location,
                                                   p.LocationName)
                AND p.StatusType = ISNULL(@Status, p.StatusType)
                AND p.ProblemType = ISNULL(@RequestType,
                                                  p.ProblemType)
                AND p.ClientName = ISNULL(@ClientName,
                                                 p.ClientName)
        GROUP BY p.ProblemType;

        DECLARE @ProblemType1 AS VARCHAR(50);
        DECLARE @ProblemType2 AS VARCHAR(50);
        DECLARE @ProblemType3 AS VARCHAR(50);
        DECLARE @ProblemType4 AS VARCHAR(50);
        DECLARE @ProblemType5 AS VARCHAR(50);

        SELECT  @ProblemType1 = t.ProblemType
        FROM    #TopCategory t
        WHERE   t.RowNo = 1;
        SELECT  @ProblemType2 = t.ProblemType
        FROM    #TopCategory t
        WHERE   t.RowNo = 2;
        SELECT  @ProblemType3 = t.ProblemType
        FROM    #TopCategory t
        WHERE   t.RowNo = 3;
        SELECT  @ProblemType4 = t.ProblemType
        FROM    #TopCategory t
        WHERE   t.RowNo = 4;
        SELECT  @ProblemType5 = t.ProblemType
        FROM    #TopCategory t
        WHERE   t.RowNo = 5;

		-- Get Individual List
        IF OBJECT_ID('tempdb..#Individuals') IS NOT NULL 
            BEGIN  
                DROP TABLE #Individuals
            END

		
        SELECT  e.* ,
                e.FName + ' ' + e.LName AS [fullname] ,
                r.IsMiscellaneous
        INTO    #Individuals
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID
        WHERE   c.CategoryID = 9

		-- Convert date formate to lower case
        SET @dateFormate = @dateFormate;

        DECLARE @FName AS VARCHAR(20);
        DECLARE @LName AS VARCHAR(20);
        DECLARE @UserName AS VARCHAR(20);

        SELECT  @FName = e.fname ,
                @LName = e.lname ,
                @UserName = e.username
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID
        WHERE   c.CategoryID = 9
                AND e.UniqueUserId = @UniqueID
                AND ISNULL(@IsMisc, 0) <> 1;
		

	-- === DATE RANGE VARIABLES : START =====
        DECLARE @TwoYearsBeforeFrom AS DATE;
        SET @TwoYearsBeforeFrom = CAST(CAST(YEAR(@BEGINDATE) - 2 AS VARCHAR(20))
            + '/01/01' AS DATE);
        DECLARE @TwoYearsBeforeTo AS DATE;
        SET @TwoYearsBeforeTo = CAST(CAST(YEAR(@BEGINDATE) - 2 AS VARCHAR(20))
            + '/12/31' AS DATE);

        DECLARE @LastYearFrom AS DATE;
        SET @LastYearFrom = CAST(CAST(YEAR(@BEGINDATE) - 1 AS VARCHAR(20))
            + '/01/01' AS DATE);
        DECLARE @LastYearTo AS DATE;
        SET @LastYearTo = CAST(CAST(YEAR(@BEGINDATE) - 1 AS VARCHAR(20))
            + '/12/31' AS DATE);

        DECLARE @LastYearSamePeriodFrom AS DATE;
        SET @LastYearSamePeriodFrom = CAST(( YEAR(@BEGINDATE) - 1 ) AS VARCHAR(20))
            + '/' + CAST(MONTH(@BEGINDATE) AS VARCHAR(20)) + '/'
            + CAST(DAY(@BEGINDATE) AS VARCHAR(20));
        DECLARE @LastYearSamePeriodTo AS DATE;
        SET @LastYearSamePeriodTo = CAST(( YEAR(@ENDDATE) - 1 ) AS VARCHAR(20))
            + '/' + CAST(MONTH(@ENDDATE) AS VARCHAR(20)) + '/'
            + CAST(DAY(@ENDDATE) AS VARCHAR(20));

        IF OBJECT_ID('tempdb..#DrillDownStats') IS NOT NULL 
            BEGIN  
                DROP TABLE #DrillDownStats
            END

        CREATE TABLE #DrillDownStats
            (
              CSSINDEX INT ,
              current_index INT ,
              HeaderName VARCHAR(50) ,
              HeaderToolTip VARCHAR(100) ,
              HeaderLink VARCHAR(MAX) ,
              StartDate VARCHAR(50) ,
              TableClass VARCHAR(20) ,
              UniqueUserId INT ,
              Username VARCHAR(20) ,
              FromDate DATETIME ,
              ToDate DATETIME ,

			  -- COMPLEATED TICKET STATS
              CompletedWHDTktCount INT ,
              PercTktSolved DECIMAL(18, 2) ,
              ClosedUnassignedTime DECIMAL(18, 2) ,
              AvgFirstRespTime DECIMAL(18, 2) ,
              AvgTotalTimeOpen DECIMAL(18, 2) ,
              TotalWorkTime DECIMAL(18, 2) ,
              AvgTotalWorkTime DECIMAL(18, 2) ,
              AvgNoPeopleCCperTicket DECIMAL(18, 2) ,
              ReaasignmentsCount INT ,
              AvgNoReassignmentsPerTicket DECIMAL(18, 2) ,
              Level3AlertsCount INT ,
              AvgNoLevel3AlertsPerTicket DECIMAL(18, 2) ,
              TotalNoTechNotes INT ,
              AvgNoTechNotesPerTicket DECIMAL(18, 2) ,
              ClosedReopenTicketCount DECIMAL(18, 2) ,

              -- EVALUATION STATS
              EvaluationsNo DECIMAL(18, 2) ,
              EvaluationRating DECIMAL(18, 2) ,

              -- OPEN TICKET STATS
              OpenTickets INT ,
              OpenPastDue INT ,
              OpenUnassigned INT ,
              OpenUnassignedTime DECIMAL(18, 2) ,
              OpenAvgFirstRespTime DECIMAL(18, 2) ,
              OpenAvgTotalTimeOpen DECIMAL(18, 2) ,
              OpenTotalWorkTime DECIMAL(18, 2) ,
              OpenAvgTotalWorkTime DECIMAL(18, 2) ,
              OpenAvgCntPeopleCCperTicket DECIMAL(18, 2) ,
              OpenReassignment INT ,
              OpenAvgReassignPerTicket DECIMAL(18, 2) ,
              OpenLevel3Alerts INT ,
              OpenAvgCountOfLevel3AlertsPerTicket DECIMAL(18, 2) ,
              OpenTotalTechNotes INT ,
              OpenAvgCountOfTechNotesPerTicket DECIMAL(18, 2) ,
              OpenReopenTicketCount DECIMAL(18, 2) ,

              -- OPEN TICKET - BY REQUEST TYPE
              ProblemType1 INT ,
              ProblemType2 INT ,
              ProblemType3 INT ,
              ProblemType4 INT ,
              ProblemType5 INT ,
              ProblemTypeOthers INT ,
              ProblemTypeTotal INT ,

			  -- ACTIVITY
              NoOfTotalCalls INT ,
              NoOfIncomingCalls INT ,
              NoOfOutgiongCalls INT ,
              NoOfInternalForwardedCalls INT ,
              NoOfAvgCallsPerDay INT ,
              AvgCallDurationMin DECIMAL(10, 2) ,
              AvgDailyStart VARCHAR(20) ,
              AvgDailyEnd VARCHAR(20) ,
              TotalActiveHrs DECIMAL(10, 2) ,
              TotalNonWorkHrs DECIMAL(10, 2) ,
              TotalNoOfKeystrokes INT ,
              TotalNoOfEmails INT
            );

        DECLARE @counter AS INT = 1;
        DECLARE @fromDate AS DATE = NULL;
        DECLARE @toDate AS DATE = NULL;
        DECLARE @header AS VARCHAR(MAX) = NULL;
        DECLARE @DrillDownIndividual AS VARCHAR(50);
        DECLARE @headerlink AS VARCHAR(MAX);

        IF ISNULL(@IsMisc, 0) = 0 
            BEGIN
                SET @DrillDownIndividual = dbo.ufnGetShortName(@FName, @LName,
                                                              10);
                SET @headerlink = '~/EmployeeMetrics/WHDStats.aspx?v=IDDC&d='
                    + @dateFormate + '&u=' +  + CONVERT(VARCHAR(25), @UniqueID);
            END
        ELSE 
            BEGIN
                SET @DrillDownIndividual = 'Misc.';
                SET @headerlink = '~/EmployeeMetrics/WHDStats.aspx?v=IDDC&d='
                    + @dateFormate + '&u=misc';
            END

        WHILE @counter < 5 
            BEGIN
				
                SET @fromDate = CASE @counter
                                  WHEN 1 THEN @TwoYearsBeforeFrom
                                  WHEN 2 THEN @LastYearFrom
                                  WHEN 3 THEN @BEGINDATE
                                  WHEN 4 THEN @LastYearSamePeriodFrom
                                  ELSE NULL
                                END;

                SET @toDate = CASE @counter
                                WHEN 1 THEN @TwoYearsBeforeTo
                                WHEN 2 THEN @LastYearTo
                                WHEN 3 THEN @ENDDATE
                                WHEN 4 THEN @LastYearSamePeriodTo
                                ELSE NULL
                              END;
            
                SET @header = CASE @counter
                                WHEN 1
                                THEN @DrillDownIndividual + '<br/>'
                                     + CAST(YEAR(@TwoYearsBeforeTo) AS VARCHAR(MAX))
                                WHEN 2
                                THEN @DrillDownIndividual + '<br/>'
                                     + CAST(YEAR(@LastYearTo) AS VARCHAR(MAX))
                                WHEN 3
                                THEN @DrillDownIndividual + '<br/>'
                                     + CONVERT(VARCHAR(10), @BEGINDATE, 1)
                                     + ' - ' + CONVERT(VARCHAR(10), @ENDDATE, 1)
                                WHEN 4
                                THEN @DrillDownIndividual + '<br/>'
                                     + CONVERT(VARCHAR(10), @LastYearSamePeriodFrom, 1)
                                     + ' - '
                                     + CONVERT(VARCHAR(10), @LastYearSamePeriodTo, 1)
                                ELSE NULL
                              END;

                INSERT  INTO #DrillDownStats
                        ( CSSINDEX ,
                          HeaderName ,
                          HeaderLink ,
                          UniqueUserId ,
                          Username ,
                          FromDate ,
                          ToDate ,
						  
						  -- COMPLEATED TICKET STATS
                          CompletedWHDTktCount ,
                          PercTktSolved ,
                          ClosedUnassignedTime ,
                          AvgFirstRespTime ,
                          AvgTotalTimeOpen ,
                          TotalWorkTime ,
                          AvgTotalWorkTime ,
                          AvgNoPeopleCCperTicket ,
                          ReaasignmentsCount ,
                          AvgNoReassignmentsPerTicket ,
                          Level3AlertsCount ,
                          AvgNoLevel3AlertsPerTicket ,
                          TotalNoTechNotes ,
                          AvgNoTechNotesPerTicket ,
                          ClosedReopenTicketCount ,

						  -- EVALUATION STATS
                          EvaluationsNo ,
                          EvaluationRating ,

						  -- OPEN TICKET STATS
                          OpenTickets ,
                          OpenPastDue ,
                          OpenUnassigned ,
                          OpenUnassignedTime ,
                          OpenAvgFirstRespTime ,
                          OpenAvgTotalTimeOpen ,
                          OpenTotalWorkTime ,
                          OpenAvgTotalWorkTime ,
                          OpenAvgCntPeopleCCperTicket ,
                          OpenReassignment ,
                          OpenAvgReassignPerTicket ,
                          OpenLevel3Alerts ,
                          OpenAvgCountOfLevel3AlertsPerTicket ,
                          OpenTotalTechNotes ,
                          OpenAvgCountOfTechNotesPerTicket ,
                          OpenReopenTicketCount ,

						  -- OPEN TICKET - BY REQUEST TYPE
                          ProblemType1 ,
                          ProblemType2 ,
                          ProblemType3 ,
                          ProblemType4 ,
                          ProblemType5 ,
                          ProblemTypeOthers ,
                          ProblemTypeTotal ,
                  
						  -- ACTIVITY
                          NoOfTotalCalls ,
                          NoOfIncomingCalls ,
                          NoOfOutgiongCalls ,
                          NoOfInternalForwardedCalls ,
                          NoOfAvgCallsPerDay ,
                          AvgCallDurationMin ,
                          AvgDailyStart ,
                          AvgDailyEnd ,
                          TotalActiveHrs ,
                          TotalNonWorkHrs ,
                          TotalNoOfKeystrokes ,
                          TotalNoOfEmails
                        )
                        SELECT  *
                        FROM    ( SELECT    @counter AS [CSSINDEX] ,
                                            @header AS [HeaderName] ,
                                            @headerlink AS [HeaderLink] ,
                                            @UniqueID AS [UniqueUserId] ,
                                            @USERNAME AS [Username] ,
                                            @fromDate AS [FromDate] ,
                                            @toDate AS [ToDate] ,
								
								-- COMPLEATED TICKET STATS
                                            COUNT(*) AS [CompletedWHDTktCount] , -- CompletedWHDTktCount
                                            [dbo].[ufnGetPercOfTicketSolved](@fromDate,
                                                              @toDate, NULL,
                                                              NULL) AS [PercTktSolved] , -- PercTktSolved
                                            SUM(UnassignedTime) AS [ClosedUnassignedTime] , -- ClosedUnassignedTime
                                            AVG(FirstResponseTime) AS [AvgFirstRespTime] , -- AvgFirstRespTime
                                            AVG(TotalTimeOpen) AS [AvgTotalTimeOpen] , -- AvgTotalTimeOpen
                                            SUM(TotalTimeOpen) AS [TotalWorkTime] , -- TotalWorkTime
                                            AVG(TotalTimeWorked) AS [AvgTotalWorkTime] , -- AvgTotalWorkTime
                                            AVG(PeopleCcPerTicket) AS [AvgNoPeopleCCperTicket] , -- AvgNoPeopleCCperTicket
                                            SUM(ReassignmentsCount) AS [ReaasignmentsCount] , -- ReaasignmentsCount
                                            AVG(ReassignmentsCount) AS [AvgNoReassignmentsPerTicket] , -- AvgNoReassignmentsPerTicket
                                            SUM(PastDueAlerts) AS [Level3AlertsCount] , -- Level3AlertsCount
                                            AVG(PastDueAlerts) AS [AvgNoLevel3AlertsPerTicket] , -- AvgNoLevel3AlertsPerTicket
                                            SUM(TotalNoofTechNotes) AS [TotalNoTechNotes] , -- TotalNoTechNotes
                                            AVG(TotalNoofTechNotes) AS [AvgNoTechNotesPerTicket] ,-- AvgNoTechNotesPerTicket
                                            SUM(ReopenCounter) AS [ClosedReopenTicketCount] -- ClosedReopenTicketCount
                                  FROM      [dbo].[KeyStats_WHD_ClosedTickets_Snapshot] t
                                  WHERE     CAST(t.[ClosedDate] AS DATE) >= @fromDate
                                            AND CAST(t.[ClosedDate] AS DATE) <= @toDate
                                            AND t.Tech_UniqueUserId = ISNULL(@UniqueID,
                                                              t.Tech_UniqueUserId)
                                            AND t.[Tech_IsMisc] = ISNULL(@IsMisc,
                                                              t.[Tech_IsMisc])
                                            AND t.LocationName = ISNULL(@Location,
                                                              t.LocationName)
                                            AND t.StatusType = ISNULL(@Status,
                                                              t.StatusType)
                                            AND t.ProblemType = ISNULL(@RequestType,
                                                              t.ProblemType)
                                            AND t.ClientName = ISNULL(@ClientName,
                                                              t.ClientName)
                                ) compleated
                                LEFT JOIN ( SELECT -- EVALUATION STATS
                                                    COUNT(*) AS [EvaluationsNo] , -- EvaluationsNo
                                                    AVG(Rating) AS [EvaluationRating] -- EvaluationRating
                                            FROM    #Individuals i
                                                    LEFT JOIN dbo.KeyStats_EmployeeEvaluation_DailySnapShot e ON e.[EvaluateForUsername] = i.username
                                            WHERE   CAST(e.[ActualCloseDate] AS DATE) >= @fromDate
                                                    AND CAST(e.[ActualCloseDate] AS DATE) <= @toDate
                                                    AND i.UniqueUserId = ISNULL(@UniqueID,
                                                              i.UniqueUserId)
                                                    AND i.IsMiscellaneous = ISNULL(@IsMisc,
                                                              i.IsMiscellaneous)
                                          ) evaluation ON 1 = 1
                                LEFT JOIN ( SELECT  -- OPEN TICKET STATS
                                                    COUNT(*) AS [OpenTickets] , -- OpenTickets ,
                                                    COUNT(CASE
                                                              WHEN IsPastDue = 1
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [OpenPastDue] , -- OpenPastDue
                                                    COUNT(CASE
                                                              WHEN AssignedTech = 'unassigned'
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [OpenUnassigned] , -- OpenUnassigned ,
                                                    SUM(CASE WHEN AssignedTech = 'unassigned'
                                                             THEN TotalTimeOpen
                                                             ELSE 0
                                                        END) AS [OpenUnassignedTime] , -- OpenUnassignedTime ,
                                                    AVG(FirstResponseTime) AS [OpenAvgFirstRespTime] , -- OpenAvgFirstRespTime
                                                    AVG(TotalTimeOpen) AS [OpenAvgTotalTimeOpen] , -- OpenAvgTotalTimeOpen
                                                    SUM(TotalTimeOpen) AS [OpenTotalWorkTime] , -- OpenTotalWorkTime
                                                    AVG(TotalTimeWorked) AS [OpenAvgTotalWorkTime] , -- OpenAvgTotalWorkTime
                                                    AVG(PeopleCcPerTicket) AS [OpenAvgCntPeopleCCperTicket] , -- OpenAvgCntPeopleCCperTicket
                                                    SUM(ReassignmentsCount) AS [OpenReassignment] , -- OpenReassignment
                                                    AVG(ReassignmentsCount) AS [OpenAvgReassignPerTicket] , -- OpenAvgReassignPerTicket
                                                    SUM(PastDueAlerts) AS [OpenLevel3Alerts] , -- OpenLevel3Alerts
                                                    AVG(PastDueAlerts) AS [OpenAvgCountOfLevel3AlertsPerTicket] , -- OpenAvgCountOfLevel3AlertsPerTicket
                                                    SUM(TotalNoofTechNotes) AS [OpenTotalTechNotes] , -- OpenTotalTechNotes
                                                    AVG(TotalNoofTechNotes) AS [OpenAvgCountOfTechNotesPerTicket] ,-- OpenAvgCountOfTechNotesPerTicket
                                                    SUM(ReopenCounter) AS [OpenReopenTicketCount] ,-- OpenReopenTicketCount

													-- OPEN TICKET - BY REQUEST TYPE
                                                    COUNT(CASE
                                                              WHEN p.ProblemType = @ProblemType1
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemType1] ,-- ProblemType1
                                                    COUNT(CASE
                                                              WHEN p.ProblemType = @ProblemType2
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemType2] ,-- ProblemType2
                                                    COUNT(CASE
                                                              WHEN p.ProblemType = @ProblemType3
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemType3] ,-- ProblemType3
                                                    COUNT(CASE
                                                              WHEN p.ProblemType = @ProblemType4
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemType4] ,-- ProblemType4
                                                    COUNT(CASE
                                                              WHEN p.ProblemType = @ProblemType5
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemType5] ,-- ProblemType5
                                                    COUNT(CASE
                                                              WHEN p.ProblemType NOT IN (
                                                              @ProblemType1,
                                                              @ProblemType2,
                                                              @ProblemType3,
                                                              @ProblemType4,
                                                              @ProblemType5 )
                                                              THEN 1
                                                              ELSE NULL
                                                          END) AS [ProblemTypeOthers] ,-- ProblemTypeOthers
                                                    COUNT(p.ProblemType) AS [ProblemTypeTotal] -- ProblemTypeTotal
                                            FROM    [dbo].[KeyStats_WHD_OpenTickets_Pipeline] p
                                            WHERE   CAST(p.SnapshotDate AS DATE) = @toDate
                                                    AND p.Tech_UniqueUserId = ISNULL(@UniqueID,
                                                              p.Tech_UniqueUserId)
                                                    AND p.[Tech_IsMisc] = ISNULL(@IsMisc,
                                                              p.[Tech_IsMisc])
                                                    AND p.LocationName = ISNULL(@Location,
                                                              p.LocationName)
                                                    AND p.StatusType = ISNULL(@Status,
                                                              p.StatusType)
                                                    AND p.ProblemType = ISNULL(@RequestType,
                                                              p.ProblemType)
                                                    AND p.ClientName = ISNULL(@ClientName,
                                                              p.ClientName)
                                          ) openTickets ON 1 = 1
                                LEFT JOIN ( SELECT -- ACTIVITY
                                            SUM([PhoneCalls]) AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                            SUM([TotalInboundCalls]) AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                            SUM([TotalOutboundCalls]) AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                            SUM([TotalForwardCalls])
                                            + SUM([TotalInternalCalls]) AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                            CASE WHEN SUM([PhoneCalls]) > 0
                                                 THEN SUM([CallDuration])
                                                      / SUM([PhoneCalls])
                                                 ELSE NULL
                                            END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                            CASE WHEN SUM([PhoneCalls]) > 0
                                                 THEN SUM([CallDuration])
                                                      / SUM([PhoneCalls]) * 60
                                                 ELSE NULL
                                            END AS [AvgCallDurationMin] , -- AvgCallDurationMin
                                            ISNULL(CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                                   / 60) + ':'
                                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(a.[DailyStartMin])
                                                              % 60)) = 1
                                                          THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(a.[DailyStartMin])
                                                              % 60)
                                                          ELSE CONVERT(VARCHAR(10), AVG(a.[DailyStartMin])
                                                              % 60)
                                                     END, 0) AS [AvgDailyStart] ,
                                            ISNULL(CONVERT(VARCHAR(10), AVG(a.[DailyEndMin])
                                                   / 60) + ':'
                                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(a.[DailyEndMin])
                                                              % 60)) = 1
                                                          THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(a.[DailyEndMin])
                                                              % 60)
                                                          ELSE CONVERT(VARCHAR(10), AVG(a.[DailyEndMin])
                                                              % 60)
                                                     END, 0) AS [AvgDailyEnd] ,
                                            SUM(a.[TotalActiveHr]) AS [TotalActiveHrs] , -- TotalActiveHrs
                                            SUM(a.[NonWorkHours]) AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                            SUM([KeyStrokes]) AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                            SUM([EmailSent]) AS [TotalNoOfEmails] -- TotalNoOfEmails
                                    FROM    #Individuals i
                                            LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON a.[DirectoryName] = i.username
                                    WHERE   CAST(a.[SnapshotDate] AS DATE) >= @fromDate
                                            AND CAST(a.[SnapshotDate] AS DATE) <= @toDate
                                            AND i.UniqueUserId = ISNULL(@UniqueID,
                                                              i.UniqueUserId)
                                            AND i.IsMiscellaneous = ISNULL(@IsMisc,
                                                              i.IsMiscellaneous)
                                          ) activity ON 1 = 1

                SET @counter = @counter + 1;
            END
  
		-- Calculate the difference column
		INSERT  INTO #DrillDownStats
        ( CSSINDEX ,
          HeaderName ,
						 
		  -- COMPLEATED TICKET STATS
          CompletedWHDTktCount ,
          PercTktSolved ,
          ClosedUnassignedTime ,
          AvgFirstRespTime ,
          AvgTotalTimeOpen ,
          TotalWorkTime ,
          AvgTotalWorkTime ,
          AvgNoPeopleCCperTicket ,
          ReaasignmentsCount ,
          AvgNoReassignmentsPerTicket ,
          Level3AlertsCount ,
          AvgNoLevel3AlertsPerTicket ,
          TotalNoTechNotes ,
          AvgNoTechNotesPerTicket ,
          ClosedReopenTicketCount ,

	      -- EVALUATION STATS
          EvaluationsNo ,
          EvaluationRating ,

		  -- OPEN TICKET STATS
          OpenTickets ,
          OpenPastDue ,
          OpenUnassigned ,
          OpenUnassignedTime ,
          OpenAvgFirstRespTime ,
          OpenAvgTotalTimeOpen ,
          OpenTotalWorkTime ,
          OpenAvgTotalWorkTime ,
          OpenAvgCntPeopleCCperTicket ,
          OpenReassignment ,
          OpenAvgReassignPerTicket ,
          OpenLevel3Alerts ,
          OpenAvgCountOfLevel3AlertsPerTicket ,
          OpenTotalTechNotes ,
          OpenAvgCountOfTechNotesPerTicket ,
          OpenReopenTicketCount ,

		  -- OPEN TICKET - BY REQUEST TYPE
          ProblemType1 ,
          ProblemType2 ,
          ProblemType3 ,
          ProblemType4 ,
          ProblemType5 ,
          ProblemTypeOthers ,
          ProblemTypeTotal ,

		  -- ACTIVITY
          NoOfTotalCalls ,
          NoOfIncomingCalls ,
          NoOfOutgiongCalls ,
          NoOfInternalForwardedCalls ,
          NoOfAvgCallsPerDay ,
          AvgCallDurationMin ,
          AvgDailyStart ,
          AvgDailyEnd ,
          TotalActiveHrs ,
          TotalNonWorkHrs ,
          TotalNoOfKeystrokes ,
          TotalNoOfEmails
                        
        )
        SELECT  5 AS [CSSINDEX] ,
                'Difference' AS [HeaderName] ,

				-- COMPLEATED TICKET STATS
                ISNULL(t1.CompletedWHDTktCount, 0)
                - ISNULL(t2.CompletedWHDTktCount, 0) ,
                ISNULL(t1.PercTktSolved, 0) - ISNULL(t2.PercTktSolved, 0) ,
                ISNULL(t1.ClosedUnassignedTime, 0)
                - ISNULL(t2.ClosedUnassignedTime, 0) ,
                ISNULL(t1.AvgFirstRespTime, 0) - ISNULL(t2.AvgFirstRespTime, 0) ,
                ISNULL(t1.AvgTotalTimeOpen, 0) - ISNULL(t2.AvgTotalTimeOpen, 0) ,
                ISNULL(t1.TotalWorkTime, 0) - ISNULL(t2.TotalWorkTime, 0) ,
                ISNULL(t1.AvgTotalWorkTime, 0) - ISNULL(t2.AvgTotalWorkTime, 0) ,
                ISNULL(t1.AvgNoPeopleCCperTicket, 0)
                - ISNULL(t2.AvgNoPeopleCCperTicket, 0) ,
                ISNULL(t1.ReaasignmentsCount, 0)
                - ISNULL(t2.ReaasignmentsCount, 0) ,
                ISNULL(t1.AvgNoReassignmentsPerTicket, 0)
                - ISNULL(t2.AvgNoReassignmentsPerTicket, 0) ,
                ISNULL(t1.Level3AlertsCount, 0) - ISNULL(t2.Level3AlertsCount,
                                                         0) ,
                ISNULL(t1.AvgNoLevel3AlertsPerTicket, 0)
                - ISNULL(t2.AvgNoLevel3AlertsPerTicket, 0) ,
                ISNULL(t1.TotalNoTechNotes, 0) - ISNULL(t2.TotalNoTechNotes, 0) ,
                ISNULL(t1.AvgNoTechNotesPerTicket, 0)
                - ISNULL(t2.AvgNoTechNotesPerTicket, 0) ,
                ISNULL(t1.ClosedReopenTicketCount, 0)
                - ISNULL(t2.ClosedReopenTicketCount, 0) ,

				---- EVALUATION STATS
                ISNULL(t1.EvaluationsNo, 0) - ISNULL(t2.EvaluationsNo, 0) AS EvaluationsNo ,
                ISNULL(t1.EvaluationRating, 0) - ISNULL(t2.EvaluationRating, 0) AS EvaluationRating ,

				-- OPEN TICKET STATS
                ISNULL(t1.OpenTickets, 0) - ISNULL(t2.OpenTickets, 0) AS OpenTickets ,
                ISNULL(t1.OpenPastDue, 0) - ISNULL(t2.OpenPastDue, 0) AS OpenPastDue ,
                ISNULL(t1.OpenUnassigned, 0) - ISNULL(t2.OpenUnassigned, 0) AS OpenUnassigned ,
                ISNULL(t1.OpenUnassignedTime, 0)
                - ISNULL(t2.OpenUnassignedTime, 0) AS OpenUnassignedTime ,
                ISNULL(t1.OpenAvgFirstRespTime, 0)
                - ISNULL(t2.OpenAvgFirstRespTime, 0) AS OpenAvgFirstRespTime ,
                ISNULL(t1.OpenAvgTotalTimeOpen, 0)
                - ISNULL(t2.OpenAvgTotalTimeOpen, 0) AS OpenAvgTotalTimeOpen ,
                ISNULL(t1.OpenTotalWorkTime, 0) - ISNULL(t2.OpenTotalWorkTime,
                                                         0) AS OpenTotalWorkTime ,
                ISNULL(t1.OpenAvgTotalWorkTime, 0)
                - ISNULL(t2.OpenAvgTotalWorkTime, 0) AS OpenAvgTotalWorkTime ,
                ISNULL(t1.OpenAvgCntPeopleCCperTicket, 0)
                - ISNULL(t2.OpenAvgCntPeopleCCperTicket, 0) AS OpenAvgCntPeopleCCperTicket ,
                ISNULL(t1.OpenReassignment, 0) - ISNULL(t2.OpenReassignment, 0) AS OpenReassignment ,
                ISNULL(t1.OpenAvgReassignPerTicket, 0)
                - ISNULL(t2.OpenAvgReassignPerTicket, 0) AS OpenAvgReassignPerTicket ,
                ISNULL(t1.OpenLevel3Alerts, 0) - ISNULL(t2.OpenLevel3Alerts, 0) AS OpenLevel3Alerts ,
                ISNULL(t1.OpenAvgCountOfLevel3AlertsPerTicket, 0)
                - ISNULL(t2.OpenAvgCountOfLevel3AlertsPerTicket, 0) AS OpenAvgCountOfLevel3AlertsPerTicket ,
                ISNULL(t1.OpenTotalTechNotes, 0)
                - ISNULL(t2.OpenTotalTechNotes, 0) AS OpenTotalTechNotes ,
                ISNULL(t1.OpenAvgCountOfTechNotesPerTicket, 0)
                - ISNULL(t2.OpenAvgCountOfTechNotesPerTicket, 0) AS OpenAvgCountOfTechNotesPerTicket ,
                ISNULL(t1.OpenReopenTicketCount, 0)
                - ISNULL(t2.OpenReopenTicketCount, 0) AS OpenReopenTicketCount ,

				-- OPEN TICKET - BY REQUEST TYPE
                ISNULL(t1.ProblemType1, 0) - ISNULL(t2.ProblemType1, 0) AS ProblemType1 ,
                ISNULL(t1.ProblemType2, 0) - ISNULL(t2.ProblemType2, 0) AS ProblemType2 ,
                ISNULL(t1.ProblemType3, 0) - ISNULL(t2.ProblemType3, 0) AS ProblemType3 ,
                ISNULL(t1.ProblemType4, 0) - ISNULL(t2.ProblemType4, 0) AS ProblemType4 ,
                ISNULL(t1.ProblemType5, 0) - ISNULL(t2.ProblemType5, 0) AS ProblemType5 ,
                ISNULL(t1.ProblemTypeOthers, 0) - ISNULL(t2.ProblemTypeOthers,
                                                         0) AS ProblemTypeOthers ,
                ISNULL(t1.ProblemTypeTotal, 0) - ISNULL(t2.ProblemTypeTotal, 0) AS ProblemTypeTotal ,

				-- ACTIVITY
                ISNULL(t1.NoOfTotalCalls, 0) - ISNULL(t2.NoOfTotalCalls, 0) AS NoOfTotalCalls ,
                ISNULL(t1.NoOfIncomingCalls, 0) - ISNULL(t2.NoOfIncomingCalls,
                                                         0) AS NoOfIncomingCalls ,
                ISNULL(t1.NoOfOutgiongCalls, 0) - ISNULL(t2.NoOfOutgiongCalls,
                                                         0) AS NoOfOutgiongCalls ,
                ISNULL(t1.NoOfInternalForwardedCalls, 0)
                - ISNULL(t2.NoOfInternalForwardedCalls, 0) AS NoOfInternalForwardedCalls ,
                ISNULL(t1.NoOfAvgCallsPerDay, 0)
                - ISNULL(t2.NoOfAvgCallsPerDay, 0) AS NoOfAvgCallsPerDay ,
                ISNULL(t1.AvgCallDurationMin, 0)
                - ISNULL(t2.AvgCallDurationMin, 0) AS AvgCallDurationMin ,
                '-' AS AvgDailyStart ,
                '-' AS AvgDailyEnd ,
                ISNULL(t1.TotalActiveHrs, 0) - ISNULL(t2.TotalActiveHrs, 0) AS TotalActiveHrs ,
                ISNULL(t1.TotalNonWorkHrs, 0) - ISNULL(t2.TotalNonWorkHrs, 0) AS TotalNonWorkHrs ,
                ISNULL(t1.TotalNoOfKeystrokes, 0)
                - ISNULL(t2.TotalNoOfKeystrokes, 0) AS TotalNoOfKeystrokes ,
                ISNULL(t1.TotalNoOfEmails, 0) - ISNULL(t2.TotalNoOfEmails, 0) AS TotalNoOfEmails
        FROM    #DrillDownStats t1 ,
                #DrillDownStats t2
        WHERE   t1.[CSSINDEX] = 3
                AND t2.[CSSINDEX] = 4;
		          
        SELECT  *
        FROM    #DrillDownStats;

        SELECT  *
        FROM    #TopCategory;
    END
GO
