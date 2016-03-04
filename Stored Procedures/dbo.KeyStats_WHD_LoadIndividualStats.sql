SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/15/2015
-- Description:	To load the individual stats for Web Help Desk

-- Test: [dbo].[KeyStats_WHD_LoadIndividualStats] '01/01/2015', '12/15/2015', 'ytd'
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_WHD_LoadIndividualStats]
    @BEGINDATE AS DATE ,
    @ENDDATE AS DATE ,
    @dateFormate AS VARCHAR(10) ,
    @IsMisc AS BIT = NULL ,
    @UniqueID AS INT = NULL ,
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

		-- Convert date formate to lower case
        SET @dateFormate = @dateFormate;

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

		-- Get the count of all emnployees
        DECLARE @IndividualCount AS INT = 0;
        SELECT  @IndividualCount = COUNT(*)
        FROM    #Individuals

        IF OBJECT_ID('tempdb..#IndividualStats') IS NOT NULL 
            BEGIN  
                DROP TABLE #IndividualStats
            END

        CREATE TABLE #IndividualStats
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
              TotalNoOfEmails INT ,

              -- SCORE
              NoMatching INT ,
              NoAccuracy DECIMAL(10, 2) ,
              WordMatching INT ,
              WordAccuracy DECIMAL(10, 2) ,
              MathTest INT ,
              MathAccuracy DECIMAL(10, 2) ,
              TypingSpeed INT ,
              TypingAccuracy INT ,
              BeaconScore INT ,
              FICOScore INT
            );


        INSERT  INTO #IndividualStats
                ( CSSINDEX ,
                  current_index ,
                  HeaderName ,
                  HeaderToolTip ,
                  HeaderLink ,
                  TableClass ,
                  StartDate ,
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
                  TotalNoOfEmails ,
			      
                  -- SCORE
                  NoMatching ,
                  NoAccuracy ,
                  WordMatching ,
                  WordAccuracy ,
                  MathTest ,
                  MathAccuracy ,
                  TypingSpeed ,
                  TypingAccuracy ,
                  BeaconScore ,
                  FICOScore
                )
				-- Calculate BFC Total
                SELECT  *
                FROM    ( SELECT    1 AS [CSSINDEX] ,
                                    101 AS [current_index] ,
                                    'BFC Tot.' AS [HeaderName] ,
                                    'Beacon Funding Corporation Total' AS [HeaderToolTip] ,
                                    '#' AS [HeaderLink] ,
                                    'BFC_Total' AS [TableClass] ,
                                    '-' AS [StartDate] ,
                                    0 AS [UniqueUserId] ,
                                    '' AS [Username] ,
                                    @BEGINDATE AS [FromDate] ,
                                    @ENDDATE AS [ToDate] ,
																			
									-- COMPLEATED TICKET STATS
                                    COUNT(*) AS [CompletedWHDTktCount] , -- CompletedWHDTktCount
                                    [dbo].[ufnGetPercOfTicketSolved](@BEGINDATE,
                                                              @ENDDATE, NULL,
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
                          WHERE     CAST(t.[ClosedDate] AS DATE) >= @BEGINDATE
                                    AND CAST(t.[ClosedDate] AS DATE) <= @ENDDATE
									AND t.Tech_IsMisc = 0
                        ) compleated
                        LEFT JOIN ( SELECT -- EVALUATION STATS
                                            COUNT(*) AS [EvaluationsNo] , -- EvaluationsNo
                                            AVG(Rating) AS [EvaluationRating] -- EvaluationRating
                                    FROM #Individuals i   
									LEFT JOIN dbo.KeyStats_EmployeeEvaluation_DailySnapShot e ON e.[EvaluateForUsername] = i.username
                                    WHERE   CAST(e.[ActualCloseDate] AS DATE) >= @BEGINDATE
                                            AND CAST(e.[ActualCloseDate] AS DATE) <= @ENDDATE
                                            AND i.IsMiscellaneous = 0
                                  ) evaluation ON 1 = 1
                        LEFT JOIN ( SELECT  -- OPEN TICKET STATS
                                            COUNT(*) AS [OpenTickets] , -- OpenTickets ,
                                            COUNT(CASE WHEN IsPastDue = 1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [OpenPastDue] , -- OpenPastDue
                                            COUNT(CASE WHEN AssignedTech = 'unassigned'
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
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType1] ,-- ProblemType1
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType2
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType2] ,-- ProblemType2
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType3
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType3] ,-- ProblemType3
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType4
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType4] ,-- ProblemType4
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType5
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType5] ,-- ProblemType5
                                            COUNT(CASE WHEN p.ProblemType NOT IN (
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
                                    WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
									AND p.Tech_IsMisc = 0
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
                                    WHERE   CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                            AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
											AND i.UniqueUserId = 0
                                  ) activity ON 1 = 1
                        LEFT JOIN ( SELECT -- SCORE
                                            SUM(ISNULL(t.[ProofReadingTestA], 0)) AS [NoMatching] , -- NoMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                   0)) AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[ProofReadingTestB], 0)) AS [WordMatching] , -- WordMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                   0)) AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[MathTest], 0)) AS [MathTest] , -- MathTest INT ,
                                            SUM(ISNULL(t.[MathTestAttempt], 0)) AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[TypingTestWPM], 0)) AS [TypingSpeed] , -- TypingSpeed INT ,
                                            SUM(ISNULL(t.[TypingTestAccuracy],
                                                   0)) AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                            SUM(ISNULL(t.[BeaconScore], 0)) AS [BeaconScore] , -- BeaconScore INT ,
                                            SUM(ISNULL(t.[FicoScore], 0)) AS [FICOScore] -- FICOScore INT
                                    FROM    #Individuals i
                                            LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
											AND i.UniqueUserId = 0
                                  ) scores ON 1 = 1
                UNION
				-- Calculate BFC Average              
                SELECT  *
                FROM    ( SELECT    2 AS [CSSINDEX] ,
                                    102 AS [current_index] ,
                                    'BFC Avg.' AS [HeaderName] ,
                                    'Beacon Funding Corporation Average' AS [HeaderToolTip] ,
                                    '#' AS [HeaderLink] ,
                                    'BFC_Avg' AS [TableClass] ,
                                    '-' AS [StartDate] ,
                                    0 AS [UniqueUserId] ,
                                    '' AS [Username] ,
                                    @BEGINDATE AS [FromDate] ,
                                    @ENDDATE AS [ToDate] ,

									-- COMPLEATED TICKET STATS
                                    COUNT(*) / @IndividualCount AS [CompletedWHDTktCount] , -- CompletedWHDTktCount
                                    [dbo].[ufnGetPercOfTicketSolved](@BEGINDATE,
                                                              @ENDDATE, NULL,
                                                              NULL)
                                    / @IndividualCount AS [PercTktSolved] , -- PercTktSolved
                                    SUM(UnassignedTime) / @IndividualCount AS [ClosedUnassignedTime] , -- ClosedUnassignedTime
                                    AVG(FirstResponseTime) / @IndividualCount AS [AvgFirstRespTime] , -- AvgFirstRespTime
                                    AVG(TotalTimeOpen) / @IndividualCount AS [AvgTotalTimeOpen] , -- AvgTotalTimeOpen
                                    SUM(TotalTimeOpen) / @IndividualCount AS [TotalWorkTime] , -- TotalWorkTime
                                    AVG(TotalTimeWorked) / @IndividualCount AS [AvgTotalWorkTime] , -- AvgTotalWorkTime
                                    AVG(PeopleCcPerTicket) / @IndividualCount AS [AvgNoPeopleCCperTicket] , -- AvgNoPeopleCCperTicket
                                    SUM(ReassignmentsCount) / @IndividualCount AS [ReaasignmentsCount] , -- ReaasignmentsCount
                                    AVG(ReassignmentsCount) / @IndividualCount AS [AvgNoReassignmentsPerTicket] , -- AvgNoReassignmentsPerTicket
                                    SUM(PastDueAlerts) / @IndividualCount AS [Level3AlertsCount] , -- Level3AlertsCount
                                    AVG(PastDueAlerts) / @IndividualCount AS [AvgNoLevel3AlertsPerTicket] , -- AvgNoLevel3AlertsPerTicket
                                    SUM(TotalNoofTechNotes) / @IndividualCount AS [TotalNoTechNotes] , -- TotalNoTechNotes
                                    AVG(TotalNoofTechNotes) / @IndividualCount AS [AvgNoTechNotesPerTicket] ,-- AvgNoTechNotesPerTicket
                                    SUM(ReopenCounter) / @IndividualCount AS [ClosedReopenTicketCount] -- ClosedReopenTicketCount
                          FROM      [dbo].[KeyStats_WHD_ClosedTickets_Snapshot] t
                          WHERE     CAST(t.[ClosedDate] AS DATE) >= @BEGINDATE
                                    AND CAST(t.[ClosedDate] AS DATE) <= @ENDDATE
									AND t.Tech_IsMisc = 0
                        ) compleated
                        LEFT JOIN ( SELECT -- EVALUATION STATS
                                            COUNT(*) / @IndividualCount AS [EvaluationsNo] , -- EvaluationsNo
                                            AVG(Rating) / @IndividualCount AS [EvaluationRating] -- EvaluationRating
                                    FROM #Individuals i   
									LEFT JOIN dbo.KeyStats_EmployeeEvaluation_DailySnapShot e ON e.[EvaluateForUsername] = i.username
                                    WHERE   CAST(e.[ActualCloseDate] AS DATE) >= @BEGINDATE
                                            AND CAST(e.[ActualCloseDate] AS DATE) <= @ENDDATE
                                            AND i.IsMiscellaneous = 0
                                  ) evaluation ON 1 = 1
                        LEFT JOIN ( SELECT  -- OPEN TICKET STATS
                                            COUNT(*) / @IndividualCount AS [OpenTickets] , -- OpenTickets ,
                                            COUNT(CASE WHEN IsPastDue = 1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [OpenPastDue] , -- OpenPastDue
                                            COUNT(CASE WHEN AssignedTech = 'unassigned'
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [OpenUnassigned] , -- OpenUnassigned ,
                                            SUM(CASE WHEN AssignedTech = 'unassigned'
                                                     THEN TotalTimeOpen
                                                     ELSE 0
                                                END) / @IndividualCount AS [OpenUnassignedTime] , -- OpenUnassignedTime ,
                                            AVG(FirstResponseTime)
                                            / @IndividualCount AS [OpenAvgFirstRespTime] , -- OpenAvgFirstRespTime
                                            AVG(TotalTimeOpen)
                                            / @IndividualCount AS [OpenAvgTotalTimeOpen] , -- OpenAvgTotalTimeOpen
                                            SUM(TotalTimeOpen)
                                            / @IndividualCount AS [OpenTotalWorkTime] , -- OpenTotalWorkTime
                                            AVG(TotalTimeWorked)
                                            / @IndividualCount AS [OpenAvgTotalWorkTime] , -- OpenAvgTotalWorkTime
                                            AVG(PeopleCcPerTicket)
                                            / @IndividualCount AS [OpenAvgCntPeopleCCperTicket] , -- OpenAvgCntPeopleCCperTicket
                                            SUM(ReassignmentsCount)
                                            / @IndividualCount AS [OpenReassignment] , -- OpenReassignment
                                            AVG(ReassignmentsCount) AS [OpenAvgReassignPerTicket] , -- OpenAvgReassignPerTicket
                                            SUM(PastDueAlerts)
                                            / @IndividualCount AS [OpenLevel3Alerts] , -- OpenLevel3Alerts
                                            AVG(PastDueAlerts)
                                            / @IndividualCount AS [OpenAvgCountOfLevel3AlertsPerTicket] , -- OpenAvgCountOfLevel3AlertsPerTicket
                                            SUM(TotalNoofTechNotes)
                                            / @IndividualCount AS [OpenTotalTechNotes] , -- OpenTotalTechNotes
                                            AVG(TotalNoofTechNotes)
                                            / @IndividualCount AS [OpenAvgCountOfTechNotesPerTicket] ,-- OpenAvgCountOfTechNotesPerTicket
                                            SUM(ReopenCounter)
                                            / @IndividualCount AS [OpenReopenTicketCount] ,-- OpenReopenTicketCount

                                            -- OPEN TICKET - BY REQUEST TYPE
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [ProblemType1] ,-- ProblemType1
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType2
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [ProblemType2] ,-- ProblemType2
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType3
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [ProblemType3] ,-- ProblemType3
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType4
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [ProblemType4] ,-- ProblemType4
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType5
                                                       THEN 1
                                                       ELSE NULL
                                                  END) / @IndividualCount AS [ProblemType5] ,-- ProblemType5
                                            COUNT(CASE WHEN p.ProblemType NOT IN (
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
                                    WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
									AND p.Tech_IsMisc = 0
                                  ) openTickets ON 1 = 1
                        LEFT JOIN ( SELECT -- ACTIVITY
                                            SUM([PhoneCalls]) / @IndividualCount AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                            SUM([TotalInboundCalls]) / @IndividualCount AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                            SUM([TotalOutboundCalls]) / @IndividualCount AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                            (SUM([TotalForwardCalls])
                                            + SUM([TotalInternalCalls])) / @IndividualCount AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                            CASE WHEN SUM([PhoneCalls]) > 0
                                                 THEN (SUM([CallDuration])
                                                      / SUM([PhoneCalls])) / @IndividualCount
                                                 ELSE NULL
                                            END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                            CASE WHEN SUM([PhoneCalls]) > 0
                                                 THEN (SUM([CallDuration])
                                                      / SUM([PhoneCalls]) * 60) / @IndividualCount
                                                 ELSE NULL
                                            END AS [AvgCallDurationMin] , -- AvgCallDurationMin
											'-' AS [AvgDailyStart] ,
											'-' AS [AvgDailyEnd] ,
                                            SUM(a.[TotalActiveHr]) / @IndividualCount AS [TotalActiveHrs] , -- TotalActiveHrs
                                            SUM(a.[NonWorkHours]) / @IndividualCount AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                            SUM([KeyStrokes]) / @IndividualCount AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                            SUM([EmailSent]) / @IndividualCount AS [TotalNoOfEmails] -- TotalNoOfEmails
                                    FROM    #Individuals i
                                            LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON a.[DirectoryName] = i.username
                                    WHERE   CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                            AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
											AND i.IsMiscellaneous = 0
                                  ) activity ON 1 = 1
                        LEFT JOIN ( SELECT -- SCORE
                                            SUM(ISNULL(t.[ProofReadingTestA],
                                                       0)) / @IndividualCount  AS [NoMatching] , -- NoMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                       0)) / @IndividualCount  AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[ProofReadingTestB],
                                                       0)) / @IndividualCount  AS [WordMatching] , -- WordMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                       0)) / @IndividualCount  AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[MathTest], 0)) / @IndividualCount  AS [MathTest] , -- MathTest INT ,
                                            SUM(ISNULL(t.[MathTestAttempt],
                                                       0)) / @IndividualCount  AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[TypingTestWPM],
                                                       0)) / @IndividualCount  AS [TypingSpeed] , -- TypingSpeed INT ,
                                            SUM(ISNULL(t.[TypingTestAccuracy],
                                                       0)) / @IndividualCount  AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                            SUM(ISNULL(t.[BeaconScore], 0)) / @IndividualCount  AS [BeaconScore] , -- BeaconScore INT ,
                                            SUM(ISNULL(t.[FicoScore], 0)) / @IndividualCount  AS [FICOScore] -- FICOScore INT
                                    FROM    #Individuals i
                                            LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
											AND i.IsMiscellaneous = 0
                                  ) scores ON 1 = 1
                UNION
				-- Calculate the individual stats
                SELECT  3 AS [CSSINDEX] ,
                        [dbo].[ufnCheckStartDateForColorFormating](1,
                                                              i.[StartDate]) AS [current_index] ,
                        [dbo].[ufnGetIndividualHeading](i.[StartDate],
                                                        i.[LName], 6, 2) AS [HeaderName] ,
                        i.[fullname] AS [HeaderToolTip] ,
                        'WHDStats.aspx?v=IDD&d=' + @dateFormate + '&u='
                        + CONVERT(VARCHAR(20), i.UniqueUserId) AS [HeaderLink] ,
                        '' AS [TableClass] ,
                        i.[StartDate] AS [StartDate] ,
                        i.[UniqueUserId] AS [UniqueUserId] ,
                        i.[username] AS [Username] ,
                        @BEGINDATE AS [FromDate] ,
                        @ENDDATE AS [ToDate] ,

						-- COMPLEATED TICKET STATS
                        compleated.[CompletedWHDTktCount] AS [CompletedWHDTktCount] ,
                        compleated.[PercTktSolved] AS [PercTktSolved] ,
                        compleated.[ClosedUnassignedTime] AS [ClosedUnassignedTime] ,
                        compleated.[AvgFirstRespTime] AS [AvgFirstRespTime] ,
                        compleated.[AvgTotalTimeOpen] AS [AvgTotalTimeOpen] ,
                        compleated.[TotalWorkTime] AS [TotalWorkTime] ,
                        compleated.[AvgTotalWorkTime] AS [AvgTotalWorkTime] ,
                        compleated.[AvgNoPeopleCCperTicket] AS [AvgNoPeopleCCperTicket] ,
                        compleated.[ReaasignmentsCount] AS [ReaasignmentsCount] ,
                        compleated.[AvgNoReassignmentsPerTicket] AS [AvgNoReassignmentsPerTicket] ,
                        compleated.[Level3AlertsCount] AS [Level3AlertsCount] ,
                        compleated.[AvgNoLevel3AlertsPerTicket] AS [AvgNoLevel3AlertsPerTicket] ,
                        compleated.[TotalNoTechNotes] AS [TotalNoTechNotes] ,
                        compleated.[AvgNoTechNotesPerTicket] AS [AvgNoTechNotesPerTicket] ,
                        compleated.[ClosedReopenTicketCount] AS [ClosedReopenTicketCount] ,

						-- EVALUATION STATS
                        evaluation.[EvaluationsNo] AS [EvaluationsNo] ,
                        evaluation.[EvaluationRating] AS [EvaluationRating] ,

						-- OPEN TICKET STATS
                        openTickets.[OpenTickets] AS [OpenTickets] ,
                        openTickets.[OpenPastDue] AS [OpenPastDue] ,
                        openTickets.[OpenUnassigned] AS [OpenUnassigned] ,
                        openTickets.[OpenUnassignedTime] AS [OpenUnassignedTime] ,
                        openTickets.[OpenAvgFirstRespTime] AS [OpenAvgFirstRespTime] ,
                        openTickets.[OpenAvgTotalTimeOpen] AS [OpenAvgTotalTimeOpen] ,
                        openTickets.[OpenTotalWorkTime] AS [OpenTotalWorkTime] ,
                        openTickets.[OpenAvgTotalWorkTime] AS [OpenAvgTotalWorkTime] ,
                        openTickets.[OpenAvgCntPeopleCCperTicket] AS [OpenAvgCntPeopleCCperTicket] ,
                        openTickets.[OpenReassignment] AS [OpenReassignment] ,
                        openTickets.[OpenAvgReassignPerTicket] AS [OpenAvgReassignPerTicket] ,
                        openTickets.[OpenLevel3Alerts] AS [OpenLevel3Alerts] ,
                        openTickets.[OpenAvgCountOfLevel3AlertsPerTicket] AS [OpenAvgCountOfLevel3AlertsPerTicket] ,
                        openTickets.[OpenTotalTechNotes] AS [OpenTotalTechNotes] ,
                        openTickets.[OpenAvgCountOfTechNotesPerTicket] AS [OpenAvgCountOfTechNotesPerTicket] ,
                        openTickets.[OpenReopenTicketCount] AS [OpenReopenTicketCount] ,

						-- OPEN TICKET - BY REQUEST TYPE
                        openTickets.[ProblemType1] AS [ProblemType1] ,
                        openTickets.[ProblemType2] AS [ProblemType2] ,
                        openTickets.[ProblemType3] AS [ProblemType3] ,
                        openTickets.[ProblemType4] AS [ProblemType4] ,
                        openTickets.[ProblemType5] AS [ProblemType5] ,
                        openTickets.[ProblemTypeOthers] AS [ProblemTypeOthers] ,
                        openTickets.[ProblemTypeTotal] AS [ProblemTypeTotal] ,
						
						-- ACTIVITY
                        activity.[NoOfTotalCalls] AS [NoOfTotalCalls] ,
                        activity.[NoOfIncomingCalls] AS [NoOfIncomingCalls] ,
                        activity.[NoOfOutgiongCalls] AS [NoOfOutgiongCalls] ,
                        activity.[NoOfInternalForwardedCalls] AS [NoOfInternalForwardedCalls] ,
                        activity.[NoOfAvgCallsPerDay] AS [NoOfAvgCallsPerDay] ,
                        activity.[AvgCallDurationMin] AS [AvgCallDurationMin] ,
                        activity.[AvgDailyStart] AS [AvgDailyStart] ,
                        activity.[AvgDailyEnd] AS [AvgDailyEnd] ,
                        activity.[TotalActiveHrs] AS [TotalActiveHrs] ,
                        activity.[TotalNonWorkHrs] AS [TotalNonWorkHrs] ,
                        activity.[TotalNoOfKeystrokes] AS [TotalNoOfKeystrokes] ,
                        activity.[TotalNoOfEmails] AS [TotalNoOfEmails] ,
						
						-- SCORE
                        scores.[NoMatching] AS [NoMatching] ,
                        scores.[NoAccuracy] AS [NoAccuracy] ,
                        scores.[WordMatching] AS [WordMatching] ,
                        scores.[WordAccuracy] AS [WordAccuracy] ,
                        scores.[MathTest] AS [MathTest] ,
                        scores.[MathAccuracy] AS [MathAccuracy] ,
                        scores.[TypingSpeed] AS [TypingSpeed] ,
                        scores.[TypingAccuracy] AS [TypingAccuracy] ,
                        scores.[BeaconScore] AS [BeaconScore] ,
                        scores.[FICOScore] AS [FICOScore]
                FROM    ( SELECT    *
                          FROM      #Individuals i
                          WHERE     i.IsMiscellaneous = 0
                        ) i
                        LEFT JOIN ( SELECT  MAX([Tech_UniqueUserId]) AS [UniqueUserId] ,                      
										-- COMPLEATED TICKET STATS
                                            COUNT(*) AS [CompletedWHDTktCount] , -- CompletedWHDTktCount
                                            [dbo].[ufnGetPercOfTicketSolved](@BEGINDATE,
                                                              @ENDDATE, NULL,
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
                                    FROM    [dbo].[KeyStats_WHD_ClosedTickets_Snapshot] t
                                    WHERE   CAST(t.[ClosedDate] AS DATE) >= @BEGINDATE
                                            AND CAST(t.[ClosedDate] AS DATE) <= @ENDDATE
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
                                    GROUP BY [Tech_UniqueUserId]
                                  ) compleated ON compleated.[UniqueUserId] = i.UniqueUserId
                        LEFT JOIN ( SELECT -- EVALUATION STATS
                                            MAX(e.[EvaluateForUsername]) AS [Username] ,
                                            COUNT(*) AS [EvaluationsNo] , -- EvaluationsNo
                                            AVG(Rating) AS [EvaluationRating] -- EvaluationRating
                                    FROM #Individuals i   
									LEFT JOIN dbo.KeyStats_EmployeeEvaluation_DailySnapShot e ON e.[EvaluateForUsername] = i.username
                                    WHERE   CAST(e.[ActualCloseDate] AS DATE) >= @BEGINDATE
                                            AND CAST(e.[ActualCloseDate] AS DATE) <= @ENDDATE
                                            AND i.IsMiscellaneous = ISNULL(@IsMisc, i.IsMiscellaneous)
                                    GROUP BY e.[EvaluateForUsername]
                                  ) evaluation ON evaluation.[Username] = i.[username]
                        LEFT JOIN ( SELECT  MAX([Tech_UniqueUserId]) AS [UniqueUserId] ,
											-- OPEN TICKET STATS
                                            COUNT(*) AS [OpenTickets] , -- OpenTickets ,
                                            COUNT(CASE WHEN IsPastDue = 1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [OpenPastDue] , -- OpenPastDue
                                            COUNT(CASE WHEN LOWER(AssignedTech) = 'unassigned'
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [OpenUnassigned] , -- OpenUnassigned ,
                                            SUM(CASE WHEN LOWER(AssignedTech) = 'unassigned'
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
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType1] ,-- ProblemType1
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType2
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType2] ,-- ProblemType2
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType3
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType3] ,-- ProblemType3
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType4
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType4] ,-- ProblemType4
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType5
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType5] ,-- ProblemType5
                                            COUNT(CASE WHEN p.ProblemType NOT IN (
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
                                    WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
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
                                    GROUP BY [Tech_UniqueUserId]
                                  ) openTickets ON openTickets.[UniqueUserId] = i.UniqueUserId
                        LEFT JOIN ( SELECT -- ACTIVITY
											MAX([DirectoryName]) AS [DirectoryName],
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
                                    FROM      #Individuals i
									LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON a.[DirectoryName] = i.[username]
									WHERE     i.IsMiscellaneous = 0
											AND CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                            AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
                                            AND i.UniqueUserId = ISNULL(@UniqueID,
                                                              i.UniqueUserId)
                                            AND i.IsMiscellaneous = ISNULL(@IsMisc,
                                                              i.IsMiscellaneous)
									GROUP BY a.[DirectoryName]
                                  ) activity ON activity.[DirectoryName] = i.[username]
                        LEFT JOIN ( SELECT -- SCORE
											MAX(t.UniqueUserId) AS [UniqueUserId],
                                            SUM(ISNULL(t.[ProofReadingTestA],
                                                       0))  AS [NoMatching] , -- NoMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                       0))  AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[ProofReadingTestB],
                                                       0))  AS [WordMatching] , -- WordMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                       0))  AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[MathTest], 0))  AS [MathTest] , -- MathTest INT ,
                                            SUM(ISNULL(t.[MathTestAttempt],
                                                       0))  AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[TypingTestWPM],
                                                       0))  AS [TypingSpeed] , -- TypingSpeed INT ,
                                            SUM(ISNULL(t.[TypingTestAccuracy],
                                                       0))  AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                            SUM(ISNULL(t.[BeaconScore], 0))  AS [BeaconScore] , -- BeaconScore INT ,
                                            SUM(ISNULL(t.[FicoScore], 0))  AS [FICOScore] -- FICOScore INT
                                    FROM    #Individuals i
                                    LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
									WHERE     i.IsMiscellaneous = 0
									GROUP BY t.UniqueUserId
                                    
                                  ) scores ON scores.[UniqueUserId] = i.[UniqueUserId]
                UNION              
				-- Calculate the Miscellaneous              
                SELECT  *
                FROM    ( SELECT    4 AS [CSSINDEX] ,
                                    103 AS [current_index] ,
                                    'Misc.<sup></sup>' AS [HeaderName] ,
                                    'Miscellaneous' AS [HeaderToolTip] ,
                                    'WHDStats.aspx?v=IDD&d=' + @dateFormate
                                    + '&u=misc' AS [HeaderLink] ,
                                    '' AS [TableClass] ,
                                    '-' AS [StartDate] ,
                                    0 AS [UniqueUserId] ,
                                    '' AS [Username] ,
                                    @BEGINDATE AS [FromDate] ,
                                    @ENDDATE AS [ToDate] ,

									-- COMPLEATED TICKET STATS
                                    COUNT(*) AS [CompletedWHDTktCount] , -- CompletedWHDTktCount
                                    [dbo].[ufnGetPercOfTicketSolved](@BEGINDATE,
                                                              @ENDDATE, NULL,
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
                          WHERE     CAST(t.[ClosedDate] AS DATE) >= @BEGINDATE
                                    AND CAST(t.[ClosedDate] AS DATE) <= @ENDDATE
                                    AND t.[Tech_IsMisc] = 1
                        ) compleated
                        LEFT JOIN ( SELECT -- EVALUATION STATS
                                            COUNT(*) AS [EvaluationsNo] , -- EvaluationsNo
                                            AVG(Rating) AS [EvaluationRating] -- EvaluationRating
                                    FROM    dbo.KeyStats_EmployeeEvaluation_DailySnapShot e
                                    WHERE   CAST(e.[ActualCloseDate] AS DATE) >= @BEGINDATE
                                            AND CAST(e.[ActualCloseDate] AS DATE) <= @ENDDATE
                                            AND e.[EvaluateForUsername] IN (
                                            SELECT  username
                                            FROM    #Individuals
                                            WHERE   IsMiscellaneous = 1 )
                                  ) evaluation ON 1 = 1
                        LEFT JOIN ( SELECT  -- OPEN TICKET STATS
                                            COUNT(*) AS [OpenTickets] , -- OpenTickets ,
                                            COUNT(CASE WHEN IsPastDue = 1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [OpenPastDue] , -- OpenPastDue
                                            COUNT(CASE WHEN AssignedTech = 'unassigned'
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
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType1
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType1] ,-- ProblemType1
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType2
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType2] ,-- ProblemType2
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType3
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType3] ,-- ProblemType3
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType4
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType4] ,-- ProblemType4
                                            COUNT(CASE WHEN p.ProblemType = @ProblemType5
                                                       THEN 1
                                                       ELSE NULL
                                                  END) AS [ProblemType5] ,-- ProblemType5
                                            COUNT(CASE WHEN p.ProblemType NOT IN (
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
                                    WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
                                            AND p.[Tech_IsMisc] = 1
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
                                    FROM      #Individuals i
									LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON a.[DirectoryName] = i.[username]
									WHERE     i.IsMiscellaneous = 1
											AND CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                            AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
                                            AND i.UniqueUserId = ISNULL(@UniqueID,
                                                              i.UniqueUserId)
                                            AND i.IsMiscellaneous = ISNULL(@IsMisc,
                                                              i.IsMiscellaneous)
                                  ) activity ON 1 = 1
                        LEFT JOIN ( SELECT -- SCORE
                                            SUM(ISNULL(t.[ProofReadingTestA],
                                                       0))  AS [NoMatching] , -- NoMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                       0))  AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[ProofReadingTestB],
                                                       0))  AS [WordMatching] , -- WordMatching INT ,
                                            SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                       0))  AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[MathTest], 0))  AS [MathTest] , -- MathTest INT ,
                                            SUM(ISNULL(t.[MathTestAttempt],
                                                       0))  AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                            SUM(ISNULL(t.[TypingTestWPM],
                                                       0))  AS [TypingSpeed] , -- TypingSpeed INT ,
                                            SUM(ISNULL(t.[TypingTestAccuracy],
                                                       0))  AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                            SUM(ISNULL(t.[BeaconScore], 0))  AS [BeaconScore] , -- BeaconScore INT ,
                                            SUM(ISNULL(t.[FicoScore], 0))  AS [FICOScore] -- FICOScore INT
                                    FROM    #Individuals i
                                    LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
									WHERE     i.IsMiscellaneous = 1
                                    
                                  ) scores ON 1 = 1


        SELECT  *
        FROM    #IndividualStats
        ORDER BY [CSSINDEX] ,
                [HeaderName];

        SELECT  *
        FROM    #TopCategory;

    END
GO
