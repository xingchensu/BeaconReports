SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[Keystats_CSRActivity_VsBFCAvg_Load]
    (
      @BEGINDATE DATETIME ,
      @ENDDATE DATETIME ,
      @USERNAME VARCHAR(50) ,
      @FILTERTYPE VARCHAR(3)
    )
AS
    BEGIN       
        SET @ENDDATE = DATEADD(S, -1, DATEADD(DAY, 1, @ENDDATE));    
        IF OBJECT_ID('TempDB..#CSRActivity') IS NOT NULL
            BEGIN    
                DROP TABLE #CsrActivity;    
            END;    
    
        DECLARE @CSRIndividualStats AS TABLE
            (
              sortOrder INT ,
              [index] INT ,
              headerName VARCHAR(75) ,
              className VARCHAR(15) ,
              userName VARCHAR(15) ,
              fullName VARCHAR(50) ,
              lName VARCHAR(15) ,
              IsMiscellaneous BIT ,
              startDate VARCHAR(10) ,
              workHours DECIMAL(10, 2) ,
              expectedWorkHours DECIMAL(10, 2) ,
              workedHoursPay DECIMAL(10, 2) ,
              avgPayPerHr INT ,
              mailsPerHr INT ,
              callsPerHr DECIMAL(10, 2) ,
              cdsPerHr INT ,
              chatsPerHr INT ,
              tasksPerHr DECIMAL(10, 2) ,
              activitiesPerHr DECIMAL(10, 2) ,
              articles INT ,
              projects INT ,
              vendorReview INT ,
              refundReview INT ,
              tasks INT ,
              noOfChats INT ,
              avgChatDuration INT ,
              avgFirstResponseTime INT ,
              avgResponseTime INT ,
              avgChatRating INT ,
              charCountAgent INT ,
              charCountVisitor INT ,
              charCountTotal INT ,
              noOfChatLeads INT ,
              refundAmount DECIMAL(10, 2) ,
              refundCount INT ,
              avgRefund DECIMAL(10, 2) ,
              refundsPerHr DECIMAL(10, 2) ,
              MathTest TINYINT ,
              mathAccuracy TINYINT ,
              numberMatching TINYINT ,
              numberAccuracy TINYINT ,
              wordMatching TINYINT ,
              wordAccuracy TINYINT ,
              typingSpeed TINYINT ,
              typingAccuracy TINYINT ,
              typingTestKeyStrokes TINYINT ,
              jobSpecQues TINYINT ,
              beaconScore TINYINT ,
              ficoScore TINYINT ,
              totalCall INT ,
              totalCallIn INT ,
              totalCallOut INT ,
              totalCallInt INT ,
              avgCalls DECIMAL(10, 2) ,
              avgCallDurationMin DECIMAL(10, 2) ,
              dailyStart VARCHAR(5) ,
              dailyEnd VARCHAR(5) ,
              totalActiveHours DECIMAL(10, 2) ,
              nonWorkHours DECIMAL(10, 2) ,
              keyStroke INT ,
              totalEmails INT ,
              startdateminute INT ,
              enddateminute INT
            );    
        
        
        DECLARE @CSRIndividualDrillDown AS TABLE
            (
              [index] INT ,
              headerName VARCHAR(75) ,
              startDate VARCHAR(10) ,
              fullName VARCHAR(50) ,
              workHours DECIMAL(10, 2) ,
              expectedWorkHours DECIMAL(10, 2) ,
              workedHoursPay DECIMAL(10, 2) ,
              avgPayPerHr INT ,
              mailsPerHr INT ,
              callsPerHr DECIMAL(10, 2) ,
              cdsPerHr INT ,
              chatsPerHr INT ,
              tasksPerHr DECIMAL(10, 2) ,
              activitiesPerHr DECIMAL(10, 2) ,
              articles INT ,
              projects INT ,
              vendorReview INT ,
              refundReview INT ,
              tasks INT ,
              noOfChats INT ,
              avgChatDuration INT ,
              avgFirstResponseTime INT ,
              avgResponseTime INT ,
              avgChatRating INT ,
              charCountAgent INT ,
              charCountVisitor INT ,
              charCountTotal INT ,
              noOfChatLeads INT ,
              refundAmount DECIMAL(10, 2) ,
              refundCount INT ,
              avgRefund DECIMAL(10, 2) ,
              refundsPerHr DECIMAL(10, 2) ,
              MathTest TINYINT ,
              mathAccuracy TINYINT ,
              numberMatching TINYINT ,
              numberAccuracy TINYINT ,
              wordMatching TINYINT ,
              wordAccuracy TINYINT ,
              typingSpeed TINYINT ,
              typingAccuracy TINYINT ,
              typingTestKeyStrokes TINYINT ,
              jobSpecQues TINYINT ,
              beaconScore TINYINT ,
              ficoScore TINYINT ,
              totalCall INT ,
              totalCallIn INT ,
              totalCallOut INT ,
              totalCallInt INT ,
              avgCalls DECIMAL(10, 2) ,
              avgCallDurationMin DECIMAL(10, 2) ,
              dailyStart VARCHAR(7) ,
              dailyEnd VARCHAR(7) ,
              totalActiveHours DECIMAL(10, 2) ,
              nonWorkHours DECIMAL(10, 2) ,
              keyStroke INT ,
              totalEmails INT ,
              startdateminute INT ,
              enddateminute INT
            );    
        
        INSERT  INTO @CSRIndividualStats
                ( sortOrder ,
                  [index] ,
                  headerName ,
                  className ,
                  userName ,
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
                  mathAccuracy ,
                  numberMatching ,
                  numberAccuracy ,
                  wordMatching ,
                  wordAccuracy ,
                  typingSpeed ,
                  typingAccuracy ,
                  typingTestKeyStrokes ,
                  jobSpecQues ,
                  beaconScore ,
                  ficoScore ,
                  totalCall ,
                  totalCallIn ,
                  totalCallOut ,
                  totalCallInt ,
                  avgCalls ,
                  avgCallDurationMin ,
                  dailyStart ,
                  dailyEnd ,
                  totalActiveHours ,
                  nonWorkHours ,
                  keyStroke ,
                  totalEmails ,
                  startdateminute ,
                  enddateminute     
                )
                EXEC dbo.Keystats_CSRActivity_Individualstats_Load @BEGINDATE = @BEGINDATE, -- datetime    
                    @ENDDATE = @ENDDATE, -- datetime    
                    @FILTERTYPE = @FILTERTYPE;    
    
    
        INSERT  INTO @CSRIndividualDrillDown
                ( [index] ,
                  headerName ,
                  startDate ,
                  fullName ,
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
                  totalCall ,
                  totalCallIn ,
                  totalCallOut ,
                  totalCallInt ,
                  avgCalls ,
                  avgCallDurationMin ,
                  dailyStart ,
                  dailyEnd ,
                  totalActiveHours ,
                  nonWorkHours ,
                  keyStroke ,
                  totalEmails ,
                  startdateminute ,
                  enddateminute     
                )
                EXEC dbo.Keystats_CSRActivity_IndividualDrillDown_Load @BEGINDATE = @BEGINDATE, -- datetime    
                    @ENDDATE = @ENDDATE, -- datetime    
                    @USERNAME = @USERNAME;    
    
    
        SELECT  *
        INTO    #CSRActivity
        FROM    ( SELECT    1 sortOrder ,
                            1 [index] ,
                            userName + '<br/> &nbsp;' headerName ,
                            '' className ,
                            userName ,
                            [@CSRIndividualDrillDown].fullName ,
                            lName ,
                            IsMiscellaneous ,
                            [@CSRIndividualDrillDown].startDate ,
                            [@CSRIndividualDrillDown].workHours ,
                            [@CSRIndividualDrillDown].expectedWorkHours ,
                            [@CSRIndividualDrillDown].workedHoursPay ,
                            [@CSRIndividualDrillDown].avgPayPerHr ,
                            [@CSRIndividualDrillDown].mailsPerHr ,
                            [@CSRIndividualDrillDown].callsPerHr ,
                            [@CSRIndividualDrillDown].cdsPerHr ,
                            [@CSRIndividualDrillDown].chatsPerHr ,
                            [@CSRIndividualDrillDown].tasksPerHr ,
                            [@CSRIndividualDrillDown].activitiesPerHr ,
                            [@CSRIndividualDrillDown].articles ,
                            [@CSRIndividualDrillDown].projects ,
                            [@CSRIndividualDrillDown].vendorReview ,
                            [@CSRIndividualDrillDown].refundReview ,
                            [@CSRIndividualDrillDown].tasks ,
                            [@CSRIndividualDrillDown].noOfChats ,
                            [@CSRIndividualDrillDown].avgChatDuration ,
                            [@CSRIndividualDrillDown].avgFirstResponseTime ,
                            [@CSRIndividualDrillDown].avgResponseTime ,
                            [@CSRIndividualDrillDown].avgChatRating ,
                            [@CSRIndividualDrillDown].charCountAgent ,
                            [@CSRIndividualDrillDown].charCountVisitor ,
                            [@CSRIndividualDrillDown].charCountTotal ,
                            [@CSRIndividualDrillDown].noOfChatLeads ,
                            [@CSRIndividualDrillDown].refundAmount ,
                            [@CSRIndividualDrillDown].refundCount ,
                            [@CSRIndividualDrillDown].avgRefund ,
                            [@CSRIndividualDrillDown].refundsPerHr ,
                            ISNULL([@CSRIndividualStats].MathTest, 0) MathTest ,
                            ISNULL([@CSRIndividualStats].mathAccuracy, 0) mathAccuracy ,
                            ISNULL([@CSRIndividualStats].numberMatching, 0) numberMatching ,
                            ISNULL([@CSRIndividualStats].numberAccuracy, 0) numberAccuracy ,
                            ISNULL([@CSRIndividualStats].wordMatching, 0) wordMatching ,
                            ISNULL([@CSRIndividualStats].wordAccuracy, 0) wordAccuracy ,
                            ISNULL([@CSRIndividualStats].typingSpeed, 0) typingSpeed ,
                            ISNULL([@CSRIndividualStats].typingAccuracy, 0) typingAccuracy ,
                            ISNULL([@CSRIndividualStats].typingTestKeyStrokes,
                                   0) typingTestKeyStrokes ,
                            ISNULL([@CSRIndividualStats].jobSpecQues, 0) jobSpecQues ,
                            ISNULL([@CSRIndividualStats].beaconScore, 0) beaconScore ,
                            ISNULL([@CSRIndividualStats].ficoScore, 0) ficoScore,
                             [@CSRIndividualDrillDown].totalCall ,
                  [@CSRIndividualDrillDown].totalCallIn ,
                  [@CSRIndividualDrillDown].totalCallOut ,
                  [@CSRIndividualDrillDown].totalCallInt ,
                  [@CSRIndividualDrillDown].avgCalls ,
                  [@CSRIndividualDrillDown].avgCallDurationMin ,
                  [@CSRIndividualDrillDown].dailyStart ,
                  [@CSRIndividualDrillDown].dailyEnd ,
                  [@CSRIndividualDrillDown].totalActiveHours ,
                  [@CSRIndividualDrillDown].nonWorkHours ,
                  [@CSRIndividualDrillDown].keyStroke ,
                  [@CSRIndividualDrillDown].totalEmails ,
                  [@CSRIndividualDrillDown].startdateminute ,
                  [@CSRIndividualDrillDown].enddateminute     
                  FROM      @CSRIndividualDrillDown
                            LEFT OUTER JOIN @CSRIndividualStats ON [@CSRIndividualStats].fullName = [@CSRIndividualDrillDown].fullName
                  WHERE     [@CSRIndividualDrillDown].[index] = 3
                  UNION
                  SELECT    sortOrder ,
                            102 [index] ,
                            userName + '<br/> &nbsp;' headerName ,
                            '' className ,
                            userName ,
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
                            mathAccuracy ,
                            numberMatching ,
                            numberAccuracy ,
                            wordMatching ,
                            wordAccuracy ,
                            typingSpeed ,
                            typingAccuracy ,
                            typingTestKeyStrokes ,
                            jobSpecQues ,
                            beaconScore ,
                            ficoScore,
                             [@CSRIndividualStats].totalCall ,
                  [@CSRIndividualStats].totalCallIn ,
                  [@CSRIndividualStats].totalCallOut ,
                  [@CSRIndividualStats].totalCallInt ,
                  [@CSRIndividualStats].avgCalls ,
                  [@CSRIndividualStats].avgCallDurationMin ,
                  [@CSRIndividualStats].dailyStart ,
                  [@CSRIndividualStats].dailyEnd ,
                  [@CSRIndividualStats].totalActiveHours ,
                  [@CSRIndividualStats].nonWorkHours ,
                  [@CSRIndividualStats].keyStroke ,
                  [@CSRIndividualStats].totalEmails ,
                  [@CSRIndividualStats].startdateminute ,
                  [@CSRIndividualStats].enddateminute 
                  FROM      @CSRIndividualStats
                  WHERE     [index] = 101
                ) AS CSRIndividualNAvg;    
    
        SELECT  *
        FROM    #CSRActivity
        UNION
        SELECT  3 sortOrder ,
                5 [index] ,
                'DIFFERENCE' headerName ,
                '' className ,
                '' userName ,
                '' fullName ,
                '' lName ,
                0 isMiscellaneous ,
                '' startDate ,
                *
        FROM    ( SELECT    ( Indrow.workHours - AvgRow.workHours ) workHours ,
                            ( Indrow.expectedWorkHours
                              - AvgRow.expectedWorkHours ) expectedWorkHours ,
                            ( Indrow.workedHoursPay - AvgRow.workedHoursPay ) workedHoursPay ,
                            ( Indrow.avgPayPerHr - AvgRow.avgPayPerHr ) avgPayPerHr ,
                            ( Indrow.mailsPerHr - AvgRow.mailsPerHr ) mailsPerHr ,
                            ( Indrow.callsPerHr - AvgRow.callsPerHr ) callsPerHr ,
                            ( Indrow.cdsPerHr - AvgRow.cdsPerHr ) cdsPerHr ,
                            ( Indrow.chatsPerHr - AvgRow.chatsPerHr ) chatsPerHr ,
                            ( Indrow.tasksPerHr - AvgRow.tasksPerHr ) tasksPerHr ,
                            ( Indrow.activitiesPerHr - AvgRow.activitiesPerHr ) activitiesPerHr ,
                            ( Indrow.articles - AvgRow.articles ) articles ,
                            ( Indrow.projects - AvgRow.projects ) projects ,
                            ( Indrow.vendorReview - AvgRow.vendorReview ) vendorReview ,
                            ( Indrow.refundReview - AvgRow.refundReview ) refundReview ,
                            ( Indrow.tasks - AvgRow.tasks ) tasks ,
                            ( Indrow.noOfChats - AvgRow.noOfChats ) noOfChats ,
                            ( Indrow.avgChatDuration - AvgRow.avgChatDuration ) avgChatDuration ,
                            ( Indrow.avgFirstResponseTime
                              - AvgRow.avgFirstResponseTime ) avgFirstResponseTime ,
                            ( Indrow.avgResponseTime - AvgRow.avgResponseTime ) avgResponseTime ,
                            ( Indrow.avgChatRating - AvgRow.avgChatRating ) avgChatRating ,
                            ( Indrow.charCountAgent - AvgRow.charCountAgent ) charCountAgent ,
                            ( Indrow.charCountVisitor
                              - AvgRow.charCountVisitor ) charCountVisitor ,
                            ( Indrow.charCountTotal - AvgRow.charCountTotal ) charCountTotal ,
                            ( Indrow.noOfChatLeads - AvgRow.noOfChatLeads ) noOfChatLeads ,
                            ( Indrow.refundAmount - AvgRow.refundAmount ) refundAmount ,
                            ( Indrow.refundCount - AvgRow.refundCount ) refundCount ,
                            ( Indrow.avgRefund - AvgRow.avgRefund ) avgRefund ,
                            ( Indrow.refundsPerHr - AvgRow.refundsPerHr ) refundsPerHr ,
                            ( Indrow.MathTest - AvgRow.MathTest ) MathTest ,
                            ( Indrow.mathAccuracy - AvgRow.mathAccuracy ) mathAccuracy ,
                            ( Indrow.numberMatching - AvgRow.numberMatching ) numberMatching ,
                            ( Indrow.numberAccuracy - AvgRow.numberAccuracy ) numberAccuracy ,
                            ( Indrow.wordMatching - AvgRow.wordMatching ) wordMatching ,
                            ( Indrow.wordAccuracy - AvgRow.wordAccuracy ) wordAccuracy ,
                            ( Indrow.typingSpeed - AvgRow.typingSpeed ) typingSpeed ,
                            ( Indrow.typingAccuracy - AvgRow.typingAccuracy ) typingAccuracy ,
                            ( Indrow.typingTestKeyStrokes
                              - AvgRow.typingTestKeyStrokes ) typingTestKeyStrokes ,
                            ( Indrow.jobSpecQues - AvgRow.jobSpecQues ) jobSpecQues ,
                            ( Indrow.beaconScore - AvgRow.beaconScore ) beaconScore ,
                            ( Indrow.ficoScore - AvgRow.ficoScore ) ficoScore,
                            ( Indrow.totalCall - Avgrow.totalCall ) totalCall ,
                            ( Indrow.totalCallIn
                              - Avgrow.totalCallInt ) totalCallIn ,
                            ( Indrow.totalCallOut
                              - Avgrow.totalCallOut ) totalCallOut ,
                            ( Indrow.totalCallInt
                              - Avgrow.totalCallInt ) totalCallInt ,
                            ( Indrow.avgCalls - Avgrow.avgCalls ) avgCalls ,
                            ( Indrow.avgCallDurationMin
                              - Avgrow.avgCallDurationMin ) avgCallDurationMin ,
                            CAST(Indrow.startdateminute
                            - Avgrow.startdateminute AS VARCHAR(10))
                            + ' min' dailyStart ,
                            CAST(Indrow.enddateminute
                            - Avgrow.enddateminute AS VARCHAR(10))
                            + ' min' dailyEnd ,
                            ( Indrow.totalActiveHours
                              - Avgrow.totalActiveHours ) totalActiveHours ,
                            ( Indrow.nonWorkHours
                              - Avgrow.nonWorkHours ) nonWorkHours ,
                            ( Indrow.keyStroke - Avgrow.keyStroke ) keyStroke ,
                            ( Indrow.totalEmails
                              - Avgrow.totalEmails ) totalEmails ,
                            ( Indrow.startdateminute
                              - Avgrow.startdateminute ) startdateminute ,
                            ( Indrow.enddateminute
                              - Avgrow.enddateminute ) enddateminute
                  FROM      #CSRActivity Indrow ,
                            #CSRActivity AvgRow
                  WHERE     Indrow.[sortOrder] = 1
                            AND AvgRow.[sortOrder] = 2
                ) AS DifferenceRow;     
    END; 
GO
