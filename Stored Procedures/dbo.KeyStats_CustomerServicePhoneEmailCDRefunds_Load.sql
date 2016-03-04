SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[KeyStats_CustomerServicePhoneEmailCDRefunds_Load]
    (
      @BeginDate DATETIME = NULL ,
      @EndDate DATETIME = NULL--,            
    )
AS
    BEGIN            
        IF OBJECT_ID('tempDB..#ActivityDates') IS NOT NULL
            BEGIN            
                DROP TABLE #ActivityDates;            
            END;            
        IF OBJECT_ID('tempDB..#Users') IS NOT NULL
            BEGIN            
                DROP TABLE #Users;            
            END;            
        IF OBJECT_ID('tempDB..#UserActivityDates') IS NOT NULL
            BEGIN            
                DROP TABLE #UserActivityDates;            
            END;            
        IF OBJECT_ID('tempDB..#PhoneCallDetails') IS NOT NULL
            BEGIN            
                DROP TABLE #PhoneCallDetails;            
            END;            
        IF OBJECT_ID('tempDB..#TEMPFINALACTIVITY') IS NOT NULL
            BEGIN            
                DROP TABLE #TEMPFINALACTIVITY;            
            END;
            WITH    runningDate
                      AS ( SELECT   CAST(@BeginDate AS DATETIME) DateValue
                           UNION ALL
                           SELECT   DateValue + 1
                           FROM     runningDate
                           WHERE    DateValue + 1 <= @EndDate
                         )
            SELECT  runningDate.DateValue
            INTO    #ActivityDates
            FROM    runningDate
        OPTION  ( MAXRECURSION 0 );            
            
 --SELECT * FROM #ActivityDates            
        CREATE TABLE #Users
            (
              FirstName VARCHAR(100) ,
              LastName VARCHAR(100) ,
              UserName AS ( SUBSTRING(FirstName, 1, 1) ) + ( LastName ) ,
              HourlyPay DECIMAL(10, 2)
            );            
        INSERT  INTO #Users
                ( FirstName, LastName, HourlyPay )
        VALUES  ( 'Bonnie', 'Landsberger', 0 ),
                ( 'Cindy', 'Colosimo', 0 ),
                ( 'Sue', 'Gerhardt', 0 ),
                ( 'Roberta', 'Erickson', 0 ),
                ( 'Marie', 'Geschke', 0 );--,            
 --('Vicki', 'OBrien')            
        UPDATE  Usrs
        SET     Usrs.HourlyPay = PayDet.payPerHour
        FROM    #Users Usrs
                INNER JOIN dbo.KeyStats_HourlyPay PayDet ON PayDet.userName = Usrs.UserName
        WHERE   activeStatus = 1
                AND categoryID = 11;            
        SELECT  * ,
                CONVERT(DECIMAL(10, 2), 0) expectedWorkHours
        INTO    #UserActivityDates
        FROM    #Users
                FULL OUTER JOIN #ActivityDates ON 1 = 1;            
           
        UPDATE  UAD
        SET     UAD.expectedWorkHours = ( SELECT    expectedWorkHours / 5
                                          FROM      dbo.[KeyStats_ExpectedHours] expHours
                                          WHERE     expHours.userName = UAD.UserName
                                                    AND expHours.activeStatus = 1
                                        )
        FROM    #UserActivityDates UAD;            
            
            
 --UPDATE UAD SET UAD.expectedWorkHours=(SELECT  CASE DATENAME(DW, DateValue) WHEN 'SATURDAY' THEN 0 WHEN 'SUNDAY' THEN 0 ELSE expectedworkhours/5  END FROM             
 -- dbo.[KeyStats_ExpectedHours] expHours WHERE expHours.userName = uad.UserName AND exphours.activestatus  =1 ) FROM #UserActivityDates UAD            
            
        CREATE TABLE #PhoneCallDetails
            (
              First_Name VARCHAR(100) ,
              Last_Name VARCHAR(100) ,
              UserName VARCHAR(100) ,
              HourlyPay DECIMAL(10, 2) ,
              PhoneMonth INT ,
              PhoneYear INT ,
              TotalCall INT ,
              ActivityDate DATETIME ,
              ExpectedWorkHours DECIMAL(10, 2)
            );            
        INSERT  INTO #PhoneCallDetails
                ( First_Name ,
                  Last_Name ,
                  UserName ,
                  HourlyPay ,
                  PhoneMonth ,
                  PhoneYear ,
                  TotalCall ,
                  ActivityDate ,
                  ExpectedWorkHours
                )
                SELECT  FirstName First_Name ,
                        LastName Last_Name ,
                        UserName ,
                        HourlyPay ,
                        MONTH(DateValue) PhoneMonth ,
                        YEAR(DateValue) PhoneYear ,
                        COUNT(First_Name) AS TotalCall ,
                        DateValue ActivityDate ,
                        expectedWorkHours
                FROM    #UserActivityDates
                        LEFT OUTER JOIN LINK_SQLPROD01.MicroTelCall.dbo.UNION_vw_Call_Details Calls ON #UserActivityDates.DateValue = Date_Only
                                                              AND Calls.First_Name = FirstName
                                                              AND Calls.Last_Name = LastName
                                                              AND ( ( First_Name = 'Bonnie'
                                                              AND Last_Name = 'Landsberger'
                                                              )
                                                              OR ( First_Name = 'Cindy'
                                                              AND Last_Name = 'Colosimo'
                                                              )
                                                              OR ( First_Name = 'Sue'
                                                              AND Last_Name = 'Gerhardt'
                                                              )
                                                              OR ( First_Name = 'Roberta' )
                                                              OR ( First_Name = 'Marie'
                                                              AND Last_Name = 'Geschke'
                                                              )
                                                              )
                                                              AND Date_Time BETWEEN @BeginDate AND @EndDate            
 -- OR (First_Name = 'Vicki' AND Last_Name = 'OBrien')            
                GROUP BY FirstName ,
                        LastName ,
                        #UserActivityDates.DateValue ,
                        UserName ,
                        HourlyPay ,
                        expectedWorkHours
                ORDER BY #UserActivityDates.DateValue;         
           
 --DELETE FROM #PhoneCallDetails  WHERE UserName IN( SELECT UserName FROM #PhoneCallDetails GROUP BY UserName HAVING (SUM(TotalCall)) =0)            
 --TO DO: Replcae TotalChats once New Chat Tool is implemented            
        SELECT  '1' AS DummyColumn ,
                Phone.ActivityDate ,
                Phone.PhoneMonth EntryMonth ,
                Phone.PhoneYear EntryYear ,
                Phone.UserName AS Username ,
                ISNULL(Phone.TotalCall, 0) TotalCall ,
                ISNULL(Flex.EntryTotal, 0) EntryTotal ,
                ISNULL(Email.TotatEmails, 0) AS TotalEmails ,
                ISNULL(CD.Memo, 0) AS CDs ,
                0 AS TotalChats ,
                ISNULL(Refunds.RefundAmount, 0) AS Refund ,
                ISNULL(Refunds.TotalRefundCount, 0) TotalRefundCount ,
                Phone.HourlyPay ,
                ISNULL(Projects.articles, 0) TotalArticles ,
                ISNULL(Projects.projects, 0) TotalProjects ,
                Phone.ExpectedWorkHours
        INTO    #tempFinalActivity
        FROM    #PhoneCallDetails Phone
                LEFT JOIN --BEGIN FLEX BLOCK            
                ( SELECT    MONTH(EntryDate) AS EntryMonth ,
                            YEAR(EntryDate) AS EntryYear ,
                            SUM(FT.Total) AS EntryTotal ,
                            username ,
                            FT.EntryDate -- ADDED ENTRYDATE            
                  FROM      Intranet_Beaconfunding.dbo.vw_FlexTime FT
                  WHERE     FT.username IN ( 'ccolosimo', 'rerickson',
                                             'sgerhardt', 'blandsberger',
                                             'mgeschke' )
                            AND EntryDate BETWEEN @BeginDate AND @EndDate
                  GROUP BY  UserID ,
                            username ,
                            MONTH(EntryDate) ,
                            YEAR(EntryDate) ,
                            FT.EntryDate
                ) AS Flex ON Flex.EntryDate = Phone.ActivityDate
                             AND Flex.UserName = Phone.UserName            
  --END FLEX BLOCK            
            
            
  --BEGIN EMAILS BLOCK            
                LEFT JOIN ( SELECT  Username ,
                                    MONTH(SentDate_Only) AS SentMonth ,
                                    YEAR(SentDate_Only) AS SentYear ,
                                    COUNT(*) AS TotatEmails ,
                                    SentDate_Only EntryDate
                            FROM    LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.vw_Admin_CustomerService_EmailLogs
                            WHERE   Username IN ( 'ccolosimo', 'rerickson',
                                                  'sgerhardt', 'blandsberger',
                                                  'mgeschke' )
                                    AND SentDate_Only BETWEEN @BeginDate AND @EndDate
                            GROUP BY Username ,
                                    MONTH(SentDate_Only) ,
                                    YEAR(SentDate_Only) ,
                                    SentDate_Only
                          ) AS Email ON Flex.UserName = Email.UserName
                                        AND Flex.EntryMonth = Email.SentMonth
                                        AND Flex.EntryYear = Email.SentYear
                                        AND Email.EntryDate = Flex.EntryDate             
  --END EMAILS BLOCK            
            
            
  --BEGIN  MEMOS(CDs) BLOCK            
                LEFT JOIN ( SELECT  CSR_Name ,
                                    DateCreated ,
                                    DateMonth ,
                                    DateYear ,
                                    COUNT(Memo) AS Memo
                            FROM    ( SELECT    CSR_Name ,
                                                MONTH(DateCreated) AS DateMonth ,
                                                YEAR(DateCreated) AS DateYear ,
                                                1 AS Memo ,
                                                DATEADD(DAY,
                                                        DATEDIFF(DAY, 0,
                                                              DateCreated), 0) DateCreated
                                      FROM      LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.[vw_Admin_CustomerService_Ship-A-CD]
                                      WHERE     DateCreated BETWEEN @BeginDate AND @EndDate
                                                AND CSR_Name <> ''
                                      UNION ALL
                                      SELECT    CSR_Name ,
                                                MONTH(DateCreated) AS DateMonth ,
                                                YEAR(DateCreated) AS DateYear ,
                                                1 AS Memo ,
                                                DATEADD(DAY,
                                                        DATEDIFF(DAY, 0,
                                                              DateCreated), 0) DateCreated
                                      FROM      LINK_EDSQL05.GrandSlamDesigns_Sites.dbo.[vw_Admin_CustomerService_Ship-A-CD]
                                      WHERE     DateCreated BETWEEN @BeginDate AND @EndDate
                                                AND CSR_Name <> ''
                                    ) AS CDTEMP
                            GROUP BY CDTEMP.CSR_Name ,
                                    CDTEMP.DateCreated ,
                                    CDTEMP.DateMonth ,
                                    CDTEMP.DateYear
                          ) CD ON Phone.UserName = CD.CSR_Name
                                  AND Phone.ActivityDate = CD.DateCreated            
  -- END MEMOS(CDs) BLOCK            
            
            
  --BEGIN REFUNDS BLOCK            
                LEFT JOIN ( SELECT  tkts.ticket_IssuedBy AS UserName ,
                                    DATEADD(DAY,
                                            DATEDIFF(DAY, 0,
                                                     tkts.ticket_CreateDate),
                                            0) DateCreated ,
                                    MONTH(tkts.ticket_CreateDate) AS MonthCreated ,
                                    YEAR(tkts.ticket_CreateDate) AS YearCreated ,
                                    SUM(Refunds.TxnAmount) AS RefundAmount ,
                                    COUNT(Refunds.UniqueId) AS TotalRefundCount
                            FROM    LINK_EDSQL04.EmbroideryDesigns_Sites.dbo.CustomerSupport_TroubleTickets tkts
                                    WITH ( NOLOCK )
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Transactions.dbo.CustomerSupport_IssueCredit_OrderGroup orders
                                    WITH ( NOLOCK ) ON tkts.TicketID = orders.TicketRowId
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Transactions.dbo.PurchaseOrders purchase
                                    WITH ( NOLOCK ) ON tkts.cust_ReferenceOrderNumber = purchase.TrackingNumber
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Transactions.dbo.Refunds_PurchaseOrders Refunds
                                    WITH ( NOLOCK ) ON Refunds.OrderGroupId = purchase.OrderGroupId
                                    INNER JOIN LINK_EDSQL04.EmbroideryDesigns_Transactions.dbo.Accounting_Transactions trans
                                    WITH ( NOLOCK ) ON trans.TransactionId = Refunds.TransactionId
                                                       AND trans.OrigTransactionId = Refunds.Ref_TransactionId
                                                       AND trans.OrderGroupId = Refunds.OrderGroupId
                            WHERE   tkts.ticket_IssueCategory = 'Issue Refund'
                                    AND tkts.ticket_StatusCode = 5
                                    AND tkts.ticket_CreateDate BETWEEN @BeginDate
                                                              AND
                                                              @EndDate
                                    AND tkts.ticket_IssuedBy IN ( 'CColosimo',
                                                              'MGeschke',
                                                              'BLandsberger',
                                                              'SGerhardt',
                                                              'RErickson' )
                                    AND orders.Approved = 1
                            GROUP BY tkts.ticket_IssuedBy ,
                                    MONTH(tkts.ticket_CreateDate) ,
                                    YEAR(tkts.ticket_CreateDate) ,
                                    DATEADD(DAY,
                                            DATEDIFF(DAY, 0,
                                                     tkts.ticket_CreateDate),
                                            0)
                          ) Refunds ON Refunds.UserName = Phone.UserName
                                       AND Refunds.DateCreated = Phone.ActivityDate            
  --END REFUNDS BLOCK            
            
            
  --BEGIN ARTICLES BLOCK            
                LEFT JOIN (      
  --SELECT SUBSTRING(FName, 1, 1) + LName AS Username, A.PublishDate,                           COUNT(ArticleId) AS Articles            
  --                  FROM EDSQL02.EmbroideryDesigns_FreeStuff.dbo.FES_Articles A WITH (NOLOCK)            
  --                  INNER JOIN EDSQL02.EmbroideryDesigns_FreeStuff.dbo.FES_Authors W WITH (NOLOCK)            
  --                      ON W.AuthorID = A.AuthorId            
  --                  WHERE A.AuthorId IN (201, 475)            
  --                      AND A.PublishDate >=  @BeginDate            
  --                      AND A.PublishDate <=  @EndDate            
  --                      AND isDeleted = 0            
  --                  GROUP BY PublishDate, Fname, LName      
                            SELECT  SUBSTRING(FName, 1, 1) + LName AS Username ,
                                    A.PublishDate ,
                                    CASE WHEN A.Type = 0
                                         THEN COUNT(A.ArticleId)
                                         ELSE 0
                                    END articles ,
                                    CASE WHEN A.Type = 1
                                         THEN COUNT(A.ArticleId)
                                         ELSE 0
                                    END projects
                            FROM    EDSQL02.EmbroideryDesigns_FreeStuff.dbo.FES_Articles A
                                    WITH ( NOLOCK )
                                    INNER JOIN EDSQL02.EmbroideryDesigns_FreeStuff.dbo.FES_Authors W
                                    WITH ( NOLOCK ) ON W.AuthorID = A.AuthorId
                            WHERE   A.AuthorId IN ( 201, 475 )
                                    AND A.PublishDate >= @BeginDate
                                    AND A.PublishDate <= @EndDate
                                    AND isDeleted = 0
                            GROUP BY PublishDate ,
                                    FName ,
                                    LName ,
                                    A.Type
                          ) Projects ON Projects.Username = Phone.UserName
                                        AND Projects.PublishDate = Phone.ActivityDate;            
  --END ARTICLES BLOCK            
            
              
              
  --IF(@SRC='APP')            
  --BEGIN            
  --  SELECT 1 dummyColumn, EntryMonth, EntryYear, Username, SUM(EntryTotal) HoursWorked, HourlyPay, SUM(TotalEmails) TotalEmails, SUM(TotalCall) TotalCall, SUM(CDs) TotalCDs ,            
  --    SUM(Refund) Refund, SUM(TotalRefundCount) TotalRefundCount FROM #tempFinalActivity            
  --  GROUP BY  EntryMonth, EntryYear, Username, HourlyPay            
  --END            
  --ELSE            
  --BEGIN          
        
        SELECT  ActivityDate ,
                Username ,
                EntryTotal HoursWorked ,
                HourlyPay ,
                TotalEmails ,
                TotalCall ,
                CDs TotalCDs ,
                TotalChats ,
                Refund ,
                TotalRefundCount ,
                TotalArticles ,
                TotalProjects Projects ,
                ExpectedWorkHours
        FROM    #tempFinalActivity;           
       
  --END            
    END;            
      
      
      
GO
