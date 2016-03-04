SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 07/12/2015
-- Description:	To load the company stats 

-- Test: [dbo].[KeyStats_IndiaAdmin_LoadCompanyStats] '01/01/2015', '12/11/2015'
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_IndiaAdmin_LoadCompanyStats]
    @BEGINDATE AS DATETIME ,
    @ENDDATE AS DATETIME ,
    @IsMisc AS BIT = NULL ,
    @USERNAME AS VARCHAR(25) = NULL ,
    @Shift AS INT = NULL
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
    
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

        IF OBJECT_ID('tempdb..#CompanyStats') IS NOT NULL 
            BEGIN  
                DROP TABLE #CompanyStats
            END

        CREATE TABLE #CompanyStats
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
              TotalNoOfEmails INT
            );

        DECLARE @counter AS INT = 1;
        DECLARE @fromDate AS DATE = NULL;
        DECLARE @toDate AS DATE = NULL;
        DECLARE @header AS VARCHAR(MAX) = NULL;

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
                                THEN 'BFC Total<br/>'
                                     + CAST(YEAR(@TwoYearsBeforeTo) AS VARCHAR(MAX))
                                WHEN 2
                                THEN 'BFC Total<br/>'
                                     + CAST(YEAR(@LastYearTo) AS VARCHAR(MAX))
                                WHEN 3
                                THEN 'BFC Total<br/>'
                                     + CONVERT(VARCHAR(10), @BEGINDATE, 1)
                                     + ' - ' + CONVERT(VARCHAR(10), @ENDDATE, 1)
                                WHEN 4
                                THEN 'BFC Total<br/>'
                                     + CONVERT(VARCHAR(10), @LastYearSamePeriodFrom, 1)
                                     + ' - '
                                     + CONVERT(VARCHAR(10), @LastYearSamePeriodTo, 1)
                                ELSE NULL
                              END;

                INSERT  INTO #CompanyStats
                        ( CSSINDEX ,
                          HeaderName ,
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
                          TotalNoOfEmails
                        )
                        ( SELECT    *
                          FROM      ( SELECT    @counter AS [CSSINDEX] ,
                                                @header AS [HeaderName] ,
                                                @fromDate AS [FromDate] ,
                                                @toDate AS [ToDate] ,

								-- CAFE PRESS
                                                SUM(ISNULL(s.CP_RepotedHrs, 0)) AS [CP_ReportedHour] ,
                                                SUM(ISNULL(s.CP_ActiveHrs, 0)) AS [CP_ActiveHrs] ,
                                                SUM(ISNULL(s.CP_Designs, 0)) AS [CP_Designs] ,
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.CP_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.CP_Designs,
                                                              0)
                                                              / s.CP_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [CP_DesignsPerHr] ,
                                                SUM(ISNULL(s.CP_Cost, 0)) AS [CP_Cost] ,
                                                SUM(ISNULL(s.CP_CostPerDesign,
                                                           0)) AS [CP_CostPerDesign] ,

								-- ZAZZLE
                                                SUM(ISNULL(s.ZZ_RepotedHrs, 0)) AS [ZZ_ReportedHour] ,
                                                SUM(ISNULL(s.ZZ_ActiveHrs, 0)) AS [ZZ_ActiveHrs] ,
                                                SUM(ISNULL(s.ZZ_Designs, 0)) AS [ZZ_Designs] ,
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.ZZ_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.ZZ_Designs,
                                                              0)
                                                              / s.ZZ_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [ZZ_DesignsPerHr] ,
                                                SUM(ISNULL(s.ZZ_Cost, 0)) AS [ZZ_Cost] ,
                                                SUM(ISNULL(s.ZZ_CostPerDesign ,
                                                           0)) AS [ZZ_CostPerDesign] ,

								-- SHUTTERSTOCK
                                                SUM(ISNULL(s.SS_RepotedHrs, 0)) AS [SS_ReportedHour] ,
                                                SUM(ISNULL(s.SS_ActiveHrs, 0)) AS [SS_ActiveHrs] ,
                                                SUM(ISNULL(s.SS_Designs, 0)) AS [SS_Designs] ,
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.SS_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.SS_Designs,
                                                              0)
                                                              / s.SS_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [SS_DesignsPerHr] ,
                                                SUM(ISNULL(s.SS_Cost, 0)) AS [SS_Cost] ,
                                                SUM(ISNULL(s.SS_CostPerDesign,
                                                           0)) AS [SS_CostPerDesign] ,

								-- DREAMSTIME
                                                SUM(ISNULL(s.DT_RepotedHrs, 0)) AS [DT_ReportedHour] ,
                                                SUM(ISNULL(s.DT_ActiveHrs, 0)) AS [DT_ActiveHrs] ,
                                                SUM(ISNULL(s.DT_Designs, 0)) AS [DT_Designs] ,
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.DT_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.DT_Designs,
                                                              0)
                                                              / s.DT_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [DT_DesignsPerHr] ,
                                                SUM(ISNULL(s.DT_Cost, 0)) AS [DT_Cost] ,
                                                SUM(ISNULL(s.DT_CostPerDesign,
                                                           0)) AS [DT_CostPerDesign] ,

								-- 123RF
                                                SUM(ISNULL(s.RF_RepotedHrs, 0)) AS [RF_ReportedHour] ,
                                                SUM(ISNULL(s.RF_ActiveHrs, 0)) AS [RF_ActiveHrs] ,
                                                SUM(ISNULL(s.RF_Designs, 0)) AS [RF_Designs] ,
                                                SUM(ISNULL(CASE
                                                              WHEN ISNULL(s.RF_RepotedHrs,
                                                              0) <> 0
                                                              THEN ISNULL(s.RF_Designs,
                                                              0)
                                                              / s.RF_RepotedHrs
                                                              ELSE 0
                                                           END, 0)) AS [RF_DesignsPerHr] ,
                                                SUM(ISNULL(s.RF_Cost, 0)) AS [RF_Cost] ,
                                                SUM(ISNULL(s.RF_CostPerDesign,
                                                           0)) AS [RF_CostPerDesign]
                                      FROM      [dbo].[KeyStats_IndiaAdminStats_Snapshot] s
                                      WHERE     s.[ActivityDate] >= @fromDate
                                                AND [ActivityDate] <= @toDate
                                                AND (LOWER(s.username) = LOWER(@USERNAME) OR @USERNAME IS NULL)
												AND (s.[shift] = @Shift OR @Shift IS NULL)
												AND (s.IsMiscellaneous = @IsMisc OR @IsMisc IS NULL)
                                    ) adminStats
                                    LEFT JOIN ( SELECT  SUM(ISNULL([PhoneCalls] ,0)) AS [NoOfTotalCalls] , -- NoOfTotalCalls
                                                        SUM(ISNULL([TotalInboundCalls] ,0)) AS [NoOfIncomingCalls] , -- NoOfIncomingCalls
                                                        SUM(ISNULL([TotalOutboundCalls] ,0)) AS [NoOfOutgiongCalls] , -- NoOfOutgiongCalls
                                                        SUM(ISNULL([TotalForwardCalls] ,0))
                                                        + SUM(ISNULL([TotalInternalCalls] ,0)) AS [NoOfInternalForwardedCalls] , -- NoOfInternalForwardedCalls
                                                        CASE WHEN SUM(ISNULL([PhoneCalls] ,0)) > 0
                                                             THEN SUM(ISNULL([CallDuration] ,0))
                                                              / SUM(ISNULL([PhoneCalls] ,0))
                                                             ELSE NULL
                                                        END AS [NoOfAvgCallsPerDay] , -- NoOfAvgCallsPerDay
                                                        CASE WHEN SUM(ISNULL([PhoneCalls] ,0)) > 0
                                                             THEN SUM(ISNULL([CallDuration] ,0))
                                                              / SUM(ISNULL([PhoneCalls] ,0))
                                                              * 60
                                                             ELSE NULL
                                                        END AS [AvgCallDurationMin] , -- AvgCallDurationMin
                                                        ISNULL(CONVERT(VARCHAR(10), AVG(ISNULL([DailyStartMin], 0))
                                                              / 60) + ':'
                                                              + CASE
                                                              WHEN LEN(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin], 0))
                                                              % 60)) = 1
                                                              THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin], 0))
                                                              % 60)
                                                              ELSE CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyStartMin], 0))
                                                              % 60)
                                                              END, 0) AS [AvgDailyStart] ,
                                                        ISNULL(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin], 0))
                                                              / 60) + ':'
                                                              + CASE
                                                              WHEN LEN(CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin], 0))
                                                              % 60)) = 1
                                                              THEN '0'
                                                              + CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin], 0))
                                                              % 60)
                                                              ELSE CONVERT(VARCHAR(10), AVG(ISNULL(a.[DailyEndMin], 0))
                                                              % 60)
                                                              END, 0) AS [AvgDailyEnd] ,
                                                        SUM(ISNULL(a.[TotalActiveHr] ,0)) AS [TotalActiveHrs] , -- TotalActiveHrs
                                                        SUM(ISNULL(a.[NonWorkHours] ,0)) AS [TotalNonWorkHrs] , -- TotalNonWorkHrs
                                                        SUM(ISNULL([KeyStrokes] ,0)) AS [TotalNoOfKeystrokes] , -- TotalNoOfKeystrokes
                                                        SUM(ISNULL([EmailSent] ,0)) AS [TotalNoOfEmails] -- TotalNoOfEmails
                                                FROM    #Individuals i
                                                        LEFT JOIN LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot a ON LOWER(a.[DirectoryName]) = LOWER(i.username)
                                                WHERE   CAST(a.[SnapshotDate] AS DATE) >= @fromDate
                                                        AND CAST(a.[SnapshotDate] AS DATE) <= @toDate
                                                        AND (i.[shift] = @Shift OR @Shift IS NULL)
														AND (i.IsMiscellaneous = @IsMisc OR @IsMisc IS NULL)
                                              ) activity ON 1 = 1
                        )

                SET @counter = @counter + 1;
            END
  
  
		-- Calculate the difference column
        INSERT  INTO #CompanyStats
                ( CSSINDEX ,
                  HeaderName ,
						 
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
                  TotalNoOfEmails
                        
                )
                SELECT  5 AS [CSSINDEX] ,
                        'Difference' AS [HeaderName] ,
						
						-- CAFE PRESS
                        ISNULL(t1.CP_ReportedHour, 0)
                        - ISNULL(t2.CP_ReportedHour, 0) ,
                        ISNULL(t1.CP_ActiveHrs, 0) - ISNULL(t2.CP_ActiveHrs, 0) ,
                        ISNULL(t1.CP_Designs, 0) - ISNULL(t2.CP_Designs, 0) ,
                        ISNULL(t1.CP_DesignsPerHr, 0)
                        - ISNULL(t2.CP_DesignsPerHr, 0) ,
                        ISNULL(t1.CP_Cost, 0) - ISNULL(t2.CP_Cost, 0) ,
                        ISNULL(t1.CP_CostPerDesign, 0)
                        - ISNULL(t2.CP_CostPerDesign, 0) ,
						
						-- ZAZZLE                      
                        ISNULL(t1.ZZ_ReportedHour, 0)
                        - ISNULL(t2.ZZ_ReportedHour, 0) ,
                        ISNULL(t1.ZZ_ActiveHrs, 0) - ISNULL(t2.ZZ_ActiveHrs, 0) ,
                        ISNULL(t1.ZZ_Designs, 0) - ISNULL(t2.ZZ_Designs, 0) ,
                        ISNULL(t1.ZZ_DesignsPerHr, 0)
                        - ISNULL(t2.ZZ_DesignsPerHr, 0) ,
                        ISNULL(t1.ZZ_Cost, 0) - ISNULL(t2.ZZ_Cost, 0) ,
                        ISNULL(t1.ZZ_CostPerDesign, 0)
                        - ISNULL(t2.ZZ_CostPerDesign, 0) ,
						
						-- SHUTTERSTOCK
                        ISNULL(t1.SS_ReportedHour, 0)
                        - ISNULL(t2.SS_ReportedHour, 0) ,
                        ISNULL(t1.SS_ActiveHrs, 0) - ISNULL(t2.SS_ActiveHrs, 0) ,
                        ISNULL(t1.SS_Designs, 0) - ISNULL(t2.SS_Designs, 0) ,
                        ISNULL(t1.SS_DesignsPerHr, 0)
                        - ISNULL(t2.SS_DesignsPerHr, 0) ,
                        ISNULL(t1.SS_Cost, 0) - ISNULL(t2.SS_Cost, 0) ,
                        ISNULL(t1.SS_CostPerDesign, 0)
                        - ISNULL(t2.SS_CostPerDesign, 0) ,
						
						-- DREAMSTIME
                        ISNULL(t1.DT_ReportedHour, 0)
                        - ISNULL(t2.DT_ReportedHour, 0) ,
                        ISNULL(t1.DT_ActiveHrs, 0) - ISNULL(t2.DT_ActiveHrs, 0) ,
                        ISNULL(t1.DT_Designs, 0) - ISNULL(t2.DT_Designs, 0) ,
                        ISNULL(t1.DT_DesignsPerHr, 0)
                        - ISNULL(t2.DT_DesignsPerHr, 0) ,
                        ISNULL(t1.DT_Cost, 0) - ISNULL(t2.DT_Cost, 0) ,
                        ISNULL(t1.DT_CostPerDesign, 0)
                        - ISNULL(t2.DT_CostPerDesign, 0) ,
						
						-- 123RF
                        ISNULL(t1.RF_ReportedHour, 0)
                        - ISNULL(t2.RF_ReportedHour, 0) ,
                        ISNULL(t1.RF_ActiveHrs, 0) - ISNULL(t2.RF_ActiveHrs, 0) ,
                        ISNULL(t1.RF_Designs, 0) - ISNULL(t2.RF_Designs, 0) ,
                        ISNULL(t1.RF_DesignsPerHr, 0)
                        - ISNULL(t2.RF_DesignsPerHr, 0) ,
                        ISNULL(t1.RF_Cost, 0) - ISNULL(t2.RF_Cost, 0) ,
                        ISNULL(t1.RF_CostPerDesign, 0)
                        - ISNULL(t2.RF_CostPerDesign, 0) ,
						
						-- ACTIVITY
                        ISNULL(t1.NoOfTotalCalls, 0)
                        - ISNULL(t2.NoOfTotalCalls, 0) ,
                        ISNULL(t1.NoOfIncomingCalls, 0)
                        - ISNULL(t2.NoOfIncomingCalls, 0) ,
                        ISNULL(t1.NoOfOutgiongCalls, 0)
                        - ISNULL(t2.NoOfOutgiongCalls, 0) ,
                        ISNULL(t1.NoOfInternalForwardedCalls, 0)
                        - ISNULL(t2.NoOfInternalForwardedCalls, 0) ,
                        ISNULL(t1.NoOfAvgCallsPerDay, 0)
                        - ISNULL(t2.NoOfAvgCallsPerDay, 0) ,
                        ISNULL(t1.AvgCallDurationMin, 0)
                        - ISNULL(t2.AvgCallDurationMin, 0) ,
                        '-' ,
                        '-' ,
                        ISNULL(t1.TotalActiveHrs, 0)
                        - ISNULL(t2.TotalActiveHrs, 0) ,
                        ISNULL(t1.TotalNonWorkHrs, 0)
                        - ISNULL(t2.TotalNonWorkHrs, 0) ,
                        ISNULL(t1.TotalNoOfKeystrokes, 0)
                        - ISNULL(t2.TotalNoOfKeystrokes, 0) ,
                        ISNULL(t1.TotalNoOfEmails, 0)
                        - ISNULL(t2.TotalNoOfEmails, 0)
                FROM    #CompanyStats t1 ,
                        #CompanyStats t2
                WHERE   t1.[CSSINDEX] = 3
                        AND t2.[CSSINDEX] = 4;
		          
        SELECT  *
        FROM    #CompanyStats;
    END

GO
