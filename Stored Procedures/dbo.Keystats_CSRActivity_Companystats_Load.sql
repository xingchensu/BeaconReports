SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[Keystats_CSRActivity_Companystats_Load]
    (
      @BEGINDATE DATETIME ,
      @ENDDATE DATETIME    
    )
AS
    BEGIN    
    
        SET @ENDDATE = DATEADD(S, -1, DATEADD(DAY, 1, @ENDDATE));    
        DECLARE @TMPBEGINDATE AS DATETIME ,
            @TMPENDDATE AS DATETIME ,
            @LOOPVAR AS SMALLINT ,
            @HEADER AS VARCHAR(50);    
        SET @LOOPVAR = 0;     
    
        IF OBJECT_ID('TempDB..#CSRActivity') IS NOT NULL
            DROP TABLE #CSRActivity;   
        IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL
            DROP TABLE #SpectorDailyAdminDataSnapShot;
        IF OBJECT_ID('tempdb..#CSREmployees') IS NOT NULL
            BEGIN        
                DROP TABLE #CSREmployees;        
            END;  
        SELECT  e.* ,
                e.[FName] + ' ' + e.[LName] AS fullname ,
                e.[LName] + ', ' + e.[FName] AS [fullname2] ,
                r.IsMiscellaneous ,
                edsalary.HourlyPayUSD
        INTO    #CSREmployees
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID
                LEFT JOIN LINK_EDSQL04.[EmbroideryDesigns_Sites].[ADMIN].[vw_PrintArt_SalaryInfo] edsalary ON edsalary.UserName = e.username
        WHERE   c.CategoryID = 11; 
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
                                         THEN 'BFC TOTAL <br/> '
                                              + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @TMPBEGINDATE))
                                         WHEN @LOOPVAR = 1
                                         THEN 'BFC TOTAL <br/> '
                                              + CONVERT(VARCHAR(4), DATEPART(YEAR,
                                                              @TMPBEGINDATE))
                                         WHEN @LOOPVAR = 2
                                         THEN 'BFC TOTAL <br/> '
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPBEGINDATE), 101)
                                              + '-'
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPENDDATE), 101)
                                         WHEN @LOOPVAR = 3
                                         THEN 'BFC TOTAL <br/> '
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPBEGINDATE), 101)
                                              + '-'
                                              + CONVERT(VARCHAR(10), CONVERT(DATE, @TMPENDDATE), 101)
                                    END );    
