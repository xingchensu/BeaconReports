SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/09/2015
-- Description:	To load the individual stats 

-- Test: [dbo].[KeyStats_IndiaAdmin_LoadIndividualStats] '01/01/2015', '12/11/2015', 'ytd'
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_IndiaAdmin_LoadIndividualStats]
    @BEGINDATE AS DATETIME ,
    @ENDDATE AS DATETIME ,
    @dateFormate AS VARCHAR(10) ,
    @USERNAME AS VARCHAR(25) = NULL ,
    @IsMisc AS BIT = NULL ,
    @Shift AS INT = NULL
AS 
    BEGIN
        SET NOCOUNT ON;

		-- Convert date formate to lower case
        SET @dateFormate = LOWER(@dateFormate);

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
        WHERE   c.CategoryID = 4;

        DECLARE @IndividualCount AS INT = 0;

				-- Get the count of all emnployees
        SELECT  @IndividualCount = COUNT(*)
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID
        WHERE   c.CategoryID = 4

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

			  -- CAFE PRESS
              CP_ReportedHour DECIMAL(10, 2) ,
              CP_ActiveHrs DECIMAL(10, 2) ,
              CP_Designs DECIMAL(10, 2) ,
              CP_DesignsPerHr DECIMAL(10, 2) ,
              CP_Cost DECIMAL(10, 2) ,
              CP_CostPerDesign DECIMAL(10, 2) ,

              --ZAZZLE
              ZZ_ReportedHour DECIMAL(10, 2) ,
              ZZ_ActiveHrs DECIMAL(10, 2) ,
              ZZ_Designs DECIMAL(10, 2) ,
              ZZ_DesignsPerHr DECIMAL(10, 2) ,
              ZZ_Cost DECIMAL(10, 2) ,
              ZZ_CostPerDesign DECIMAL(10, 2) ,

              -- SHUTTERSTOCK
              SS_ReportedHour DECIMAL(10, 2) ,
              SS_ActiveHrs DECIMAL(10, 2) ,
              SS_Designs DECIMAL(10, 2) ,
              SS_DesignsPerHr DECIMAL(10, 2) ,
              SS_Cost DECIMAL(10, 2) ,
              SS_CostPerDesign DECIMAL(10, 2) ,

              -- DREAMSTIME
              DT_ReportedHour DECIMAL(10, 2) ,
              DT_ActiveHrs DECIMAL(10, 2) ,
              DT_Designs DECIMAL(10, 2) ,
              DT_DesignsPerHr DECIMAL(10, 2) ,
              DT_Cost DECIMAL(10, 2) ,
              DT_CostPerDesign DECIMAL(10, 2) ,

              -- 123RF
              RF_ReportedHour DECIMAL(10, 2) ,
              RF_ActiveHrs DECIMAL(10, 2) ,
              RF_Designs DECIMAL(10, 2) ,
              RF_DesignsPerHr DECIMAL(10, 2) ,
              RF_Cost DECIMAL(10, 2) ,
              RF_CostPerDesign DECIMAL(10, 2) ,
	          
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

		-- Calculate BFC Total
        INSERT  INTO #IndividualStats
                ( current_index ,
                  HeaderName ,
                  HeaderToolTip ,
                  HeaderLink ,
                  TableClass ,
                  FromDate ,
                  ToDate ,
						 
				  -- CAFE PRESS
                  CP_ReportedHour ,
                  CP_ActiveHrs ,
                  CP_Designs ,
                  CP_DesignsPerHr ,
                  CP_Cost ,
                  CP_CostPerDesign ,

				  -- ZAZZLE
                  ZZ_ReportedHour ,
                  ZZ_ActiveHrs ,
                  ZZ_Designs ,
                  ZZ_DesignsPerHr ,
                  ZZ_Cost ,
                  ZZ_CostPerDesign ,

				  -- SHUTTERSTOCK
                  SS_ReportedHour ,
                  SS_ActiveHrs ,
                  SS_Designs ,
                  SS_DesignsPerHr ,
                  SS_Cost ,
                  SS_CostPerDesign ,

				  -- DREAMSTIME
                  DT_ReportedHour ,
                  DT_ActiveHrs ,
                  DT_Designs ,
                  DT_DesignsPerHr ,
                  DT_Cost ,
                  DT_CostPerDesign ,

				  -- 123RF
                  RF_ReportedHour ,
                  RF_ActiveHrs ,
                  RF_Designs ,
                  RF_DesignsPerHr ,
                  RF_Cost ,
                  RF_CostPerDesign ,
                  
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
                ( SELECT    *
                  FROM      ( SELECT    101 AS [current_index] ,
                                        'BFC Tot.' AS [HeaderName] ,
                                        'Beacon Funding Corporation Total' AS [HeaderToolTip] ,
                                        '#' AS [HeaderLink] ,
                                        'BFC_Total' AS [TableClass] ,
                                        @BEGINDATE AS [FromDate] ,
                                        @ENDDATE AS [ToDate] ,

						  -- CAFE PRESS
                                        SUM(ISNULL(s.CP_RepotedHrs, 0)) AS [CP_ReportedHour] ,
                                        SUM(ISNULL(s.CP_ActiveHrs, 0)) AS [CP_ActiveHrs] ,
                                        SUM(ISNULL(s.CP_Designs, 0)) AS [CP_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.CP_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.CP_Designs,
                                                              0)
                                                             / s.CP_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [CP_DesignsPerHr] ,
                                        SUM(ISNULL(s.CP_Cost, 0)) AS [CP_Cost] ,
                                        SUM(ISNULL(s.CP_CostPerDesign, 0)) AS [CP_CostPerDesign] ,

						  -- ZAZZLE
                                        SUM(ISNULL(s.ZZ_RepotedHrs, 0)) AS [ZZ_ReportedHour] ,
                                        SUM(ISNULL(s.ZZ_ActiveHrs, 0)) AS [ZZ_ActiveHrs] ,
                                        SUM(ISNULL(s.ZZ_Designs, 0)) AS [ZZ_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.ZZ_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.ZZ_Designs,
                                                              0)
                                                             / s.ZZ_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [ZZ_DesignsPerHr] ,
                                        SUM(ISNULL(s.ZZ_Cost, 0)) AS [ZZ_Cost] ,
                                        SUM(ISNULL(s.ZZ_CostPerDesign, 0)) AS [ZZ_CostPerDesign] ,

						  -- SHUTTERSTOCK
                                        SUM(ISNULL(s.SS_RepotedHrs, 0)) AS [SS_ReportedHour] ,
                                        SUM(ISNULL(s.SS_ActiveHrs, 0)) AS [SS_ActiveHrs] ,
                                        SUM(ISNULL(s.SS_Designs, 0)) AS [SS_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.SS_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.SS_Designs,
                                                              0)
                                                             / s.SS_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [SS_DesignsPerHr] ,
                                        SUM(ISNULL(s.SS_Cost, 0)) AS [SS_Cost] ,
                                        SUM(ISNULL(s.SS_CostPerDesign, 0)) AS [SS_CostPerDesign] ,

						  -- DREAMSTIME
                                        SUM(ISNULL(s.DT_RepotedHrs, 0)) AS [DT_ReportedHour] ,
                                        SUM(ISNULL(s.DT_ActiveHrs, 0)) AS [DT_ActiveHrs] ,
                                        SUM(ISNULL(s.DT_Designs, 0)) AS [DT_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.DT_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.DT_Designs,
                                                              0)
                                                             / s.DT_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [DT_DesignsPerHr] ,
                                        SUM(ISNULL(s.DT_Cost, 0)) AS [DT_Cost] ,
                                        SUM(ISNULL(s.DT_CostPerDesign, 0)) AS [DT_CostPerDesign] ,

						  -- 123RF
                                        SUM(ISNULL(s.RF_RepotedHrs, 0)) AS [RF_ReportedHour] ,
                                        SUM(ISNULL(s.RF_ActiveHrs, 0)) AS [RF_ActiveHrs] ,
                                        SUM(ISNULL(s.RF_Designs, 0)) AS [RF_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.RF_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.RF_Designs,
                                                              0)
                                                             / s.RF_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [RF_DesignsPerHr] ,
                                        SUM(ISNULL(s.RF_Cost, 0)) AS [RF_Cost] ,
                                        SUM(ISNULL(s.RF_CostPerDesign, 0)) AS [RF_CostPerDesign]
                              FROM      [dbo].[KeyStats_IndiaAdminStats_Snapshot] s
                              WHERE     s.[ActivityDate] >= @BEGINDATE
                                        AND [ActivityDate] <= @ENDDATE
                            ) adminStats
                            LEFT JOIN ( SELECT 
										-- ACTIVITY
                                                SUM(ISNULL([PhoneCalls], 0)) AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                                SUM(ISNULL([TotalInboundCalls],
                                                           0)) AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                                SUM(ISNULL([TotalOutboundCalls],
                                                           0)) AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                                SUM(ISNULL([TotalForwardCalls],
                                                           0))
                                                + SUM(ISNULL([TotalInternalCalls],
                                                             0)) AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN SUM(ISNULL([CallDuration],
                                                              0))
                                                          / SUM(ISNULL([PhoneCalls],
                                                              0))
                                                     ELSE NULL
                                                END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN SUM(ISNULL([CallDuration],
                                                              0))
                                                          / SUM(ISNULL([PhoneCalls],
                                                              0)) * 60
                                                     ELSE NULL
                                                END AS [AvgCallDurationMin] , -- AvgCallDurationMin
                                                ISNULL(CONVERT(VARCHAR(10), AVG(ISNULL([DailyStartMin],
                                                              0)) / 60) + ':'
                                                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin],
                                                              0)) % 60)) = 1
                                                              THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin],
                                                              0)) % 60)
                                                              ELSE CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin],
                                                              0)) % 60)
                                                         END, 0) AS [AvgDailyStart] ,
                                                ISNULL(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin],
                                                              0)) / 60) + ':'
                                                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin],
                                                              0)) % 60)) = 1
                                                              THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin],
                                                              0)) % 60)
                                                              ELSE CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin],
                                                              0)) % 60)
                                                         END, 0) AS [AvgDailyEnd] ,
                                                SUM(ISNULL(a.[TotalActiveHr],
                                                           0)) AS [TotalActiveHrs] , -- TotalActiveHrs
                                                SUM(ISNULL(a.[NonWorkHours], 0)) AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                                SUM(ISNULL([KeyStrokes], 0)) AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                                SUM(ISNULL([EmailSent], 0)) AS [TotalNoOfEmails] -- TotalNoOfEmails
                                        FROM    #Individuals i
                                                LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON LOWER(a.[DirectoryName]) = LOWER(i.username)
                                        WHERE   CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                                AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
                                                AND i.IsMiscellaneous = 0
                                      ) activity ON 1 = 1
                            LEFT JOIN ( SELECT 
										-- SCORE
                                                SUM(ISNULL(t.[ProofReadingTestA],
                                                           0)) AS [NoMatching] , -- NoMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                           0)) AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[ProofReadingTestB],
                                                           0)) AS [WordMatching] , -- WordMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                           0)) AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[MathTest], 0)) AS [MathTest] , -- MathTest INT ,
                                                SUM(ISNULL(t.[MathTestAttempt],
                                                           0)) AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[TypingTestWPM],
                                                           0)) AS [TypingSpeed] , -- TypingSpeed INT ,
                                                SUM(ISNULL(t.[TypingTestAccuracy],
                                                           0)) AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                                SUM(ISNULL(t.[BeaconScore], 0)) AS [BeaconScore] , -- BeaconScore INT ,
                                                SUM(ISNULL(t.[FicoScore], 0)) AS [FICOScore] -- FICOScore INT
                                        FROM    #Individuals i
                                                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
                                        WHERE   i.IsMiscellaneous = 0
                                      ) score ON 1 = 1
                )

		-- Calculate BFC Average
        INSERT  INTO #IndividualStats
                ( current_index ,
                  HeaderName ,
                  HeaderToolTip ,
                  HeaderLink ,
                  TableClass ,
                  FromDate ,
                  ToDate ,
				
				  -- CAFE PRESS
                  CP_ReportedHour ,
                  CP_ActiveHrs ,
                  CP_Designs ,
                  CP_DesignsPerHr ,
                  CP_Cost ,
                  CP_CostPerDesign ,

				  -- ZAZZLE
                  ZZ_ReportedHour ,
                  ZZ_ActiveHrs ,
                  ZZ_Designs ,
                  ZZ_DesignsPerHr ,
                  ZZ_Cost ,
                  ZZ_CostPerDesign ,

				  -- SHUTTERSTOCK
                  SS_ReportedHour ,
                  SS_ActiveHrs ,
                  SS_Designs ,
                  SS_DesignsPerHr ,
                  SS_Cost ,
                  SS_CostPerDesign ,

				  -- DREAMSTIME
                  DT_ReportedHour ,
                  DT_ActiveHrs ,
                  DT_Designs ,
                  DT_DesignsPerHr ,
                  DT_Cost ,
                  DT_CostPerDesign ,

				  -- 123RF
                  RF_ReportedHour ,
                  RF_ActiveHrs ,
                  RF_Designs ,
                  RF_DesignsPerHr ,
                  RF_Cost ,
                  RF_CostPerDesign ,
                  
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
                ( SELECT    *
                  FROM      ( SELECT    102 AS [current_index] ,
                                        'BFC Avg.' AS [HeaderName] ,
                                        'Beacon Funding Corporation Average' AS [HeaderToolTip] ,
                                        '#' AS [HeaderLink] ,
                                        'BFC_Avg' AS [TableClass] ,
                                        @BEGINDATE AS [FromDate] ,
                                        @ENDDATE AS [ToDate] ,

						-- CAFE PRESS
                                        SUM(ISNULL(s.CP_RepotedHrs, 0))
                                        / @IndividualCount AS [CP_ReportedHour] ,
                                        SUM(ISNULL(s.CP_ActiveHrs, 0))
                                        / @IndividualCount AS [CP_ActiveHrs] ,
                                        SUM(ISNULL(s.CP_Designs, 0))
                                        / @IndividualCount AS [CP_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.CP_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.CP_Designs,
                                                              0)
                                                             / s.CP_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) / @IndividualCount AS [CP_DesignsPerHr] ,
                                        SUM(ISNULL(s.CP_Cost, 0))
                                        / @IndividualCount AS [CP_Cost] ,
                                        SUM(ISNULL(s.CP_CostPerDesign, 0))
                                        / @IndividualCount AS [CP_CostPerDesign] ,

						-- ZAZZLE
                                        SUM(ISNULL(s.ZZ_RepotedHrs, 0))
                                        / @IndividualCount AS [ZZ_ReportedHour] ,
                                        SUM(ISNULL(s.ZZ_ActiveHrs, 0))
                                        / @IndividualCount AS [ZZ_ActiveHrs] ,
                                        SUM(ISNULL(s.ZZ_Designs, 0))
                                        / @IndividualCount AS [ZZ_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.ZZ_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.ZZ_Designs,
                                                              0)
                                                             / s.ZZ_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) / @IndividualCount AS [ZZ_DesignsPerHr] ,
                                        SUM(ISNULL(s.ZZ_Cost, 0))
                                        / @IndividualCount AS [ZZ_Cost] ,
                                        SUM(ISNULL(s.ZZ_CostPerDesign, 0))
                                        / @IndividualCount AS [ZZ_CostPerDesign] ,

						-- SHUTTERSTOCK
                                        SUM(ISNULL(s.SS_RepotedHrs, 0))
                                        / @IndividualCount AS [SS_ReportedHour] ,
                                        SUM(ISNULL(s.SS_ActiveHrs, 0))
                                        / @IndividualCount AS [SS_ActiveHrs] ,
                                        SUM(ISNULL(s.SS_Designs, 0))
                                        / @IndividualCount AS [SS_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.SS_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.SS_Designs,
                                                              0)
                                                             / s.SS_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) / @IndividualCount AS [SS_DesignsPerHr] ,
                                        SUM(ISNULL(s.SS_Cost, 0))
                                        / @IndividualCount AS [SS_Cost] ,
                                        SUM(ISNULL(s.SS_CostPerDesign, 0))
                                        / @IndividualCount AS [SS_CostPerDesign] ,

						-- DREAMSTIME
                                        SUM(ISNULL(s.DT_RepotedHrs, 0))
                                        / @IndividualCount AS [DT_ReportedHour] ,
                                        SUM(ISNULL(s.DT_ActiveHrs, 0))
                                        / @IndividualCount AS [DT_ActiveHrs] ,
                                        SUM(ISNULL(s.DT_Designs, 0))
                                        / @IndividualCount AS [DT_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.DT_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.DT_Designs,
                                                              0)
                                                             / s.DT_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) / @IndividualCount AS [DT_DesignsPerHr] ,
                                        SUM(ISNULL(s.DT_Cost, 0))
                                        / @IndividualCount AS [DT_Cost] ,
                                        SUM(ISNULL(s.DT_CostPerDesign, 0))
                                        / @IndividualCount AS [DT_CostPerDesign] ,

						-- 123RF
                                        SUM(ISNULL(s.RF_RepotedHrs, 0))
                                        / @IndividualCount AS [RF_ReportedHour] ,
                                        SUM(ISNULL(s.RF_ActiveHrs, 0))
                                        / @IndividualCount AS [RF_ActiveHrs] ,
                                        SUM(ISNULL(s.RF_Designs, 0))
                                        / @IndividualCount AS [RF_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.RF_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.RF_Designs,
                                                              0)
                                                             / s.RF_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) / @IndividualCount AS [RF_DesignsPerHr] ,
                                        SUM(ISNULL(s.RF_Cost, 0))
                                        / @IndividualCount AS [RF_Cost] ,
                                        SUM(ISNULL(s.RF_CostPerDesign, 0))
                                        / @IndividualCount AS [RF_CostPerDesign]
                              FROM      [dbo].[KeyStats_IndiaAdminStats_Snapshot] s
                              WHERE     s.[ActivityDate] >= @BEGINDATE
                                        AND [ActivityDate] <= @ENDDATE
                            ) adminStats
                            LEFT JOIN ( SELECT 
										-- ACTIVITY
                                                SUM(ISNULL([PhoneCalls], 0))
                                                / @IndividualCount AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                                SUM(ISNULL([TotalInboundCalls],
                                                           0))
                                                / @IndividualCount AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                                SUM(ISNULL([TotalOutboundCalls],
                                                           0))
                                                / @IndividualCount AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                                ( SUM(ISNULL([TotalForwardCalls],
                                                             0))
                                                  + SUM(ISNULL([TotalInternalCalls],
                                                              0)) )
                                                / @IndividualCount AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN ( SUM(ISNULL([CallDuration],
                                                              0))
                                                            / SUM(ISNULL([PhoneCalls],
                                                              0)) )
                                                          / @IndividualCount
                                                     ELSE NULL
                                                END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN ( SUM(ISNULL([CallDuration],
                                                              0))
                                                            / SUM(ISNULL([PhoneCalls],
                                                              0)) )
                                                          / @IndividualCount
                                                          * 60
                                                     ELSE NULL
                                                END AS [AvgCallDurationMin] , -- AvgCallDurationMin
                                                '-' AS [AvgDailyStart] ,
                                                '-' AS [AvgDailyEnd] ,
                                                SUM(ISNULL(a.[TotalActiveHr],
                                                           0))
                                                / @IndividualCount AS [TotalActiveHrs] , -- TotalActiveHrs
                                                SUM(ISNULL(a.[NonWorkHours], 0))
                                                / @IndividualCount AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                                SUM(ISNULL([KeyStrokes], 0))
                                                / @IndividualCount AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                                SUM(ISNULL([EmailSent], 0))
                                                / @IndividualCount AS [TotalNoOfEmails] -- TotalNoOfEmails
                                        FROM    #Individuals i
                                                LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON LOWER(a.[DirectoryName]) = LOWER(i.username)
                                        WHERE   CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                                AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
                                                AND i.IsMiscellaneous = 0
                                      ) activity ON 1 = 1
                            LEFT JOIN ( SELECT 
										-- SCORE
                                                SUM(ISNULL(t.[ProofReadingTestA],
                                                           0))
                                                / @IndividualCount AS [NoMatching] , -- NoMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                           0))
                                                / @IndividualCount AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[ProofReadingTestB],
                                                           0))
                                                / @IndividualCount AS [WordMatching] , -- WordMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                           0))
                                                / @IndividualCount AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[MathTest], 0)) AS [MathTest] , -- MathTest INT ,
                                                SUM(ISNULL(t.[MathTestAttempt],
                                                           0))
                                                / @IndividualCount AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[TypingTestWPM],
                                                           0))
                                                / @IndividualCount AS [TypingSpeed] , -- TypingSpeed INT ,
                                                SUM(ISNULL(t.[TypingTestAccuracy],
                                                           0))
                                                / @IndividualCount AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                                SUM(ISNULL(t.[BeaconScore], 0))
                                                / @IndividualCount AS [BeaconScore] , -- BeaconScore INT ,
                                                SUM(ISNULL(t.[FicoScore], 0))
                                                / @IndividualCount AS [FICOScore] -- FICOScore INT
                                        FROM    #Individuals i
                                                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
                                        WHERE   i.IsMiscellaneous = 0
                                      ) score ON 1 = 1
                )
		
		-- Calculate stats for individual employees
        INSERT  INTO #IndividualStats
                ( current_index ,
                  HeaderName ,
                  HeaderToolTip ,
                  HeaderLink ,
                  StartDate ,
                  UniqueUserId ,
                  Username ,
                  FromDate ,
                  ToDate ,

				  -- CAFE PRESS
                  CP_ReportedHour ,
                  CP_ActiveHrs ,
                  CP_Designs ,
                  CP_DesignsPerHr ,
                  CP_Cost ,
                  CP_CostPerDesign ,

				  -- ZAZZLE
                  ZZ_ReportedHour ,
                  ZZ_ActiveHrs ,
                  ZZ_Designs ,
                  ZZ_DesignsPerHr ,
                  ZZ_Cost ,
                  ZZ_CostPerDesign ,

				  -- SHUTTERSTOCK
                  SS_ReportedHour ,
                  SS_ActiveHrs ,
                  SS_Designs ,
                  SS_DesignsPerHr ,
                  SS_Cost ,
                  SS_CostPerDesign ,

				  -- DREAMSTIME
                  DT_ReportedHour ,
                  DT_ActiveHrs ,
                  DT_Designs ,
                  DT_DesignsPerHr ,
                  DT_Cost ,
                  DT_CostPerDesign ,

				  -- 123RF
                  RF_ReportedHour ,
                  RF_ActiveHrs ,
                  RF_Designs ,
                  RF_DesignsPerHr ,
                  RF_Cost ,
                  RF_CostPerDesign ,
                  
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
                ( SELECT [dbo].[ufnCheckStartDateForColorFormating](1,
                                                        individuals.[StartDate]) AS [current_index] ,
                        [dbo].[ufnGetIndividualHeading](individuals.[StartDate],
                                                        individuals.[LName], 6, 2) AS [HeaderName] ,
                        individuals.[fullname] AS [HeaderToolTip] ,
                        'IndiaAdminStats.aspx?v=IDD&d=' + @dateFormate+ '&u=' + individuals.[username] AS [HeaderLink] ,
                        individuals.[StartDate] AS [StartDate] ,
                        individuals.[UniqueUserId] AS [UniqueUserId] ,
                        individuals.[username] AS [Username] ,

                        @BEGINDATE AS [FromDate] ,
                        @ENDDATE AS [ToDate] ,

						-- CAFE PRESS
					  adminStats.CP_ReportedHour ,
					  adminStats.CP_ActiveHrs ,
					  adminStats.CP_Designs ,
					  adminStats.CP_DesignsPerHr ,
					  adminStats.CP_Cost ,
					  adminStats.CP_CostPerDesign ,

					  -- ZAZZLE
					  adminStats.ZZ_ReportedHour ,
					  adminStats.ZZ_ActiveHrs ,
					  adminStats.ZZ_Designs ,
					  adminStats.ZZ_DesignsPerHr ,
					  adminStats.ZZ_Cost ,
					  adminStats.ZZ_CostPerDesign ,

					  -- SHUTTERSTOCK
					  adminStats.SS_ReportedHour ,
					  adminStats.SS_ActiveHrs ,
					  adminStats.SS_Designs ,
					  adminStats.SS_DesignsPerHr ,
					  adminStats.SS_Cost ,
					  adminStats.SS_CostPerDesign ,

					  -- DREAMSTIME
					  adminStats.DT_ReportedHour ,
					  adminStats.DT_ActiveHrs ,
					  adminStats.DT_Designs ,
					  adminStats.DT_DesignsPerHr ,
					  adminStats.DT_Cost ,
					  adminStats.DT_CostPerDesign ,

					  -- 123RF
					  adminStats.RF_ReportedHour ,
					  adminStats.RF_ActiveHrs ,
					  adminStats.RF_Designs ,
					  adminStats.RF_DesignsPerHr ,
					  adminStats.RF_Cost ,
					  adminStats.RF_CostPerDesign ,

					  -- ACTIVITY
					  ISNULL(activity.NoOfTotalCalls ,0) ,
					  ISNULL(activity.NoOfIncomingCalls ,0) ,
					  ISNULL(activity.NoOfOutgiongCalls ,0) ,
					  ISNULL(activity.NoOfInternalForwardedCalls ,0) ,
					  ISNULL(activity.NoOfAvgCallsPerDay ,0) ,
					  ISNULL(activity.AvgCallDurationMin ,0) ,
					  ISNULL(activity.AvgDailyStart ,0) ,
					  ISNULL(activity.AvgDailyEnd ,0) ,
					  ISNULL(activity.TotalActiveHrs ,0) ,
					  ISNULL(activity.TotalNonWorkHrs ,0) ,
					  ISNULL(activity.TotalNoOfKeystrokes ,0) ,
					  ISNULL(activity.TotalNoOfEmails ,0) ,
					  
					  -- SCORE
					  ISNULL(scores.NoMatching ,0) ,
					  ISNULL(scores.NoAccuracy ,0) ,
					  ISNULL(scores.WordMatching ,0) ,
					  ISNULL(scores.WordAccuracy ,0) ,
					  ISNULL(scores.MathTest ,0) ,
					  ISNULL(scores.MathAccuracy ,0) ,
					  ISNULL(scores.TypingSpeed ,0) ,
					  ISNULL(scores.TypingAccuracy ,0) ,
					  ISNULL(scores.BeaconScore ,0) ,
					  ISNULL(scores.FICOScore, 0)

                  FROM      ( SELECT    *
                              FROM      #Individuals i
                              WHERE     i.IsMiscellaneous = 0
                            ) individuals
                            LEFT JOIN ( SELECT  MAX(s.[UniqueUserId]) AS [UniqueUserId],

						-- CAFE PRESS
                                                SUM(ISNULL(s.CP_RepotedHrs, 0)) AS [CP_ReportedHour],
                                                SUM(ISNULL(s.CP_ActiveHrs, 0)) AS [CP_ActiveHrs],
                                                SUM(ISNULL(s.CP_Designs, 0)) AS [CP_Designs],
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.CP_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.CP_Designs,
                                                              0)
                                                              / s.CP_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [CP_DesignsPerHr],
                                                SUM(ISNULL(s.CP_Cost, 0)) AS [CP_Cost],
                                                SUM(ISNULL(s.CP_CostPerDesign,
                                                           0)) AS [CP_CostPerDesign],

						-- ZAZZLE
                                                SUM(ISNULL(s.ZZ_RepotedHrs, 0)) AS [ZZ_ReportedHour],
                                                SUM(ISNULL(s.ZZ_ActiveHrs, 0)) AS [ZZ_ActiveHrs],
                                                SUM(ISNULL(s.ZZ_Designs, 0)) AS [ZZ_Designs],
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.ZZ_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.ZZ_Designs,
                                                              0)
                                                              / s.ZZ_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [ZZ_DesignsPerHr],
                                                SUM(ISNULL(s.ZZ_Cost, 0)) AS [ZZ_Cost],
                                                SUM(ISNULL(s.ZZ_CostPerDesign,
                                                           0)) AS [ZZ_CostPerDesign],

						  -- SHUTTERSTOCK
                                                SUM(ISNULL(s.SS_RepotedHrs, 0)) AS [SS_ReportedHour],
                                                SUM(ISNULL(s.SS_ActiveHrs, 0)) AS [SS_ActiveHrs],
                                                SUM(ISNULL(s.SS_Designs, 0)) AS [SS_Designs],
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.SS_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.SS_Designs,
                                                              0)
                                                              / s.SS_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [SS_DesignsPerHr],
                                                SUM(ISNULL(s.SS_Cost, 0)) AS [SS_Cost],
                                                SUM(ISNULL(s.SS_CostPerDesign,
                                                           0)) AS [SS_CostPerDesign],

						  -- DREAMSTIME
                                                SUM(ISNULL(s.DT_RepotedHrs, 0)) AS [DT_ReportedHour],
                                                SUM(ISNULL(s.DT_ActiveHrs, 0)) AS [DT_ActiveHrs],
                                                SUM(ISNULL(s.DT_Designs, 0)) AS [DT_Designs],
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.DT_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.DT_Designs,
                                                              0)
                                                              / s.DT_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [DT_DesignsPerHr],
                                                SUM(ISNULL(s.DT_Cost, 0)) AS [DT_Cost],
                                                SUM(ISNULL(s.DT_CostPerDesign,
                                                           0)) AS [DT_CostPerDesign],

						  -- 123RF
                                                SUM(ISNULL(s.RF_RepotedHrs, 0)) AS [RF_ReportedHour],
                                                SUM(ISNULL(s.RF_ActiveHrs, 0)) AS [RF_ActiveHrs],
                                                SUM(ISNULL(s.RF_Designs, 0)) AS [RF_Designs],
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.RF_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.RF_Designs,
                                                              0)
                                                              / s.RF_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [RF_DesignsPerHr],
                                                SUM(ISNULL(s.RF_Cost, 0)) AS [RF_Cost],
                                                SUM(ISNULL(s.RF_CostPerDesign,
                                                           0)) AS [RF_CostPerDesign]
                                        FROM    [dbo].[KeyStats_IndiaAdminStats_Snapshot] s
                                        WHERE   s.[ActivityDate] >= @BEGINDATE
                                                AND s.[ActivityDate] <= @ENDDATE
												AND (LOWER(s.username) = LOWER(@USERNAME) OR @USERNAME IS NULL)
												AND (s.[shift] = @Shift OR @Shift IS NULL)
                                                AND s.IsMiscellaneous = 0
                                        GROUP BY s.[UniqueUserId]
                                      ) adminStats ON adminStats.[UniqueUserId] = individuals.[UniqueUserId]
                            LEFT JOIN ( SELECT -- ACTIVITY
                                                MAX([DirectoryName]) AS [DirectoryName] ,
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
                                                          / SUM([PhoneCalls])
                                                          * 60
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
                                                LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON LOWER(a.[DirectoryName]) = LOWER(i.[username])
                                        WHERE   i.IsMiscellaneous = 0
                                                AND CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                                AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
												AND (LOWER(i.username) = LOWER(@USERNAME) OR @USERNAME IS NULL)
												AND (i.IsMiscellaneous = @IsMisc OR @IsMisc IS NULL)
                                        GROUP BY a.[DirectoryName]
                                      ) activity ON LOWER(activity.[DirectoryName]) = LOWER(individuals.[username])
                            LEFT JOIN ( SELECT -- SCORE
                                                MAX(t.UniqueUserId) AS [UniqueUserId] ,
                                                SUM(ISNULL(t.[ProofReadingTestA],
                                                           0)) AS [NoMatching] , -- NoMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                           0)) AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[ProofReadingTestB],
                                                           0)) AS [WordMatching] , -- WordMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                           0)) AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[MathTest], 0)) AS [MathTest] , -- MathTest INT ,
                                                SUM(ISNULL(t.[MathTestAttempt],
                                                           0)) AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[TypingTestWPM],
                                                           0)) AS [TypingSpeed] , -- TypingSpeed INT ,
                                                SUM(ISNULL(t.[TypingTestAccuracy],
                                                           0)) AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                                SUM(ISNULL(t.[BeaconScore], 0)) AS [BeaconScore] , -- BeaconScore INT ,
                                                SUM(ISNULL(t.[FicoScore], 0)) AS [FICOScore] -- FICOScore INT
                                        FROM    #Individuals i
                                                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
                                        WHERE   i.IsMiscellaneous = 0
                                        GROUP BY t.UniqueUserId
                                      ) scores ON scores.[UniqueUserId] = individuals.[UniqueUserId]
                )

		-- Calculate BFC Miscellaneous
        INSERT  INTO #IndividualStats
                ( current_index ,
                  HeaderName ,
                  HeaderToolTip ,
                  HeaderLink ,
                  TableClass ,
                  FromDate ,
                  ToDate ,

				  -- CAFE PRESS
                  CP_ReportedHour ,
                  CP_ActiveHrs ,
                  CP_Designs ,
                  CP_DesignsPerHr ,
                  CP_Cost ,
                  CP_CostPerDesign ,

				  -- ZAZZLE
                  ZZ_ReportedHour ,
                  ZZ_ActiveHrs ,
                  ZZ_Designs ,
                  ZZ_DesignsPerHr ,
                  ZZ_Cost ,
                  ZZ_CostPerDesign ,

				  -- SHUTTERSTOCK
                  SS_ReportedHour ,
                  SS_ActiveHrs ,
                  SS_Designs ,
                  SS_DesignsPerHr ,
                  SS_Cost ,
                  SS_CostPerDesign ,

				  -- DREAMSTIME
                  DT_ReportedHour ,
                  DT_ActiveHrs ,
                  DT_Designs ,
                  DT_DesignsPerHr ,
                  DT_Cost ,
                  DT_CostPerDesign ,

				  -- 123RF
                  RF_ReportedHour ,
                  RF_ActiveHrs ,
                  RF_Designs ,
                  RF_DesignsPerHr ,
                  RF_Cost ,
                  RF_CostPerDesign ,
                  
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
                ( SELECT    *
                  FROM      ( SELECT    103 AS [current_index] ,
                                        'Misc.<sup></sup>' AS [HeaderName] ,
                                        'Miscellaneous' AS [HeaderToolTip] ,
                                        'IndiaAdminStats.aspx?v=IDD&d='
                                        + @dateFormate + '&u=misc' AS [HeaderLink] ,
                                        '' AS [TableClass] ,
                                        @BEGINDATE AS [FromDate] ,
                                        @ENDDATE AS [ToDate] ,

						  -- CAFE PRESS
                                        SUM(ISNULL(s.CP_RepotedHrs, 0)) AS [CP_ReportedHour] ,
                                        SUM(ISNULL(s.CP_ActiveHrs, 0)) AS [CP_ActiveHrs] ,
                                        SUM(ISNULL(s.CP_Designs, 0)) AS [CP_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.CP_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.CP_Designs,
                                                              0)
                                                             / s.CP_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [CP_DesignsPerHr] ,
                                        SUM(ISNULL(s.CP_Cost, 0)) AS [CP_Cost] ,
                                        SUM(ISNULL(s.CP_CostPerDesign, 0)) AS [CP_CostPerDesign] ,

						  -- ZAZZLE
                                        SUM(ISNULL(s.ZZ_RepotedHrs, 0)) AS [ZZ_ReportedHour] ,
                                        SUM(ISNULL(s.ZZ_ActiveHrs, 0)) AS [ZZ_ActiveHrs] ,
                                        SUM(ISNULL(s.ZZ_Designs, 0)) AS [ZZ_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.ZZ_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.ZZ_Designs,
                                                              0)
                                                             / s.ZZ_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [ZZ_DesignsPerHr] ,
                                        SUM(ISNULL(s.ZZ_Cost, 0)) AS [ZZ_Cost] ,
                                        SUM(ISNULL(s.ZZ_CostPerDesign, 0)) AS [ZZ_CostPerDesign] ,

						  -- SHUTTERSTOCK
                                        SUM(ISNULL(s.SS_RepotedHrs, 0)) AS [SS_ReportedHour] ,
                                        SUM(ISNULL(s.SS_ActiveHrs, 0)) AS [SS_ActiveHrs] ,
                                        SUM(ISNULL(s.SS_Designs, 0)) AS [SS_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.SS_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.SS_Designs,
                                                              0)
                                                             / s.SS_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [SS_DesignsPerHr] ,
                                        SUM(ISNULL(s.SS_Cost, 0)) AS [SS_Cost] ,
                                        SUM(ISNULL(s.SS_CostPerDesign, 0)) AS [SS_CostPerDesign] ,

						  -- DREAMSTIME
                                        SUM(ISNULL(s.DT_RepotedHrs, 0)) AS [DT_ReportedHour] ,
                                        SUM(ISNULL(s.DT_ActiveHrs, 0)) AS [DT_ActiveHrs] ,
                                        SUM(ISNULL(s.DT_Designs, 0)) AS [DT_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.DT_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.DT_Designs,
                                                              0)
                                                             / s.DT_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [DT_DesignsPerHr] ,
                                        SUM(ISNULL(s.DT_Cost, 0)) AS [DT_Cost] ,
                                        SUM(ISNULL(s.DT_CostPerDesign, 0)) AS [DT_CostPerDesign] ,

						  -- 123RF
                                        SUM(ISNULL(s.RF_RepotedHrs, 0)) AS [RF_ReportedHour] ,
                                        SUM(ISNULL(s.RF_ActiveHrs, 0)) AS [RF_ActiveHrs] ,
                                        SUM(ISNULL(s.RF_Designs, 0)) AS [RF_Designs] ,
                                        SUM(ISNULL(CASE WHEN ISNULL(s.RF_RepotedHrs,
                                                              0) <> 0
                                                        THEN ISNULL(s.RF_Designs,
                                                              0)
                                                             / s.RF_RepotedHrs
                                                        ELSE 0
                                                   END, 0)) AS [RF_DesignsPerHr] ,
                                        SUM(ISNULL(s.RF_Cost, 0)) AS [RF_Cost] ,
                                        SUM(ISNULL(s.RF_CostPerDesign, 0)) AS [RF_CostPerDesign]
                              FROM      [dbo].[KeyStats_IndiaAdminStats_Snapshot] s
                              WHERE     s.[ActivityDate] >= @BEGINDATE
                                        AND [ActivityDate] <= @ENDDATE
                                        AND s.IsMiscellaneous = 1
                            ) adminStats
                            LEFT JOIN ( SELECT 
										-- ACTIVITY
                                                SUM(ISNULL([PhoneCalls], 0))
                                                / @IndividualCount AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                                SUM(ISNULL([TotalInboundCalls],
                                                           0))
                                                / @IndividualCount AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                                SUM(ISNULL([TotalOutboundCalls],
                                                           0))
                                                / @IndividualCount AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                                ( SUM(ISNULL([TotalForwardCalls],
                                                             0))
                                                  + SUM(ISNULL([TotalInternalCalls],
                                                              0)) )
                                                / @IndividualCount AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN ( SUM(ISNULL([CallDuration],
                                                              0))
                                                            / SUM(ISNULL([PhoneCalls],
                                                              0)) )
                                                          / @IndividualCount
                                                     ELSE NULL
                                                END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                                CASE WHEN SUM(ISNULL([PhoneCalls],
                                                              0)) > 0
                                                     THEN ( SUM(ISNULL([CallDuration],
                                                              0))
                                                            / SUM(ISNULL([PhoneCalls],
                                                              0)) )
                                                          / @IndividualCount
                                                          * 60
                                                     ELSE NULL
                                                END AS [AvgCallDurationMin] , -- AvgCallDurationMin
                                                '-' AS [AvgDailyStart] ,
                                                '-' AS [AvgDailyEnd] ,
                                                SUM(ISNULL(a.[TotalActiveHr],
                                                           0))
                                                / @IndividualCount AS [TotalActiveHrs] , -- TotalActiveHrs
                                                SUM(ISNULL(a.[NonWorkHours], 0))
                                                / @IndividualCount AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                                SUM(ISNULL([KeyStrokes], 0))
                                                / @IndividualCount AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                                SUM(ISNULL([EmailSent], 0))
                                                / @IndividualCount AS [TotalNoOfEmails] -- TotalNoOfEmails
                                        FROM    #Individuals i
                                                LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON LOWER(a.[DirectoryName]) = LOWER(i.username)
                                        WHERE   CAST(a.[SnapshotDate] AS DATE) >= @BEGINDATE
                                                AND CAST(a.[SnapshotDate] AS DATE) <= @ENDDATE
                                                AND i.IsMiscellaneous = 1
                                      ) activity ON 1 = 1
                            LEFT JOIN ( SELECT 
										-- SCORE
                                                SUM(ISNULL(t.[ProofReadingTestA],
                                                           0))
                                                / @IndividualCount AS [NoMatching] , -- NoMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestAAttempt],
                                                           0))
                                                / @IndividualCount AS [NoAccuracy] , -- NoAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[ProofReadingTestB],
                                                           0))
                                                / @IndividualCount AS [WordMatching] , -- WordMatching INT ,
                                                SUM(ISNULL(t.[ProofReadingTestBAttepmt],
                                                           0))
                                                / @IndividualCount AS [WordAccuracy] , -- WordAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[MathTest], 0)) AS [MathTest] , -- MathTest INT ,
                                                SUM(ISNULL(t.[MathTestAttempt],
                                                           0))
                                                / @IndividualCount AS [MathAccuracy] , -- MathAccuracy DECIMAL(10, 2) ,
                                                SUM(ISNULL(t.[TypingTestWPM],
                                                           0))
                                                / @IndividualCount AS [TypingSpeed] , -- TypingSpeed INT ,
                                                SUM(ISNULL(t.[TypingTestAccuracy],
                                                           0))
                                                / @IndividualCount AS [TypingAccuracy] , -- TypingAccuracy INT ,
                                                SUM(ISNULL(t.[BeaconScore], 0))
                                                / @IndividualCount AS [BeaconScore] , -- BeaconScore INT ,
                                                SUM(ISNULL(t.[FicoScore], 0))
                                                / @IndividualCount AS [FICOScore] -- FICOScore INT
                                        FROM    #Individuals i
                                                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON i.UniqueUserId = t.UniqueUserId
                                        WHERE   i.IsMiscellaneous = 1
                                      ) score ON 1 = 1
                )
		
		SELECT * FROM
		(SELECT  *
        FROM    #IndividualStats WHERE HeaderName IN ('BFC Tot.','BFC Avg.')) t1
		UNION ALL
        SELECT  *
        FROM    #IndividualStats WHERE HeaderName NOT IN ('BFC Tot.','BFC Avg.','Misc.<sup></sup>')
		UNION ALL
		SELECT  *
        FROM    #IndividualStats WHERE HeaderName = 'Misc.<sup></sup>'
    END

GO
