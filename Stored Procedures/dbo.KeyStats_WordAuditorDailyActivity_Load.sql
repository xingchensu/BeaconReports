SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[KeyStats_WordAuditorDailyActivity_Load]
    (
      @BEGINDATE AS DATETIME ,
      @ENDDATE AS DATETIME
    )--, @ISACTIVE AS BIT = NULL)  
AS
    BEGIN  
        IF OBJECT_ID('TEMPDB..#AuditorActivity') IS NOT NULL
            BEGIN
                DROP TABLE #AuditorActivity;
            END;

--DECLARE @BEGINDATE DATETIME ,
--    @ENDDATE DATETIME;
--SELECT  @BEGINDATE = '2015/12/01' ,
--        @ENDDATE = '2015/12/10 23:59';

        DECLARE @AUDITORSACT AS TABLE
            (
              userName VARCHAR(150) ,
              reportDate DATETIME ,
              monthDate TINYINT ,
              yearDate SMALLINT ,
              productID INT ,
              characters INT ,
              internal_isAudit BIT ,
              internal_isPopularCleanUp BIT ,
              internal_isCleanUp BIT
            );  
  
        INSERT  INTO @AUDITORSACT
                ( userName ,
                  reportDate ,
                  monthDate ,
                  yearDate ,
                  productID ,
                  characters ,
                  internal_isAudit ,
                  internal_isPopularCleanUp ,
                  internal_isCleanUp
                )
                SELECT  WA.userName ,
                        WA.reportDate ,
                        MONTH(WA.reportDate) AS MonthDate ,
                        YEAR(WA.reportDate) AS YearDate ,
                        COUNT(WA.productID) AS ProductID ,
                        SUM(WA.Characters) AS Characters ,
                        WA.internal_isAudit ,
                        WA.internal_isPopularCleanUp ,
                        WA.internal_isCleanUp
                FROM    ( SELECT    productId ,
                                    MAX(RowID) AS Rowid ,
                                    SUM(internal_Delta_CharacterCount) AS Characters ,
                                    username ,
                                    ReportDate ,
                                    internal_isCleanUp ,
                                    1 AS internal_isAudit ,
                                    0 AS internal_isPopularCleanUp
                          FROM      LINK_DEVECOM04.EmbroideryDesigns_Sites.dbo.KeywordAudits_AuditLog
                                    WITH ( NOLOCK )
                          WHERE     username IN ( 'dzavada', 'jmurphy',
                                                  'ladams', 'MWhitaker',
                                                  'MBremberger', 'JJanusweski',
                                                  'JPiecznski', 'LMulford',
                                                  'KBrownlee', 'Mbabb',
                                                  'rjanowski' )
                                    AND ReportDate BETWEEN @BEGINDATE AND @ENDDATE
                                    AND ReportDate <= '07/26/2015'
                          GROUP BY  productId ,
                                    username ,
                                    ReportDate ,
                                    internal_isCleanUp
                          UNION ALL
                          SELECT    productId ,
                                    MAX(RowID) AS Rowid ,
                                    SUM(internal_Delta_CharacterCount) AS Characters ,
                                    username ,
                                    ReportDate ,
                                    internal_isCleanUp ,
                                    CASE WHEN SUM(internal_NewKeywords_Count) <= 19
                                              AND SUM(internal_OldKeywords_Count) <= 19
                                         THEN 1
                                         ELSE 0
                                    END AS internal_isAudit ,
                                    CASE WHEN SUM(internal_OldKeywords_Count) > 19
                                              AND SUM(internal_NewKeywords_Count) <= 19
                                              AND internal_isCleanUp = 0
                                         THEN 1
                                         ELSE 0
                                    END AS internal_isPopularCleanUp
                          FROM      LINK_DEVECOM04.EmbroideryDesigns_Sites.dbo.KeywordAudits_AuditLog
                                    WITH ( NOLOCK )
                          WHERE     username IN ( 'dzavada', 'jmurphy',
                                                  'ladams', 'MWhitaker',
                                                  'MBremberger', 'JJanusweski',
                                                  'JPiecznski', 'LMulford',
                                                  'KBrownlee', 'lshankar',
                                                  'vvijayan', 'MElice',
                                                  'Mbabb', 'rjanowski' )
                                    AND ReportDate BETWEEN @BEGINDATE AND @ENDDATE
                                    AND ReportDate >= '07/27/2015'
                          GROUP BY  productId ,
                                    username ,
                                    ReportDate ,
                                    internal_isCleanUp
                        ) AS WA
                GROUP BY WA.userName ,
                        WA.reportDate ,
                        WA.internal_isCleanUp ,
                        WA.internal_isAudit ,
                        WA.internal_isPopularCleanUp ,
                        MONTH(WA.reportDate) ,
                        YEAR(WA.reportDate);  
  
        UPDATE  A
        SET     A.productID = A.productID + B.productID ,
                A.characters = A.characters + B.characters
        FROM    @AUDITORSACT A
                INNER JOIN @AUDITORSACT B ON B.userName = A.userName
                                             AND B.reportDate = A.reportDate  
              -- AND B.YearDate = A.YearDate  
        WHERE   A.internal_isAudit = 1
                AND A.internal_isCleanUp = 0
                AND A.internal_isPopularCleanUp = 0
                AND B.internal_isAudit = 0
                AND B.internal_isCleanUp = 0
                AND B.internal_isPopularCleanUp = 0;  
  
        DELETE  w
        FROM    @AUDITORSACT w
                INNER JOIN @AUDITORSACT t ON t.userName = w.userName
                                             AND t.reportDate = w.reportDate  
               --AND t.YearDate = w.YearDate  
                                             AND t.internal_isCleanUp = w.internal_isCleanUp
                                             AND t.internal_isPopularCleanUp = w.internal_isPopularCleanUp
        WHERE   t.internal_isAudit = 1
                AND w.internal_isAudit = 0;  
  
        UPDATE  @AUDITORSACT
        SET     internal_isAudit = 1
        WHERE   internal_isAudit = 0
                AND internal_isCleanUp = 0
                AND internal_isPopularCleanUp = 0;  


        SELECT  t.userName ,
                d.HoursTotal ,
                productID products ,
                characters ,
                internal_isAudit ,
                internal_isPopularCleanUp ,
                internal_isCleanUp ,
                t.reportDate
        INTO    #AuditorActivity
        FROM    @AUDITORSACT t
                INNER JOIN ( SELECT A.userName ,
                                    SUM(A.Number) AS HoursTotal ,
                                    CASE WHEN A.AuditName = 'Audit' THEN 1
                                         ELSE 0
                                    END AS isAudit ,
                                    CASE WHEN A.AuditName = 'CleanUp' THEN 1
                                         ELSE 0
                                    END AS isCleanUp ,
                                    CASE WHEN A.AuditName = '20orLess' THEN 1
                                         ELSE 0
                                    END AS is20orLess ,
                                    A.reportDate
                             FROM   ( SELECT    UserName ,
                                                SUM(Hours) AS Number ,
                                                AuditName ,
                                                DateAudited AS reportDate
                                      FROM      LINK_DEVECOM04.EmbroideryDesigns_Sites.ADMIN.KeywordAdmin_TimeEntry
                                                WITH ( NOLOCK )
                                      WHERE     DateAudited >= '07-27-2015'
                                                AND DateAudited <= CONVERT(VARCHAR(10), @ENDDATE, 110)
                                                AND ( UserName IN ( 'dzavada',
                                                              'jmurphy',
                                                              'ladams',
                                                              'MWhitaker',
                                                              'MBremberger',
                                                              'JJanusweski',
                                                              'JPiecznski',
                                                              'LMulford',
                                                              'KBrownlee',
                                                              'lshankar',
                                                              'vvijayan',
                                                              'MElice',
                                                              'Mbabb',
                                                              'rjanowski' ) )
                                      GROUP BY  UserName ,
                                                AuditName ,
                                                DateAudited
                                      UNION ALL
                                      SELECT    userName ,
                                                Total AS Number ,
                                                AuditName ,
                                                B.reportDate
                                      FROM      ( SELECT    WA.userName ,
                                                            SUM(WA.Total) AS Total ,
                                                            'Audit' AS AuditName ,
                                                            MONTH(WA.reportDate) AS MonthDate ,
                                                            YEAR(WA.reportDate) AS YearDate ,
                                                            WA.reportDate reportDate
                                                  FROM      ( SELECT
                                                              username ,
                                                              ReportDate ,
                                                              Total
                                                              FROM
                                                              LINK_DEVECOM04.EmbroideryDesigns_Sites.dbo.vw_Keyword_TimeEntry_TJM
                                                              WITH ( NOLOCK )
                                                              WHERE
                                                              ( ReportDate BETWEEN CONVERT(VARCHAR(10), @BEGINDATE, 110)
                                                              AND
                                                              '07-26-2015' )
                                                              AND ( username IN (
                                                              'dzavada',
                                                              'jmurphy',
                                                              'ladams',
                                                              'MWhitaker',
                                                              'MBremberger',
                                                              'JJanusweski',
                                                              'JPiecznski',
                                                              'LMulford',
                                                              'KBrownlee',
                                                              'lshankar',
                                                              'vvijayan',
                                                              'MElice',
                                                              'Mbabb',
                                                              'rjanowski' ) )
                                                              GROUP BY username ,
                                                              ReportDate ,
                                                              Total
                                                            ) AS WA
                                                  GROUP BY  WA.userName ,
                                                            MONTH(WA.reportDate) ,
                                                            YEAR(WA.reportDate) ,
                                                            WA.reportDate
                                                ) B
                                      GROUP BY  userName ,
                                                Total ,
                                                AuditName ,
                                                B.reportDate
                                    ) A
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.aspnet_Users u
                                    WITH ( NOLOCK ) ON u.LoweredUserName = LOWER(A.userName)
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.aspnet_ProfileTable p
                                    WITH ( NOLOCK ) ON p.UserId = u.UserId
                             GROUP BY A.userName ,
                                    A.AuditName ,
                                    A.reportDate
                           ) d ON d.reportDate = t.reportDate
                                  AND d.userName = t.userName
                                  AND t.internal_isPopularCleanUp = d.isCleanUp
                                  AND t.internal_isAudit = d.isAudit
                                  AND t.internal_isCleanUp = d.is20orLess;

        INSERT  INTO dbo.KeyStats_WordAuditorActivity_Load_Snapshot
                ( userName ,
                  reportDate ,
                  workHours ,
                  designsHours ,
                  noOfDesigns ,
                  noOfCharacters ,
                  keywordCleanupHours ,
                  noOfDesignsCleaned ,
                  [_20orLessKeywordHours] ,
                  [_20orLessDesignsCleaned]
                )
                SELECT  AuditorActivity.userName ,
                        AuditorActivity.reportDate ,
                        SUM(AuditorActivity.workHours) workHours ,
                        SUM(AuditorActivity.designsHours) designsHours ,
                        SUM(AuditorActivity.noOfDesigns) noOfDesigns ,
                        SUM(AuditorActivity.noOfCharacters) noOfCharacters ,
                        SUM(AuditorActivity.keywordCleanupHours) keywordCleanupHours ,
                        SUM(AuditorActivity.noOfDesignsCleaned) noOfDesignsCleaned ,
                        SUM(AuditorActivity.[_20orLessKeywordHours]) [_20orLessKeywordHours] ,
                        SUM(AuditorActivity.[_20orLessKeywordHours]) [_20orLessKeywordHours]
                FROM    ( SELECT    userName ,
                                    reportDate ,
                                    SUM(HoursTotal) workHours ,
                                    CASE WHEN internal_isAudit = 1
                                         THEN SUM(HoursTotal)
                                         ELSE 0
                                    END designsHours ,
                                    CASE WHEN internal_isAudit = 1
                                         THEN SUM(products)
                                         ELSE 0
                                    END noOfDesigns ,
                                    CASE WHEN internal_isAudit = 1
                                         THEN SUM(characters)
                                         ELSE 0
                                    END noOfCharacters ,
                                    CASE WHEN internal_isPopularCleanUp = 1
                                         THEN SUM(HoursTotal)
                                         ELSE 0
                                    END keywordCleanupHours ,
                                    CASE WHEN internal_isPopularCleanUp = 1
                                         THEN SUM(products)
                                         ELSE 0
                                    END noOfDesignsCleaned ,
                                    CASE WHEN internal_isCleanUp = 1
                                         THEN SUM(HoursTotal)
                                         ELSE 0
                                    END _20orLessKeywordHours ,
                                    CASE WHEN internal_isCleanUp = 1
                                         THEN SUM(products)
                                         ELSE 0
                                    END _20orLessDesignsCleaned
                          FROM      #AuditorActivity
                          WHERE     reportDate BETWEEN @BEGINDATE AND @ENDDATE
                          GROUP BY  userName ,
                                    internal_isAudit ,
                                    internal_isPopularCleanUp ,
                                    internal_isCleanUp ,
                                    reportDate
                        ) AS AuditorActivity
                GROUP BY AuditorActivity.userName ,
                        AuditorActivity.reportDate;
                
                
        UPDATE  AuditorActivity
        SET     AuditorActivity.hourlyPay = ISNULL(AuditorHoursNPay.hourlyPay,
                                                   0) ,
                AuditorActivity.expectedWorkHours = ISNULL(AuditorHoursNPay.expectedWorkHours,
                                                           0) ,
                AuditorActivity.fName = ISNULL(AuditorHoursNPay.fName, '') ,
                AuditorActivity.lName = ISNULL(AuditorHoursNPay.lName, '')
        FROM    dbo.KeyStats_WordAuditorActivity_Load_Snapshot AuditorActivity
                LEFT OUTER JOIN ( SELECT    u.UserName ,
                                            p.FirstName fName ,
                                            p.LastName lName ,
                                            HourlyPayUSD hourlyPay ,
                                            ISNULL(p.ExpHoursPerWeek, 0) / 5 expectedWorkHours
                                  FROM      LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.aspnet_Users u
                                            INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.aspnet_ProfileTable p ON p.UserId = u.UserId
                                            INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Sites.ADMIN.PrintArt_SalaryInfo ON PrintArt_SalaryInfo.UserName = u.UserName
                                ) AuditorHoursNPay ON AuditorHoursNPay.UserName = AuditorActivity.userName
        WHERE   reportDate BETWEEN @BEGINDATE AND @ENDDATE;
    END;  
GO
