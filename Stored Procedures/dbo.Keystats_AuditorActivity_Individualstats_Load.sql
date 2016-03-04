SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[Keystats_AuditorActivity_Individualstats_Load]    
    (    
      @BEGINDATE DATETIME ,    
      @ENDDATE DATETIME ,    
      @FILTERTYPE VARCHAR(3)    
    )    
AS    
    BEGIN            
            
        SET @ENDDATE = DATEADD(S, -1, DATEADD(DAY, 1, @ENDDATE));            
              
        IF OBJECT_ID('TempDB..#AuditorActivity') IS NOT NULL    
            DROP TABLE #AuditorActivity;                           
               
        IF OBJECT_ID('tempdb..#AuditorEmployees') IS NOT NULL    
            BEGIN            
                DROP TABLE #AuditorEmployees;            
            END;            
        IF OBJECT_ID('tempdb..#AuditorTestScores') IS NOT NULL    
            BEGIN            
                DROP TABLE #AuditorTestScores;            
            END;            
        IF OBJECT_ID('tempdb..#AuditorIndividualActivity') IS NOT NULL    
            BEGIN            
                DROP TABLE #AuditorIndividualActivity;            
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
        INTO    #AuditorEmployees    
        FROM    [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e    
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID = e.Company    
                                                              AND r.EmployeeID = e.UserID    
                INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c ON c.CategoryID = r.CategoryID    
                LEFT JOIN LINK_EDSQL04.[EmbroideryDesigns_Sites].[ADMIN].[vw_PrintArt_SalaryInfo] edsalary ON edsalary.UserName = e.username    
        WHERE   c.CategoryID = 12;          
            
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
        INTO    #AuditorTestScores    
        FROM    #AuditorEmployees em    
                LEFT JOIN [dbo].[KeyStats_Employee_TestScore] t ON em.UniqueUserId = t.UniqueUserId;       
            
            
        SELECT  '~/EmployeeMetrics/WordAuditorStats.aspx?v=IDDD&d='    
                + LOWER(@FILTERTYPE) + '&uname=' + LOWER(emp.username) headerName ,    
                emp.username ,    
                emp.IsMiscellaneous ,    
                ISNULL(emp.StartDate, '') startDate ,    
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
                RIGHT OUTER JOIN #AuditorEmployees emp ON emp.username = KeyStats_WordAuditorActivity_Load_Snapshot.userName    
                                                          AND reportDate BETWEEN @BEGINDATE AND @ENDDATE    
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
        WHERE   [SnapshotDate] BETWEEN @BEGINDATE AND @ENDDATE    
                AND DirectoryName IN ( SELECT   username    
                                       FROM     #AuditorEmployees );    
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
                'AudCol'    
                + CONVERT(VARCHAR(3), ROW_NUMBER() OVER ( ORDER BY #AuditorActivity.username )) className ,    
                #AuditorActivity.username ,    
                #AuditorActivity.IsMiscellaneous ,    
                #AuditorTestScores.fullname2 fullName ,    
                lName ,    
                startDate ,    
                workHours genTotalHours ,    
                expectedWorkHours genExpectedHours ,    
                workedHoursPay genTotalPay ,    
                CONVERT(DECIMAL(10, 2), ISNULL(workedHoursPay    
                                               / NULLIF(workHours, 0), 0.0)) genAvgPayPerHr ,    
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
                ISNULL(totalcallint, 0) totalCallInt ,    
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
        INTO    #AuditorIndividualActivity    
        FROM    #AuditorActivity    
                LEFT OUTER JOIN #AuditorTestScores ON #AuditorTestScores.username = #AuditorActivity.username    
                LEFT OUTER JOIN #SpectorSnapshotFinal ON #SpectorSnapshotFinal.userName = #AuditorActivity.username    
        ORDER BY #AuditorActivity.username;      
             PRINT 'hi';
        SELECT  Activity.*    
        INTO    #AuditorIndividualActivityFinal    
        FROM    ( SELECT    1 sortOrder ,    
                            100 [index] ,    
                            '' headerName ,    
                            'BFC_Total' className ,    
                            'BFC TOTAL' userName ,    
                            'BFC TOTAL' fullName ,    
                            'BFC TOTAL' lName ,    
                            0 IsMiscellaneous ,    
                            '' startDate ,    
                            SUM(genTotalHours) genTotalHours ,    
                            SUM(genExpectedHours) genExpectedHours ,    
                            SUM(genTotalPay) genTotalPay ,    
                            CONVERT(DECIMAL(10, 2), AVG(genAvgPayPerHr)) genAvgPayPerHour ,    
                            SUM(destotalHours) desTotalHours ,    
                            SUM(desTotalDesigns) desTotalDesigns ,    
                            SUM(desTotalCharacters) desTotalCharacters ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(SUM(desTotalDesigns)    
                                                           / NULLIF(SUM(destotalHours),    
                                                              0), 0)) desDesignsPerHour ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(SUM(desTotalCharacters)    
                                                           / NULLIF(SUM(destotalHours),    
                                                              0), 0)) desCharPerHour ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(SUM(desTotalDesigns)    
                                                              / NULLIF(SUM(destotalHours),    
                                                              0), 0), 0)) desCostPerDesign ,    
                            SUM(keyTotalHours) keyTotalHours ,    
                            SUM(keyDesignsCleaned) keyDesignsCleaned ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(SUM(keyDesignsCleaned)    
                                                           / NULLIF(SUM(keyTotalHours),    
                                                              0), 0)) keyDesignsPerHour ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(SUM(keyDesignsCleaned)    
                                                              / NULLIF(SUM(keyTotalHours),    
                                                              0), 0), 0)) keyCostPerDesign ,    
                            SUM(less20TotalHours) less20TotalHours ,    
                            SUM(less20DesignsCleaned) less20DesignsCleaned ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(SUM(less20DesignsCleaned)    
                                                           / NULLIF(SUM(less20TotalHours),0),    
                                                         0)) less20DesignsPerHour ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(SUM(less20DesignsCleaned)    
                                                              / NULLIF(SUM(less20TotalHours),    
                                                              0), 0), 0)) less20CostPerDesign ,    
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
                  FROM      #AuditorIndividualActivity    
                  UNION    
                  SELECT    2 sortOrder ,    
                            101 [index] ,    
                            '' headerName ,    
                            'BFC_Avg' className ,    
                            'BFC AVG' userName ,    
                            'BFC AVG' fullName ,    
                            'BFC AVG' lName ,    
                            0 IsMiscellaneous ,    
                            '' startDate ,    
                            CONVERT(DECIMAL(10, 2), AVG(genTotalHours)) genTotalHours ,    
                            CONVERT(DECIMAL(10, 2), AVG(genExpectedHours)) genExpectedHours ,    
                            CONVERT(DECIMAL(10, 2), AVG(genTotalPay)) genTotalPay ,    
                            CONVERT(DECIMAL(10, 2), AVG(genAvgPayPerHr)) genAvgPayPerHr ,    
                            AVG(destotalHours) desTotalHours ,    
                            AVG(desTotalDesigns) desTotalDesigns ,    
                            AVG(desTotalCharacters) desTotalCharacters ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(desTotalDesigns)    
                                                           / NULLIF(AVG(destotalHours),    
                                                              0), 0)) desDesignsPerHr ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(desTotalCharacters)    
                                                           / NULLIF(AVG(destotalHours),    
                                                              0), 0)) desCharPerHr ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(AVG(desTotalDesigns)    
                                                              / NULLIF(AVG(destotalHours),    
                                                              0), 0), 0)) desCostPerDesign ,    
                            AVG(keyTotalHours) keyTotalHours ,    
                            AVG(keyDesignsCleaned) keyDesignsCleaned ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(keyDesignsCleaned)    
                                                           / NULLIF(AVG(keyTotalHours),    
                                                              0), 0)) keyDesignsPerHr ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(AVG(keyDesignsCleaned)    
                                                              / NULLIF(AVG(keyTotalHours),    
                                                              0), 0), 0)) keyCostPerDesign ,    
                            AVG(less20TotalHours) less20TotalHours ,    
                            AVG(less20DesignsCleaned) less20DesignsCleaned ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(less20DesignsCleaned)    
                                                           / NULLIF(AVG(less20TotalHours),0),    
                                                           0)) less20DesignsPerHour ,    
                            CONVERT(DECIMAL(10, 2), ISNULL(AVG(genAvgPayPerHr)    
                                                           / NULLIF(AVG(less20DesignsCleaned)    
                                                              / NULLIF(AVG(less20TotalHours),    
                                                              0), 0), 0)) less20CostPerDesign ,    
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
                  FROM      #AuditorIndividualActivity    
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
                            genTotalHours ,    
                            genExpectedHours ,    
                            genTotalPay ,    
                            genAvgPayPerHr genAvgPayPerHour ,    
                            destotalHours ,    
                            desTotalDesigns ,    
                            desTotalCharacters ,    
                            desDesignsPerHour ,    
                            desCharPerHour ,    
                            desCostPerDesign ,    
                            keyTotalHours ,    
                            keyDesignsCleaned ,    
                            keyDesignsPerHour ,    
                            keyCostPerDesign ,    
                            less20TotalHours ,    
                            less20DesignsCleaned ,    
                            less20DesignsPerHour ,    
                            less20CostPerDesign ,    
                            MathTest ,    
                            MathTestAttempt mathAccuracy ,    
                            ProofReadingTestA numberMatching ,    
                            ProofReadingTestAAttempt numberAccuracy ,    
                            ProofReadingTestB wordMatching ,    
                            ProofReadingTestBAttempt wordAccuracy ,    
                            TypingTestWPM typingSpeed ,    
                            TypingTestAccuracy typingAccuracy ,    
                            TypingTestKeyStrokes typingTestKeyStrokes ,    
                            JobSpecQues jobSpecQues ,    
                            [beaconScore] beaconScore ,    
                            [ficoScore] ficoScore ,    
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
                  FROM      #AuditorIndividualActivity    
                ) AS Activity;       
              
        UPDATE  Activity    
        SET     userName = 'Misc' ,    
                fullName = 'Misc' ,    
                lName = 'Misc' ,    
                sortOrder = 4 ,    
                startDate = '' ,    
                headerName = REPLACE(headerName, userName, 'Misc') ,    
                className = 'AudCol'    
                + CONVERT(VARCHAR(3), ( SELECT  MAX(CONVERT(INT, REPLACE(className,    
                                                              'AudCol', '')))    
                                                + 1    
                                        FROM    #AuditorIndividualActivityFinal    
                                        WHERE   sortOrder = 3    
                                                AND IsMiscellaneous = 0    
                             ))    
        FROM    #AuditorIndividualActivityFinal Activity    
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
                SUM(genTotalHours) genTotalHours ,    
                SUM(genExpectedHours) genExpectedHours ,    
                SUM(genTotalPay) genTotalPay ,    
                SUM(genAvgPayPerHour) genAvgPayPerHour ,    
                SUM(desTotalHours) desTotalHours ,    
                SUM(desTotalDesigns) desTotalDesigns ,    
                SUM(desTotalCharacters) desTotalCharacters ,    
                SUM(desDesignsPerHour) desDesignsPerHour ,    
                SUM(desCharPerHour) desCharPerHour ,    
                SUM(desCostPerDesign) desCostPerDesign ,    
                SUM(keyTotalHours) keyTotalHours ,    
                SUM(keyDesignsCleaned) keyDesignsCleaned ,    
                SUM(keyDesignsPerHour) keyDesignsPerHour ,    
                SUM(keyCostPerDesign) keyCostPerDesign ,    
                SUM(less20TotalHours) less20TotalHours ,    
                SUM(less20DesignsCleaned) less20DesignsCleaned ,    
                SUM(less20DesignsPerHour) less20DesignsPerHour ,    
                SUM(less20CostPerDesign) less20CostPerDesign ,    
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
                CONVERT(DECIMAL(10, 2), AVG(avgCallDurationMin)) avgCallDurationMin ,    
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
        FROM    #AuditorIndividualActivityFinal    
        GROUP BY sortOrder ,    
                [index] ,    
                headerName ,    
                className ,    
                userName ,    
                fullName ,    
                lName ,    
                IsMiscellaneous ,    
                startDate;    
    END;      
GO