--SELECT @TMPBEGINDATE BEGINDATE, @TMPENDDATE ENDDATE, @HEADER HEADER    
                IF OBJECT_ID('TempDB..#CSRActivity') IS NULL
                    BEGIN    
                        SELECT  @LOOPVAR + 1 [index] ,
                                @HEADER headerName ,
                                ISNULL(SUM(workHours), 0) workHours ,
                                ISNULL(SUM(expectedWorkHours), 0) expectedWorkHours ,
                                ISNULL(SUM(workedHoursPay), 0) workedHoursPay ,
                                ISNULL(SUM(noOfEmails), 0) mails ,
                                ISNULL(SUM(noOfCalls), 0) calls ,
                                ISNULL(SUM(noOfCDs), 0) cds ,
                                ISNULL(SUM(noOfchats), 0) chats ,
                                ISNULL(SUM(articles), 0) articles ,
                                ISNULL(SUM(projects), 0) projects ,
                                ISNULL(SUM(vendorReview), 0) vendorReview ,
                                ISNULL(SUM(refundReview), 0) refundReview ,
                                ISNULL(SUM(refundAmount), 0) refundAmount ,
                                ISNULL(SUM(refundCount), 0) refundCount ,
                                ISNULL(AVG(avgChatDuration), 0) avgChatDuration ,
                                ISNULL(AVG(avgFirstResponseTime), 0) avgFirstResponseTime ,
                                ISNULL(AVG(avgResponseTime), 0) avgResponseTime ,
                                ISNULL(AVG(avgChatRating), 0) avgChatRating ,
                                ISNULL(SUM(characterCountAgent), 0) charCountAgent ,
                                ISNULL(SUM(characterCountVisitor), 0) charCountVisitor ,
                                ISNULL(SUM(noOfChatLeads), 0) noOfChatLeads
                        INTO    #CSRActivity
                        FROM    dbo.KeyStats_CSRActivity_Load_Snapshot
                        WHERE   activityDate BETWEEN @TMPBEGINDATE
                                             AND     @TMPENDDATE;
                    END;    
                ELSE
                    BEGIN    
                        INSERT  INTO #CSRActivity
                                SELECT  @LOOPVAR + 1 [index] ,
                                        @HEADER headerName ,
                                        ISNULL(SUM(workHours), 0) workHours ,
                                        ISNULL(SUM(expectedWorkHours), 0) expectedWorkHours ,
                                        ISNULL(SUM(workedHoursPay), 0) workedHoursPay ,
                                        ISNULL(SUM(noOfEmails), 0) mails ,
                                        ISNULL(SUM(noOfCalls), 0) calls ,
                                        ISNULL(SUM(noOfCDs), 0) cds ,
                                        ISNULL(SUM(noOfchats), 0) chats ,
                                        ISNULL(SUM(articles), 0) articles ,
                                        ISNULL(SUM(projects), 0) projects ,
                                        ISNULL(SUM(vendorReview), 0) vendorReview ,
                                        ISNULL(SUM(refundReview), 0) refundReview ,
                                        ISNULL(SUM(refundAmount), 0) refundAmount ,
                                        ISNULL(SUM(refundCount), 0) refundCount ,
                                        ISNULL(AVG(avgChatDuration), 0) avgChatDuration ,
                                        ISNULL(AVG(avgFirstResponseTime), 0) avgFirstResponseTime ,
                                        ISNULL(AVG(avgResponseTime), 0) avgResponseTime ,
                                        ISNULL(AVG(avgChatRating), 0) avgChatRating ,
                                        ISNULL(SUM(characterCountAgent), 0) charCountAgent ,
                                        ISNULL(SUM(characterCountVisitor), 0) charCountVisitor ,
                                        ISNULL(SUM(noOfChatLeads), 0) noOfChatLeads
                                FROM    dbo.KeyStats_CSRActivity_Load_Snapshot
                                WHERE   activityDate BETWEEN @TMPBEGINDATE
                                                     AND     @TMPENDDATE;
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
                                AND DirectoryName IN ( SELECT username
                                                       FROM   #CSREmployees );
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
                                        AND DirectoryName IN ( SELECT
                                                              username
                                                              FROM
                                                              #CSREmployees );
                     
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
                WorkHours ,
                expectedWorkHours ,
                workedHoursPay ,
                CONVERT(DECIMAL(10, 2), ISNULL(workedHoursPay
                                               / NULLIF(WorkHours, 0), 0.0)) avgPayPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(mails / NULLIF(WorkHours, 0),
                                               0.0)) mailsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(calls / NULLIF(WorkHours, 0),
                                               0.0)) callsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(cds / NULLIF(WorkHours, 0), 0.0)) cdsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(chats / NULLIF(WorkHours, 0),
                                               0.0)) chatsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(( articles + projects
                                                 + vendorReview + refundReview )
                                               / NULLIF(WorkHours, 0), 0.0)) tasksPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(( mails + calls + cds + chats
                                                 + articles + projects
                                                 + vendorReview + refundReview )
                                               / NULLIF(WorkHours, 0), 0.0)) activitiesPerHr ,
                articles ,
                projects ,
                vendorReview ,
                refundReview ,
                ( articles + projects + vendorReview + refundReview ) tasks ,
                chats noOfChats ,
                avgChatDuration avgChatDuration ,
                avgFirstResponseTime avgFirstResponseTime ,
                avgResponseTime avgResponseTime ,
                avgChatRating avgChatRating ,
                charCountAgent charCountAgent ,
                charCountVisitor charCountVisitor ,
                ( charCountAgent + charCountVisitor ) charCountTotal ,
                ISNULL(noOfChatLeads, 0) noOfChatLeads ,
                refundAmount ,
                refundCount ,
                CONVERT(DECIMAL(10, 2), ISNULL(refundAmount
                                               / NULLIF(refundCount, 0), 0.0)) avgRefund ,
                CONVERT(DECIMAL(10, 2), ISNULL(refundAmount / NULLIF(WorkHours,
                                                              0), 0.0)) refundsPerHr ,
                ISNULL(spec.totalcall, 0) totalCall ,
                ISNULL(spec.totalcallin, 0) totalCallIn ,
                ISNULL(spec.totalcallout, 0) totalCallOut ,
                ISNULL(spec.totalcallint, 0) totalCallInt ,
                ISNULL(spec.avgcalls, 0) avgCalls ,
                CONVERT(DECIMAL	(10,2), ISNULL(spec.avgcalldurationmin, 0)) avgCallDurationMin ,
                ISNULL(spec.DailyStart, '') dailyStart ,
                ISNULL(spec.DailyEnd, 0) dailyEnd ,
                ISNULL(spec.totalActiveHours, 0) totalActiveHours ,
                ISNULL(spec.NonWorkHours, 0) nonWorkHours ,
                ISNULL(spec.keystroke, 0) keyStroke ,
                ISNULL(spec.totalemails, 0) totalEmails,
                startdateminute startdateminute ,
                enddateminute enddateminute
        INTO    #CSRActivityFinal
        FROM    #CSRActivity
                LEFT OUTER JOIN #SpectorSnapshotFinal spec ON spec.DateRangeGroup = #CSRActivity.[index]
        ORDER BY [index];
        
        SELECT  *
        FROM    #CSRActivityFinal
        UNION
        SELECT  5 [index] ,
                'DIFFERENCE' headerName ,
                *
        FROM    ( SELECT    ( CurrentSpan.workHours - PreviousSpan.workHours ) workHours ,
                            ( CurrentSpan.expectedWorkHours
                              - PreviousSpan.expectedWorkHours ) expectedWorkHours ,
                            ( CurrentSpan.workedHoursPay
                              - PreviousSpan.workedHoursPay ) workedHoursPay ,
                            ( CurrentSpan.avgPayPerHr
                              - PreviousSpan.avgPayPerHr ) avgPayPerHr ,
                            ( CurrentSpan.mailsPerHr - PreviousSpan.mailsPerHr ) mailsPerHr ,
                            ( CurrentSpan.callsPerHr - PreviousSpan.callsPerHr ) callsPerHr ,
                            ( CurrentSpan.cdsPerHr - PreviousSpan.cdsPerHr ) cdsPerHr ,
                            ( CurrentSpan.chatsPerHr - PreviousSpan.chatsPerHr ) chatsPerHr ,
                            ( CurrentSpan.tasksPerHr - PreviousSpan.tasksPerHr ) tasksPerHr ,
                            ( CurrentSpan.activitiesPerHr
                              - PreviousSpan.activitiesPerHr ) activitiesPerHr ,
                            ( CurrentSpan.articles - PreviousSpan.articles ) articles ,
                            ( CurrentSpan.projects - PreviousSpan.projects ) projects ,
                            ( CurrentSpan.vendorReview
                              - PreviousSpan.vendorReview ) vendorReview ,
                            ( CurrentSpan.refundReview
                              - PreviousSpan.refundReview ) refundReview ,
                            ( CurrentSpan.tasks - PreviousSpan.tasks ) tasks ,
                            ( CurrentSpan.noOfChats - PreviousSpan.noOfChats ) noOfChats ,
                            ( CurrentSpan.avgChatDuration
                              - PreviousSpan.avgChatDuration ) avgChatDuration ,
                            ( CurrentSpan.avgFirstResponseTime
                              - PreviousSpan.avgFirstResponseTime ) avgFirstResponseTime ,
                            ( CurrentSpan.avgResponseTime
                              - PreviousSpan.avgResponseTime ) avgResponseTime ,
                            ( CurrentSpan.avgChatRating
                              - PreviousSpan.avgChatRating ) avgChatRating ,
                            ( CurrentSpan.charCountAgent
                              - PreviousSpan.charCountAgent ) charCountAgent ,
                            ( CurrentSpan.charCountVisitor
                              - PreviousSpan.charCountVisitor ) charCountVisitor ,
                            ( CurrentSpan.charCountTotal
                              - PreviousSpan.charCountTotal ) charCountTotal ,
                            ( CurrentSpan.noOfChatLeads
                              - PreviousSpan.noOfChatLeads ) noOfChatLeads ,
                            ( CurrentSpan.refundAmount
                              - PreviousSpan.refundAmount ) refundAmount ,
                            ( CurrentSpan.refundCount
                              - PreviousSpan.refundCount ) refundCount ,
                            ( CurrentSpan.avgRefund - PreviousSpan.avgRefund ) avgRefund ,
                            ( CurrentSpan.refundsPerHr
                              - PreviousSpan.refundsPerHr ) refundsPerHr ,
                            ( CurrentSpan.totalCall - PreviousSpan.totalCall ) totalCall ,
                            ( CurrentSpan.totalCallIn - PreviousSpan.totalCallInt ) totalCallIn ,
                            ( CurrentSpan.totalCallOut - PreviousSpan.totalCallOut ) totalCallOut ,
                            ( CurrentSpan.totalCallInt - PreviousSpan.totalCallInt ) totalCallInt ,
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
                            ( CurrentSpan.keyStroke - PreviousSpan.keyStroke ) keyStroke ,
                            ( CurrentSpan.totalEmails
                              - PreviousSpan.totalEmails ) totalEmails,
                              ( CurrentSpan.startdateminute - PreviousSpan.startdateminute ) startdateminute,
                              ( CurrentSpan.enddateminute - PreviousSpan.enddateminute ) enddateminute
                  FROM      #CSRActivityFinal CurrentSpan ,
                            #CSRActivityFinal PreviousSpan
                  WHERE     CurrentSpan.[index] = 3
                            AND PreviousSpan.[index] = 4
                ) AS DifferenceRow
        ORDER BY [index];    
    END;    
    
GO
