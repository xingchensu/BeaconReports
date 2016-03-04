SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[KeyStats_CSRActivityDaily_Load]
    (
      @BeginDate DATETIME ,
      @EndDate DATETIME
    )
AS
    BEGIN            
            
--SELECT @BeginDate=DATEADD(day, DATEDIFF(day, 0, @BeginDate), 0), @EndDate = DATEADD(S,-1,DATEADD(DAY,1,@EndDate))            
--SELECT @BeginDate = '2015-07-01', -- datetime            
--    @EndDate = '2015-07-31 12:25:50' -- datetime  
--Get the ED Operator Mail, CDs, Calls, Articles, Refunds Counts and Refund Amount              
--Begin              
        DECLARE @TEMPEMPACTIVITYWORK AS TABLE
            (
              activityDate DATETIME ,
              userName VARCHAR(250) ,
              entryTotal FLOAT ,
              hourlyPay DECIMAL(10, 2) ,
              totalEmails INT ,
              totalCall INT ,
              memo INT ,
              totalChats INT ,             
--articles INT,                
              refundAmount FLOAT ,
              refundCount INT ,
              articles INT ,
              projects INT ,
              refundReviews INT ,
              vendorReviews INT ,
              expectedWorkHours DECIMAL(10, 2)
            );                
        INSERT  INTO @TEMPEMPACTIVITYWORK
                ( activityDate ,
                  userName ,
                  entryTotal ,
                  hourlyPay ,
                  totalEmails ,
                  totalCall ,
                  memo ,
                  totalChats ,
                  refundAmount ,
                  refundCount ,
                  articles ,
                  projects ,
                  expectedWorkHours
                )
                EXEC dbo.KeyStats_CustomerServicePhoneEmailCDRefunds_Load @BeginDate = @BeginDate,
                    @EndDate = @EndDate;            

   
          
        UPDATE  @TEMPEMPACTIVITYWORK
        SET     refundReviews = RR.refundReview
        FROM    ( SELECT    CONVERT(DATE, CreditRequestDate) reportDate ,
                            CreditRequestedBy ,
                            COUNT(DISTINCT TicketRowId) refundReview
                  FROM      LINK_EDSQL04.EmbroideryDesigns_Transactions.dbo.CustomerSupport_IssueCredit_OrderGroup
                  WHERE     CreditRequestDate BETWEEN @BeginDate AND @EndDate
                  GROUP BY  CONVERT(DATE, CreditRequestDate) ,
                            CreditRequestedBy
                ) AS RR
        WHERE   [@TEMPEMPACTIVITYWORK].activityDate = RR.reportDate
                AND [@TEMPEMPACTIVITYWORK].userName = RR.CreditRequestedBy;          
          
--SELECT * FROM @TEMPEMPACTIVITYWORK            
--End            
            
--Get the Employee Work Hours Data              
--Begin              
        DECLARE @TEMPEMPACTIVITY AS TABLE
            (
              directoryName VARCHAR(250) ,
              startDate VARCHAR(10) ,
              activityDate DATETIME ,
              isMiscellaneous BIT ,
              totalActiveHours FLOAT ,
              nonWorkHours FLOAT ,
              workHours FLOAT ,
              startDateMinute INT ,
              endDateMinute INT ,
              dailyStart VARCHAR(10) ,
              dailyEnd VARCHAR(10) ,
              totalCall INT ,
              avgCalls FLOAT ,
              totalDurationMin FLOAT ,
              avgCallDuration FLOAT ,
              avgCallDurationMin FLOAT ,
              totalCallIn INT ,
              totalCallOut INT ,
              totalCallInt INT ,
              keyStroke BIGINT ,
              totalEmails INT
            );                
                
        INSERT  INTO @TEMPEMPACTIVITY
                ( directoryName ,
                  startDate ,
                  activityDate ,
                  isMiscellaneous ,
                  totalActiveHours ,
                  nonWorkHours ,
                  workHours ,
                  startDateMinute ,
                  endDateMinute ,
                  dailyStart ,
                  dailyEnd ,
                  totalCall ,
                  avgCalls ,
                  totalDurationMin ,
                  avgCallDuration ,
                  avgCallDurationMin ,
                  totalCallIn ,
                  totalCallOut ,
                  totalCallInt ,
                  keyStroke ,
                  totalEmails
                )
                EXEC [dbo].[KeyStats_EmployeeActivityDaily_Load] @BEGINDATE = @BeginDate,
                    @ENDDATE = @EndDate, @GroupNo = 11;   -- by  Default 11 because fgroup code for CSR is 11              
--SELECT * FROM @TEMPEMPACTIVITY            
--End            
            
--Include Chats after New Chats Tool            
            
