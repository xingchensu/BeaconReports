SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[Keystats_AuditorActivity_IndividualDrillDown_Load]
    (
      @BEGINDATE DATETIME ,
      @ENDDATE DATETIME ,
      @USERNAME AS VARCHAR(50)
    )
AS
    BEGIN          
          
        SET @ENDDATE = DATEADD(S, -1, DATEADD(DAY, 1, @ENDDATE));          
        DECLARE @TMPBEGINDATE AS DATETIME ,
            @TMPENDDATE AS DATETIME ,
            @LOOPVAR AS SMALLINT ,
            @HEADER AS VARCHAR(50) ,
            @STARTDATE AS VARCHAR(10) ,
            @FULLNAME VARCHAR(75);          
        SET @LOOPVAR = 0;           
        IF OBJECT_ID('TempDB..#AuditorActivity') IS NOT NULL
            DROP TABLE #AuditorActivity;       
        IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL
            DROP TABLE #SpectorDailyAdminDataSnapShot;      
        IF OBJECT_ID('tempdb..#AuditorEmployees') IS NOT NULL
            BEGIN              
                DROP TABLE #AuditorEmployees;              
            END;      
        SELECT  e.* ,
                e.[FName] + ' ' + e.[LName] AS fullname ,
                e.[LName] + ', ' + e.[FName] AS [fullname2] ,
                r.IsMiscellaneous ,
                edsalary.HourlyPayUSD
        INTO    #AuditorEmployees
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID
                LEFT JOIN LINK_EDSQL04.[EmbroideryDesigns_Sites].[ADMIN].[vw_PrintArt_SalaryInfo] edsalary ON edsalary.UserName = e.username
        WHERE   c.CategoryID = 12
                AND e.username = @USERNAME;      
        PRINT 'HI';     
        SELECT  @STARTDATE = StartDate ,
                @FULLNAME = [fullname2]
        FROM    #AuditorEmployees;            
        WHILE ( @LOOPVAR < 4 )
            BEGIN          
          
                SELECT  @TMPBEGINDATE = ( CASE WHEN @LOOPVAR = 0
                                               THEN CONVERT(DATETIME, '01/01/'
                                                    + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @BEGINDATE) - 2))
                                               WHEN @LOOPVAR = 1
                                               THEN CONVERT(DATETIME, '01/01/'
                                                    + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @BEGINDATE) - 1))
                                               WHEN @LOOPVAR = 2
                                               THEN @BEGINDATE
                                               WHEN @LOOPVAR = 3
                                               THEN CONVERT(DATETIME, CONVERT(VARCHAR(2), DATEPART(MONTH,
                                                              @BEGINDATE))
                                                    + '/'
                                                    + CONVERT(VARCHAR(2), DATEPART(DAY,
                                                              @BEGINDATE))
                                                    + '/'
                                                    + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @BEGINDATE) - 1))
                                          END ) ,
                        @TMPENDDATE = ( CASE WHEN @LOOPVAR = 0
                                             THEN CONVERT(DATETIME, '01/01/'
                                                  + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @ENDDATE) - 2)
                                                  + ' 23:59:59')
                                             WHEN @LOOPVAR = 1
                                             THEN CONVERT(DATETIME, '01/01/'
                                                  + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @ENDDATE) - 1)
                                                  + ' 23:59:59')
                                             WHEN @LOOPVAR = 2 THEN @ENDDATE
                                             WHEN @LOOPVAR = 3
                                             THEN CONVERT(DATETIME, CONVERT(VARCHAR(2), DATEPART(MONTH,
                                                              @ENDDATE)) + '/'
                                                  + CONVERT(VARCHAR(2), DATEPART(DAY,
                                                              @ENDDATE)) + '/'
                                                  + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @ENDDATE) - 1)
                                                  + ' 23:59:59')
                                        END );          
                SELECT  @HEADER = ( CASE WHEN @LOOPVAR = 0
                                         THEN @USERNAME + '<br/> '
                                              + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @TMPBEGINDATE))
                                         WHEN @LOOPVAR = 1
                                         THEN @USERNAME + '<br/> '
                                              + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @TMPBEGINDATE))
                                         WHEN @LOOPVAR = 2
                                         THEN @USERNAME + '<br/> '
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPBEGINDATE), 101)
                                              + '-'
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPENDDATE), 101)
                                         WHEN @LOOPVAR = 3
                                         THEN @USERNAME + '<br/> '
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPBEGINDATE), 101)
                                              + '-'
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPENDDATE), 101)
                                    END );          
                                          
                IF OBJECT_ID('TempDB..#AuditorActivity') IS NULL
                    BEGIN              
                        SELECT  @LOOPVAR + 1 [index] ,
                                @HEADER headerName ,
                                ISNULL(SUM(workHours), 0) workHours ,
                                ISNULL(SUM(expectedWorkHours), 0) expectedWorkHours ,
                                ISNULL(SUM(workedHoursPay), 0) workedHoursPay ,
                                ISNULL(SUM(designsHours), 0) designsHours ,
                                ISNULL(SUM(noOfDesigns), 0) noOfDesigns ,
                                ISNULL(SUM(noOfCharacters), 0) noOfCharacters ,
                                ISNULL(SUM(keywordCleanupHours), 0) keywordCleanupHours ,
                                ISNULL(SUM(noOfDesignsCleaned), 0) noOfDesignsCleaned ,
                                ISNULL(SUM(_20orLessKeywordHours), 0) _20orLessKeywordHours ,
                                ISNULL(SUM(_20orLessDesignsCleaned), 0) _20orLessDesignsCleaned
                        INTO    #AuditorActivity
                        FROM    KeyStats_WordAuditorActivity_Load_Snapshot
                        WHERE   reportDate BETWEEN @TMPBEGINDATE AND @TMPENDDATE;           
                    END;        
                ELSE
                    BEGIN        
                        INSERT  INTO #AuditorActivity
                                SELECT  @LOOPVAR + 1 [index] ,
                                        @HEADER headerName ,
                                        ISNULL(SUM(workHours), 0) workHours ,
                                        ISNULL(SUM(expectedWorkHours), 0) expectedWorkHours ,
                                        ISNULL(SUM(workedHoursPay), 0) workedHoursPay ,
                                        ISNULL(SUM(designsHours), 0) designsHours ,
                                        ISNULL(SUM(noOfDesigns), 0) noOfDesigns ,
                                        ISNULL(SUM(noOfCharacters), 0) noOfCharacters ,
                                        ISNULL(SUM(keywordCleanupHours), 0) keywordCleanupHours ,
                                        ISNULL(SUM(noOfDesignsCleaned), 0) noOfDesignsCleaned ,
                                        ISNULL(SUM(_20orLessKeywordHours), 0) _20orLessKeywordHours ,
                                        ISNULL(SUM(_20orLessDesignsCleaned), 0) _20orLessDesignsCleaned
                                FROM    KeyStats_WordAuditorActivity_Load_Snapshot
                                WHERE   reportDate BETWEEN @TMPBEGINDATE AND @TMPENDDATE;        
                    END;    
                IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NULL
                    BEGIN        
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
                                @LOOPVAR + 1 AS DateRangeGroup
                        INTO    #SpectorDailyAdminDataSnapShot
                        FROM    LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
                        WHERE   [SnapshotDate] BETWEEN @TMPBEGINDATE
                                               AND     @TMPENDDATE
                                AND DirectoryName IN (
                                SELECT  username
                                FROM    #AuditorEmployees );        
                    END;        
                ELSE
                    BEGIN        
                        INSERT  INTO #SpectorDailyAdminDataSnapShot
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
                                        @LOOPVAR + 1 AS DateRangeGroup
                                FROM    LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
                                WHERE   [SnapshotDate] BETWEEN @TMPBEGINDATE
                                                       AND    @TMPENDDATE
                                        AND DirectoryName IN (
                                        SELECT  username
                                        FROM    #AuditorEmployees );        
                             
                    END;        
                SET @LOOPVAR = @LOOPVAR + 1;           
            END;    
                
        SELECT  DateRangeGroup ,
                SUM([TotalActiveHr]) AS totalActiveHours ,
                SUM([NonWorkHours]) AS [NonWorkHours] ,
                SUM(TotalHours) AS [totalWorkHours] ,
                AVG([DailyStartMin]) AS startdateminute ,
                AVG([DailyEndMin]) AS enddateminute ,
                ISNULL(CONVERT(VARCHAR(10), AVG([DailyStartMin]) / 60) + ':'
                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                       % 60)) = 1
                              THEN '0'
                                   + CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                   % 60)
                              ELSE CONVERT(VARCHAR(10), AVG([DailyStartMin])
                                   % 60)
                         END, 0) AS [DailyStart] ,
                ISNULL(CONVERT(VARCHAR(10), AVG([DailyEndMin]) / 60) + ':'
                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                       % 60)) = 1
                              THEN '0'
                                   + CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                   % 60)
                              ELSE CONVERT(VARCHAR(10), AVG([DailyEndMin])
                                   % 60)
                         END, 0) AS [DailyEnd] ,
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
                     THEN SUM([CallDuration]) / SUM([PhoneCalls]) * 60
                     ELSE NULL
                END AS avgcalldurationmin ,
                SUM([TotalInboundCalls]) AS totalcallin ,
                SUM([TotalOutboundCalls]) AS totalcallout ,
                SUM([TotalForwardCalls]) + SUM([TotalInternalCalls]) AS totalcallint ,
                SUM([KeyStrokes]) AS keystroke ,
                SUM([EmailSent]) AS totalemails
        INTO    #SpectorSnapshotFinal
        FROM    #SpectorDailyAdminDataSnapShot
        GROUP BY DateRangeGroup;        
                  
        SELECT  [index] ,
                headerName ,
                @STARTDATE startDate ,
                @FULLNAME fullName ,
                workHours genTotalHours ,
                expectedWorkHours genExpectedHours ,
                workedHoursPay genTotalPay ,
                CONVERT(DECIMAL(10, 2), ISNULL(workedHoursPay
                                               / NULLIF(workHours, 0), 0.0)) genAvgPayPerHour ,
                designsHours destotalHours ,
                noOfDesigns desTotalDesigns ,
                noOfCharacters desTotalCharacters ,
                CONVERT(DECIMAL(10, 2), ISNULL(noOfDesigns
                                               / NULLIF(designsHours, 0), 0.0)) desDesignsPerHour ,
                CONVERT(DECIMAL(10, 2), ISNULL(noOfCharacters
                                               / NULLIF(designsHours, 0), 0.0)) desCharPerHour ,
                CONVERT(DECIMAL(10, 2), ISNULL(( ( ISNULL(workedHoursPay
                                                          / NULLIF(workHours,
                                                              0), 0.0) )
                                                 / NULLIF(ISNULL(noOfDesigns
                                                              / NULLIF(designsHours,
                                                              0), 0.0), 0.0) ),
                                               0)) desCostPerDesign ,
                keywordCleanupHours keyTotalHours ,
                noOfDesignsCleaned keyDesignsCleaned ,
                CONVERT(DECIMAL(10, 2), ISNULL(noOfDesignsCleaned
                                               / NULLIF(keywordCleanupHours, 0),
                                               0.0)) keyDesignsPerHour ,
                CONVERT(DECIMAL(10, 2), ISNULL(( ( ISNULL(workedHoursPay
                                                          / NULLIF(workHours,
                                                              0), 0.0) )
                                                 / NULLIF(ISNULL(noOfDesignsCleaned
                                                              / NULLIF(keywordCleanupHours,
                                                              0), 0.0), 0.0) ),
                                               0)) keyCostPerDesign ,
                [_20orLessKeywordHours] less20TotalHours ,
                [_20orLessDesignsCleaned] less20DesignsCleaned ,
                CONVERT(DECIMAL(10, 2), ISNULL([_20orLessDesignsCleaned]
                                               / NULLIF([_20orLessKeywordHours],
                                                        0), 0.0)) less20DesignsPerHour ,
                CONVERT(DECIMAL(10, 2), ISNULL(( ( ISNULL(workedHoursPay
                                                          / NULLIF(workHours,
                                                              0), 0.0) )
                                                 / NULLIF(ISNULL([_20orLessDesignsCleaned]
                                                              / NULLIF([_20orLessKeywordHours],
                                                              0), 0.0), 0.0) ),
                                               0)) less20CostPerDesign ,
                ISNULL(spec.totalcall, 0) totalCall ,
                ISNULL(spec.totalcallin, 0) totalCallIn ,
                ISNULL(spec.totalcallout, 0) totalCallOut ,
                ISNULL(spec.totalcallint, 0) totalCallInt ,
                ISNULL(spec.avgcalls, 0) avgCalls ,
                CONVERT(DECIMAL(10, 2), ISNULL(spec.avgcalldurationmin, 0)) avgCallDurationMin ,
                ISNULL(spec.DailyStart, '') dailyStart ,
                ISNULL(spec.DailyEnd, 0) dailyEnd ,
                ISNULL(spec.totalActiveHours, 0) totalActiveHours ,
                ISNULL(spec.NonWorkHours, 0) nonWorkHours ,
                ISNULL(spec.keystroke, 0) keyStroke ,
                ISNULL(spec.totalemails, 0) totalEmails ,
                startdateminute startdateminute ,
                enddateminute enddateminute
        INTO    #AuditorActivityFinal
        FROM    #AuditorActivity
                LEFT OUTER JOIN #SpectorSnapshotFinal spec ON spec.DateRangeGroup = #AuditorActivity.[index]
        ORDER BY [index];  
        SELECT  *
        INTO    #FINALRESULT
        FROM 
        ( SELECT    *
          FROM      #AuditorActivityFinal
          UNION
          SELECT    5 [index] ,
                    'DIFFERENCE' headerName ,
                    '' startDate ,
                    '' fullName ,
                    *
          FROM      ( SELECT    ( CurrentSpan.genTotalHours
                                  - PreviousSpan.genTotalHours ) genTotalHours ,
                                ( CurrentSpan.genExpectedHours
                                  - PreviousSpan.genExpectedHours ) genExpectedHours ,
                                ( CurrentSpan.genTotalPay
                                  - PreviousSpan.genTotalPay ) genTotalPay ,
                                ( CurrentSpan.genAvgPayPerHour
                                  - PreviousSpan.genAvgPayPerHour ) genAvgPayPerHour ,
                                ( CurrentSpan.destotalHours
                                  - PreviousSpan.destotalHours ) destotalHours ,
                                ( CurrentSpan.desTotalDesigns
                                  - PreviousSpan.desTotalDesigns ) desTotalDesigns ,
                                ( CurrentSpan.desTotalCharacters
                                  - PreviousSpan.desTotalCharacters ) desTotalCharacters ,
                                ( CurrentSpan.desDesignsPerHour
                                  - PreviousSpan.desDesignsPerHour ) desDesignsPerHour ,
                                ( CurrentSpan.desCharPerHour
                                  - PreviousSpan.desCharPerHour ) desCharPerHour ,
                                ( CurrentSpan.desCostPerDesign
                                  - PreviousSpan.desCostPerDesign ) desCostPerDesign ,
                                ( CurrentSpan.keyTotalHours
                                  - PreviousSpan.keyTotalHours ) keyTotalHours ,
                                ( CurrentSpan.keyDesignsCleaned
                                  - PreviousSpan.keyDesignsCleaned ) keyDesignsCleaned ,
                                ( CurrentSpan.keyDesignsPerHour
                                  - PreviousSpan.keyDesignsPerHour ) keyDesignsPerHour ,
                                ( CurrentSpan.keyCostPerDesign
                                  - PreviousSpan.keyCostPerDesign ) keyCostPerDesign ,
                                ( CurrentSpan.less20TotalHours
                                  - PreviousSpan.less20TotalHours ) less20TotalHours ,
                                ( CurrentSpan.less20DesignsCleaned
                                  - PreviousSpan.less20DesignsCleaned ) less20DesignsCleaned ,
                                ( CurrentSpan.less20DesignsPerHour
                                  - PreviousSpan.less20DesignsPerHour ) less20DesignsPerHour ,
                                ( CurrentSpan.less20CostPerDesign
                                  - PreviousSpan.less20CostPerDesign ) less20CostPerDesign ,
                                ( CurrentSpan.totalCall
                                  - PreviousSpan.totalCall ) totalCall ,
                                ( CurrentSpan.totalCallIn
                                  - PreviousSpan.totalCallInt ) totalCallIn ,
                                ( CurrentSpan.totalCallOut
                                  - PreviousSpan.totalCallOut ) totalCallOut ,
                                ( CurrentSpan.totalCallInt
                                  - PreviousSpan.totalCallInt ) totalCallInt ,
                                ( CurrentSpan.avgCalls - PreviousSpan.avgCalls ) avgCalls ,
                                ( CurrentSpan.avgCallDurationMin
                                  - PreviousSpan.avgCallDurationMin ) avgCallDurationMin ,
                                CAST(CurrentSpan.startdateminute
                                - PreviousSpan.startdateminute AS VARCHAR(10))
                                + ' min' dailyStart ,
                                CAST(CurrentSpan.enddateminute
                                - PreviousSpan.enddateminute AS VARCHAR(10))
                                + ' min' dailyEnd ,
                                ( CurrentSpan.totalActiveHours
                                  - PreviousSpan.totalActiveHours ) totalActiveHours ,
                                ( CurrentSpan.nonWorkHours
                                  - PreviousSpan.nonWorkHours ) nonWorkHours ,
                                ( CurrentSpan.keyStroke
                                  - PreviousSpan.keyStroke ) keyStroke ,
                                ( CurrentSpan.totalEmails
                                  - PreviousSpan.totalEmails ) totalEmails ,
                                ( CurrentSpan.startdateminute
                                  - PreviousSpan.startdateminute ) startdateminute ,
                                ( CurrentSpan.enddateminute
                                  - PreviousSpan.enddateminute ) enddateminute
                      FROM      #AuditorActivityFinal CurrentSpan ,
                                #AuditorActivityFinal PreviousSpan
                      WHERE     CurrentSpan.[index] = 3
                                AND PreviousSpan.[index] = 4
                    ) AS DifferenceRow
        )  RES;
        
        --SELECT COLS.name, COLS.max_length, TYP.name FROM tempdb.SYS.columns COLS
        --INNER JOIN sys.TYPES TYP ON COLS.system_type_id = TYP.system_type_id
        --WHERE COLS.[OBJECT_ID] =
        --OBJECT_ID('TEMPDB..#FINALRESULT') ORDER BY COLS.column_id
        --SELECT * FROM tempdb.SYS.columns COLS
        
        --WHERE COLS.[OBJECT_ID] =
        --OBJECT_ID('TEMPDB..#FINALRESULT')
        SELECT * FROM #FINALRESULT
    END; 
GO
