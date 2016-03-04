SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[Keystats_CSRActivity_Individualstats_Load]
    (
      @BEGINDATE DATETIME ,
      @ENDDATE DATETIME ,
      @FILTERTYPE VARCHAR(3)
    )
AS
    BEGIN      
      
        SET @ENDDATE = DATEADD(S, -1, DATEADD(DAY, 1, @ENDDATE));      
              
              
      
        IF OBJECT_ID('TempDB..#CSRActivity') IS NOT NULL
            DROP TABLE #CSRActivity;                     
        -- CSR EMPLOYEE DATA : START ===============      
        IF OBJECT_ID('tempdb..#CSREmployees') IS NOT NULL
            BEGIN      
                DROP TABLE #CSREmployees;      
            END;      
        IF OBJECT_ID('tempdb..#CSRTestScores') IS NOT NULL
            BEGIN      
                DROP TABLE #CSRTestScores;      
            END;      
        IF OBJECT_ID('tempdb..#CSRIndividualActivity') IS NOT NULL
            BEGIN      
                DROP TABLE #CSRIndividualActivity;      
            END; 
        IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL
            BEGIN
                DROP TABLE  #SpectorDailyAdminDataSnapShot;
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
-- CSR EMPLOYEE DATA : END ===============      
      
        SELECT  em.UniqueUserId ,
                em.username ,
                em.fullname2 ,
                em.LName lName ,
                ISNULL(t.[MathTest], 0) [MathTest] ,
                ISNULL(t.[MathTestAttempt], 0) [MathTestAttempt] ,
                ISNULL(t.[ProofReadingTestA], 0) [ProofReadingTestA] ,
                ISNULL(t.[ProofReadingTestAAttempt], 0) [ProofReadingTestAAttempt] ,
                ISNULL(t.[ProofReadingTestB], 0) [ProofReadingTestB] ,
                ISNULL(t.[ProofReadingTestBAttepmt], 0) [ProofReadingTestBAttempt] ,
                ISNULL(t.[TypingTestWPM], 0) [TypingTestWPM] ,
                ISNULL(t.[TypingTestAccuracy], 0) [TypingTestAccuracy] ,
                ISNULL(t.[TypingTestKeyStrokes], 0) [TypingTestKeyStrokes] ,
                ISNULL(t.[BeaconScore], 0) [beaconScore] ,
                ISNULL(t.[FicoScore], 0) [ficoScore]
        INTO    #CSRTestScores
        FROM    #CSREmployees em
                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON em.UniqueUserId = t.UniqueUserId;      
               
        SELECT  '~/EmployeeMetrics/CSRStats.aspx?v=IDDD&d='
                + LOWER(@FILTERTYPE) + '&uname=' + LOWER(emp.username) headerName ,
                emp.username ,
                emp.IsMiscellaneous ,
                ISNULL(emp.StartDate, '') startDate ,
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
                RIGHT OUTER JOIN #CSREmployees emp ON emp.username = KeyStats_CSRActivity_Load_Snapshot.userName
                                                      AND activityDate BETWEEN @BEGINDATE AND @ENDDATE
        GROUP BY emp.username ,
                emp.IsMiscellaneous ,
                emp.StartDate;      
      
		
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
                [EmailSent]
        INTO    #SpectorDailyAdminDataSnapShot
        FROM    LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot
        WHERE   [SnapshotDate] BETWEEN @BEGINDATE
                               AND     @ENDDATE
                AND DirectoryName IN ( SELECT   username
                                       FROM     #CSREmployees );
        
        SELECT  DirectoryName userName ,
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
        GROUP BY DirectoryName;
      
      
        SELECT  1 [index] ,
                headerName ,
                'CSRCol'
                + CONVERT(VARCHAR(3), ROW_NUMBER() OVER ( ORDER BY #CSRActivity.username )) className ,
                #CSRActivity.username ,
                #CSRActivity.IsMiscellaneous ,
                #CSRTestScores.fullname2 fullName ,
                lName ,
                startDate ,
                workHours ,
                expectedWorkHours ,
                workedHoursPay ,
                CONVERT(DECIMAL(10, 2), ISNULL(workedHoursPay
                                               / NULLIF(workHours, 0), 0.0)) avgPayPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(mails / NULLIF(workHours, 0),
                                               0.0)) mailsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(calls / NULLIF(workHours, 0),
                                               0.0)) callsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(cds / NULLIF(workHours, 0), 0.0)) cdsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(chats / NULLIF(workHours, 0),
                                               0.0)) chatsPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(( articles + projects
                                                 + vendorReview + refundReview )
                                               / NULLIF(workHours, 0), 0.0)) tasksPerHr ,
                CONVERT(DECIMAL(10, 2), ISNULL(( mails + calls + cds + chats
                                                 + articles + projects
                                                 + vendorReview + refundReview )
                                               / NULLIF(workHours, 0), 0.0)) activitiesPerHr ,
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
                CONVERT(DECIMAL(10, 2), ISNULL(refundAmount / NULLIF(workHours,
                                                              0), 0.0)) refundsPerHr ,
                MathTest ,
                MathTestAttempt ,
                ProofReadingTestA ,
                ProofReadingTestAAttempt ,
                ProofReadingTestB ,
                ProofReadingTestBAttempt ,
                TypingTestWPM ,
                TypingTestAccuracy ,
                TypingTestKeyStrokes ,
                0 JobSpecQues ,
                [beaconScore] ,
                [ficoScore] ,
                ISNULL(totalcall, 0) totalCall ,
                ISNULL(totalcallin, 0) totalCallIn ,
                ISNULL(totalcallout, 0) totalCallOut ,
                ISNULL( totalcallint, 0) totalCallInt ,
                ISNULL(avgcalls, 0) avgCalls ,
                CONVERT(DECIMAL(10, 2), ISNULL(avgcalldurationmin, 0)) avgCallDurationMin ,
                ISNULL(DailyStart, 0) dailyStart ,
                ISNULL(DailyEnd, 0) dailyEnd ,
                ISNULL(totalActiveHours, 0) totalActiveHours ,
                ISNULL(NonWorkHours, 0) nonWorkHours ,
                ISNULL(keystroke, 0) keyStroke ,
                ISNULL(totalemails, 0) totalEmails ,
                startdateminute startdateminute ,
                enddateminute enddateminute
        INTO    #CSRIndividualActivity
        FROM    #CSRActivity
                LEFT OUTER JOIN #CSRTestScores ON #CSRTestScores.username = #CSRActivity.username
                LEFT OUTER JOIN #SpectorSnapshotFinal ON #SpectorSnapshotFinal.userName = #CSRActivity.username
        ORDER BY #CSRActivity.username;      
              
        SELECT  Activity.*
        INTO    #CSRIndividualActivityFinal
        FROM    ( SELECT    1 sortOrder ,
                            100 [index] ,
                            '' headerName ,
                            'BFC_Total' className ,
                            'BFC TOTAL' userName ,
                            'BFC TOTAL' fullName ,
                            'BFC TOTAL' lName ,
                            0 IsMiscellaneous ,
                            '' startDate ,
                            SUM(workHours) workHours ,
                            SUM(expectedWorkHours) expectedWorkHours ,
                            SUM(workedHoursPay) workedHoursPay ,
                            SUM(avgPayPerHr) avgPayPerHr ,
                            SUM(mailsPerHr) mailsPerHr ,
                            SUM(callsPerHr) callsPerHr ,
                            SUM(cdsPerHr) cdsPerHr ,
                            SUM(chatsPerHr) chatsPerHr ,
                            SUM(tasksPerHr) tasksPerHr ,
                            SUM(activitiesPerHr) activitiesPerHr ,
                            SUM(articles) articles ,
                            SUM(projects) projects ,
                            SUM(vendorReview) vendorReview ,
                            SUM(refundReview) refundReview ,
                            SUM(tasks) tasks ,
                            SUM(noOfChats) noOfChats ,
                            SUM(avgChatDuration) avgChatDuration ,
                            SUM(avgFirstResponseTime) avgFirstResponseTime ,
                            SUM(avgResponseTime) avgResponseTime ,
                            SUM(avgChatRating) avgChatRating ,
                            SUM(charCountAgent) charCountAgent ,
                            SUM(charCountVisitor) charCountVisitor ,
                            SUM(charCountTotal) charCountTotal ,
                            SUM(noOfChatLeads) noOfChatLeads ,
                            SUM(refundAmount) refundAmount ,
                            SUM(refundCount) refundCount ,
                            SUM(avgRefund) avgRefund ,
                            SUM(refundsPerHr) refundsPerHr ,
                            SUM(MathTest) MathTest ,
                            SUM(MathTestAttempt) mathAccuracy ,
                            SUM(ProofReadingTestA) numberMatching ,
                            SUM(ProofReadingTestAAttempt) numberAccuracy ,
                            SUM(ProofReadingTestB) wordMatching ,
                            SUM(ProofReadingTestBAttempt) wordAccuracy ,
                            SUM(TypingTestWPM) typingSpeed ,
                            SUM(TypingTestAccuracy) typingAccuracy ,
                            SUM(TypingTestKeyStrokes) typingTestKeyStrokes ,
                            SUM(JobSpecQues) jobSpecQues ,
                            SUM([beaconScore]) beaconScore ,
                            SUM([ficoScore]) ficoScore ,
                            SUM(totalCall) totalCall ,
                            SUM(totalCallIn) totalCallIn ,
                            SUM(totalCallOut) totalCallOut ,
                            SUM(totalCallInt) totalCallInt ,
                            NULL avgCalls ,
                            NULL avgCallDurationMin ,
                            NULL dailyStart ,
                            NULL dailyEnd ,
                            SUM(totalActiveHours) totalActiveHours ,
                            SUM(nonWorkHours) nonWorkHours ,
                            SUM(keyStroke) keyStroke ,
                            SUM(totalEmails) totalEmails ,
                            NULL startdateminute ,
                            NULL enddateminute
                  FROM      #CSRIndividualActivity
                  UNION
                  SELECT    2 sortOrder ,
                            101 [index] ,
                            '' headerName ,
                            'BFC_Avg' className ,
                            'BFC AVG' userName ,
                            'BFC AVG' fullName ,
                            'BFC Avg' lName ,
                            0 IsMiscellaneous ,
                            '' startDate ,
                            AVG(workHours) workHours ,
                            AVG(expectedWorkHours) expectedWorkHours ,
                            AVG(workedHoursPay) workedHoursPay ,
                            AVG(avgPayPerHr) avgPayPerHr ,
                            AVG(mailsPerHr) mailsPerHr ,
                            AVG(callsPerHr) callsPerHr ,
                            AVG(cdsPerHr) cdsPerHr ,
                            AVG(chatsPerHr) chatsPerHr ,
                            AVG(tasksPerHr) tasksPerHr ,
                            AVG(activitiesPerHr) activitiesPerHr ,
                            AVG(articles) articles ,
                            AVG(projects) projects ,
                            AVG(vendorReview) vendorReview ,
                            AVG(refundReview) refundReview ,
                            AVG(tasks) tasks ,
                            AVG(noOfChats) noOfChats ,
                            AVG(avgChatDuration) avgChatDuration ,
                            AVG(avgFirstResponseTime) avgFirstResponseTime ,
                            AVG(avgResponseTime) avgResponseTime ,
                            AVG(avgChatRating) avgChatRating ,
                            AVG(charCountAgent) charCountAgent ,
                            AVG(charCountVisitor) charCountVisitor ,
                            AVG(charCountTotal) charCountTotal ,
                            AVG(noOfChatLeads) noOfChatLeads ,
                            AVG(refundAmount) refundAmount ,
                            AVG(refundCount) refundCount ,
                            AVG(avgRefund) avgRefund ,
                            AVG(refundsPerHr) refundsPerHr ,
                            AVG(MathTest) MathTest ,
                            AVG(MathTestAttempt) mathAccuracy ,
                            AVG(ProofReadingTestA) numberMatching ,
                            AVG(ProofReadingTestAAttempt) numberAccuracy ,
                            AVG(ProofReadingTestB) wordMatching ,
                            AVG(ProofReadingTestBAttempt) wordAccuracy ,
                            AVG(TypingTestWPM) typingSpeed ,
                            AVG(TypingTestAccuracy) typingAccuracy ,
                            AVG(TypingTestKeyStrokes) typingTestKeyStrokes ,
                            AVG(JobSpecQues) jobSpecQues ,
                            AVG([beaconScore]) beaconScore ,
                            AVG([ficoScore]) ficoScore ,
                            AVG(totalCall) totalCall ,
                            AVG(totalCallIn) totalCallIn ,
                            AVG(totalCallOut) totalCallOut ,
                            AVG(totalCallInt) totalCallInt ,
                            AVG(avgCalls) avgCalls ,
                            AVG(avgCallDurationMin) avgCallDurationMin ,
                            ISNULL(CONVERT(VARCHAR(10), AVG(startdateminute)
                                   / 60) + ':'
                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(startdateminute)
                                                   % 60)) = 1
                                          THEN '0'
                                               + CONVERT(VARCHAR(10), AVG(startdateminute)
                                               % 60)
                                          ELSE CONVERT(VARCHAR(10), AVG(startdateminute)
                                               % 60)
                                     END, 0) dailyStart ,
                            ISNULL(CONVERT(VARCHAR(10), AVG(enddateminute)
                                   / 60) + ':'
                                   + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(enddateminute)
                                                   % 60)) = 1
                                          THEN '0'
                                               + CONVERT(VARCHAR(10), AVG(enddateminute)
                                               % 60)
                                          ELSE CONVERT(VARCHAR(10), AVG(enddateminute)
                                               % 60)
                                     END, 0) dailyEnd ,
                            AVG(totalActiveHours) totalActiveHours ,
                            AVG(nonWorkHours) nonWorkHours ,
                            AVG(keyStroke) keyStroke ,
                            AVG(totalEmails) totalEmails ,
                            AVG(startdateminute) startdateminute ,
                            AVG(enddateminute) enddateminute
                  FROM      #CSRIndividualActivity
                  UNION
                  SELECT    3 sortOrder ,
                            [index] ,
                            headerName ,
                            className ,
                            username ,
                            fullName ,
                            lName ,
                            IsMiscellaneous ,
                            startDate ,
                            workHours ,
                            expectedWorkHours ,
                            workedHoursPay ,
                            avgPayPerHr ,
                            mailsPerHr ,
                            callsPerHr ,
                            cdsPerHr ,
                            chatsPerHr ,
                            tasksPerHr ,
                            activitiesPerHr ,
                            articles ,
                            projects ,
                            vendorReview ,
                            refundReview ,
                            tasks ,
                            noOfChats ,
                            avgChatDuration ,
                            avgFirstResponseTime ,
                            avgResponseTime ,
                            avgChatRating ,
                            charCountAgent ,
                            charCountVisitor ,
                            charCountTotal ,
                            noOfChatLeads ,
                            refundAmount ,
                            refundCount ,
                            avgRefund ,
                            refundsPerHr ,
                            MathTest ,
                            MathTestAttempt mathAccuracy ,
                            ProofReadingTestA numberMatching ,
                            ProofReadingTestAAttempt numberAccuracy ,
                            ProofReadingTestB wordMatching ,
                            ProofReadingTestBAttempt wordAccuracy ,
                            TypingTestWPM typingSpeed ,
                            TypingTestAccuracy typingAccuracy ,
                            TypingTestKeyStrokes ,
                            JobSpecQues ,
                            [beaconScore] ,
                            [ficoScore] ,
                            totalCall totalCall ,
                            totalCallIn totalCallIn ,
                            totalCallOut totalCallOut ,
                            totalCallInt totalCallInt ,
                            avgCalls ,
                            avgCallDurationMin ,
                            dailyStart ,
                            dailyEnd ,
                            totalActiveHours ,
                            nonWorkHours nonWorkHours ,
                            keyStroke keyStroke ,
                            totalEmails totalEmails ,
                            startdateminute ,
                            enddateminute
                  FROM      #CSRIndividualActivity      
                  --ORDER BY  sortOrder ,      
                  --          username      
                ) AS Activity;      
                      
                --SELECT * FROM #CSRIndividualActivityFinal      
                      
        UPDATE  Activity
        SET     userName = 'Misc' ,
                fullName = 'Misc' ,
                lName = 'Misc' ,
                sortOrder = 4 ,
                startDate = '' ,
                headerName = REPLACE(headerName, userName, 'Misc') ,
                className = 'CSRCol'
                + CONVERT(VARCHAR(3), ( SELECT  COUNT(*) + 2
                                        FROM    #CSRIndividualActivityFinal
                                        WHERE   sortOrder = 3
                                                AND IsMiscellaneous = 0
                                      ))
        FROM    #CSRIndividualActivityFinal Activity
        WHERE   IsMiscellaneous = 1;      
                      
                      
        SELECT  sortOrder ,
                [index] ,
                headerName ,
                className ,
                userName ,
                fullName ,
                lName ,
                CONVERT(BIT, IsMiscellaneous) IsMiscellaneous ,
                startDate ,
                SUM(workHours) workHours ,
                SUM(expectedWorkHours) expectedWorkHours ,
                SUM(workedHoursPay) workedHoursPay ,
                SUM(avgPayPerHr) avgPayPerHr ,
                SUM(mailsPerHr) mailsPerHr ,
                SUM(callsPerHr) callsPerHr ,
                SUM(cdsPerHr) cdsPerHr ,
                SUM(chatsPerHr) chatsPerHr ,
                SUM(tasksPerHr) tasksPerHr ,
                SUM(activitiesPerHr) activitiesPerHr ,
                SUM(articles) articles ,
                SUM(projects) projects ,
                SUM(vendorReview) vendorReview ,
                SUM(refundReview) refundReview ,
                SUM(tasks) tasks ,
                SUM(noOfChats) noOfChats ,
                SUM(avgChatDuration) avgChatDuration ,
                SUM(avgFirstResponseTime) avgFirstResponseTime ,
                SUM(avgResponseTime) avgResponseTime ,
                SUM(avgChatRating) avgChatRating ,
                SUM(charCountAgent) charCountAgent ,
                SUM(charCountVisitor) charCountVisitor ,
                SUM(charCountTotal) charCountTotal ,
                SUM(noOfChatLeads) noOfChatLeads ,
                SUM(refundAmount) refundAmount ,
                SUM(refundCount) refundCount ,
                SUM(avgRefund) avgRefund ,
                SUM(refundsPerHr) refundsPerHr ,
                SUM(MathTest) MathTest ,
                SUM(mathAccuracy) mathAccuracy ,
                SUM(numberMatching) numberMatching ,
                SUM(numberAccuracy) numberAccuracy ,
                SUM(wordMatching) wordMatching ,
                SUM(wordAccuracy) wordAccuracy ,
                SUM(typingSpeed) typingSpeed ,
                SUM(typingAccuracy) typingAccuracy ,
                SUM(typingTestKeyStrokes) typingTestKeyStrokes ,
                SUM(jobSpecQues) jobSpecQues ,
                SUM([beaconScore]) beaconScore ,
                SUM([ficoScore]) ficoScore ,
                SUM(totalCall) totalCall ,
                SUM(totalCallIn) totalCallIn ,
                SUM(totalCallOut) totalCallOut ,
                SUM(totalCallInt) totalCallInt ,
                AVG(avgCalls) avgCalls ,
                CONVERT(DECIMAL(10,2), AVG(avgCallDurationMin)) avgCallDurationMin ,
                ISNULL(CONVERT(VARCHAR(10), AVG(startdateminute) / 60) + ':'
                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(startdateminute)
                                       % 60)) = 1
                              THEN '0'
                                   + CONVERT(VARCHAR(10), AVG(startdateminute)
                                   % 60)
                              ELSE CONVERT(VARCHAR(10), AVG(startdateminute)
                                   % 60)
                         END, 0) dailyStart ,
                ISNULL(CONVERT(VARCHAR(10), AVG(enddateminute) / 60) + ':'
                       + CASE WHEN LEN(CONVERT(VARCHAR(10), AVG(enddateminute)
                                       % 60)) = 1
                              THEN '0'
                                   + CONVERT(VARCHAR(10), AVG(enddateminute)
                                   % 60)
                              ELSE CONVERT(VARCHAR(10), AVG(enddateminute)
                                   % 60)
                         END, 0) dailyEnd ,
                SUM(totalActiveHours) totalActiveHours ,
                SUM(nonWorkHours) nonWorkHours ,
                SUM(keyStroke) keyStroke ,
                SUM(totalEmails) totalEmails ,
                AVG(startdateminute) startdateminute ,
                AVG(enddateminute) enddateminute
        FROM    #CSRIndividualActivityFinal
        GROUP BY sortOrder ,
                [index] ,
                headerName ,
                className ,
                userName ,
                fullName ,
                lName ,
                IsMiscellaneous ,
                startDate
        ORDER BY sortOrder ,
                IsMiscellaneous ,
                userName;      
                      
        --SELECT * FROM #CSRIndividualActivityFinal      
    END;      
          
GO