--Get the Cosnolidated data by joining the above three tables              
--Begin             
--TRUNCATE TABLE dbo.Temp_KeyStats_CSRActivity_Load  
  
  
        INSERT  INTO dbo.KeyStats_CSRActivity_Load_Snapshot
                ( userName ,
                  startDate ,
                  activityDate ,
                  isMiscellaneouos ,
                  workHours ,
                  noOfEmails ,
                  noOfCalls ,
                  noOfCDs ,
                  refundAmount ,
                  refundCount ,
                  hourlyPay ,
                  workedHoursPay ,
                  articles ,
                  projects ,
                  refundReview ,
                  vendorReview ,
                  expectedWorkHours ,
                  noOfUnAnsweredChats
                )
                SELECT  userName ,
                        startDate ,
                        [@TEMPEMPACTIVITYWORK].activityDate ,
                        ISNULL([@TEMPEMPACTIVITY].isMiscellaneous, 0) ,
                        ISNULL(workHours, 0.00) workHours ,
                        ISNULL([@TEMPEMPACTIVITYWORK].totalEmails, 0) noofEmails ,
                        ISNULL([@TEMPEMPACTIVITYWORK].totalCall, 0) noofCalls ,
                        ISNULL([@TEMPEMPACTIVITYWORK].memo, 0) noofCDs ,
                        ISNULL([@TEMPEMPACTIVITYWORK].refundAmount, 0.00) refundAmount ,
                        ISNULL([@TEMPEMPACTIVITYWORK].refundCount, 0) refundCount ,
                        ISNULL([@TEMPEMPACTIVITYWORK].hourlyPay, 0.00) hourlyPay ,
                        ISNULL(workHours * [@TEMPEMPACTIVITYWORK].hourlyPay,
                               0.00) workedHoursPay ,
                        ISNULL([@TEMPEMPACTIVITYWORK].articles, 0) articles ,
                        ISNULL([@TEMPEMPACTIVITYWORK].projects, 0) projects ,
                        ISNULL([@TEMPEMPACTIVITYWORK].refundReviews, 0) refundReview ,
                        0 vendorReview ,
                        ISNULL(expectedWorkHours, 0.00) expectedWorkHours ,
                        0 noOfUnAnsweredChats
                FROM    @TEMPEMPACTIVITYWORK
                        LEFT OUTER JOIN @TEMPEMPACTIVITY ON [@TEMPEMPACTIVITYWORK].userName = directoryName
                                                            AND [@TEMPEMPACTIVITYWORK].activityDate = [@TEMPEMPACTIVITY].activityDate
                ORDER BY isMiscellaneous ,
                        [@TEMPEMPACTIVITYWORK].userName ,
                        [@TEMPEMPACTIVITYWORK].activityDate;  
  
--Pay for Regular  
        UPDATE  Activity
        SET     hourlyPay = HP.payPerHour ,
                Activity.FName = Emp.FName ,
                Activity.LName = Emp.LName
        FROM    dbo.KeyStats_CSRActivity_Load_Snapshot Activity
                INNER JOIN dbo.KeyStats_HourlyPay HP ON Activity.userName = HP.userName
                INNER JOIN dbo.KeyStats_AllEmployees Emp ON Activity.userName = Emp.username
        WHERE   HP.activeStatus = 1
                AND isMiscellaneouos = 0
                AND Activity.activityDate BETWEEN @BeginDate
                                          AND     @EndDate;  
  
--Pay for Miscellaneous  
        UPDATE  Activity
        SET     Activity.FName = CATREL.FName ,
                Activity.LName = CATREL.LName ,
                Activity.hourlyPay = HP.payPerHour
        FROM    KeyStats_CSRActivity_Load_Snapshot Activity
                INNER JOIN dbo.KeyStats_HourlyPay HP ON HP.userName = Activity.userName
                                                        AND HP.activeStatus = 1
                                                        AND Activity.isMiscellaneouos = 1
                INNER JOIN dbo.KeyStats_AllEmployees EMP ON EMP.username = HP.userName
                                                            AND EMP.username = Activity.userName
                INNER JOIN dbo.KeyStats_Category_Employee_Relation CATREL ON CATREL.EmployeeID = EMP.UserID
                                                              AND CATREL.CategoryID = 11
                                                              AND CATREL.IsMiscellaneous = 1
        WHERE   isMiscellaneouos = 1
                AND Activity.activityDate BETWEEN @BeginDate
                                          AND     @EndDate;  
  
  
        DECLARE @ChatActivity AS TABLE
            (
              [userName] VARCHAR(50) ,
              [chatDate] DATETIME ,
              [userEmail] VARCHAR(50) ,
              [noOfchats] INT ,
              [avgChatDurationTime] VARCHAR(8) ,
              [avgChatDuration] FLOAT ,
              [avgFirstResponseTime] FLOAT ,
              [avgResponseTime] FLOAT ,
              [characterCountAgent] INT ,
              [characterCountVisitor] INT ,
              [avgChatRating] FLOAT ,
              [noOfChatLeads] INT
            );  
  
        INSERT  INTO @ChatActivity
                ( userName ,
                  chatDate ,
                  userEmail ,
                  noOfchats ,
                  avgChatDurationTime ,
                  avgChatDuration ,
                  avgFirstResponseTime ,
                  avgResponseTime ,
                  characterCountAgent ,
                  characterCountVisitor ,
                  avgChatRating ,
                  noOfChatLeads
                )
                EXEC dbo.LiveChat_ChatwiseData_Load @BeginDate = @BeginDate,
                    @EndDate = @EndDate;  
  
        UPDATE  Activity
        SET     Activity.userEmail = Chats.userEmail ,
                Activity.noOfchats = Chats.noOfchats ,
                Activity.avgChatDurationTime = Chats.avgChatDurationTime ,
                Activity.avgChatDuration = Chats.avgChatDuration ,
                Activity.avgFirstResponseTime = Chats.avgFirstResponseTime ,
                Activity.avgResponseTime = Chats.avgResponseTime ,
                Activity.characterCountAgent = Chats.characterCountAgent ,
                Activity.characterCountVisitor = Chats.characterCountVisitor ,
                Activity.avgChatRating = Chats.avgChatRating ,
                Activity.noOfChatLeads = Chats.noOfChatLeads
        FROM    dbo.KeyStats_CSRActivity_Load_Snapshot Activity
                INNER JOIN @ChatActivity Chats ON Chats.userName = Activity.userName
                                                  AND Chats.chatDate = Activity.activityDate;  
--End             
    END;     
GO
