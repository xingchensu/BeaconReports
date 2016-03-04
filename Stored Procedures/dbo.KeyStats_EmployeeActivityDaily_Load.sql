SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ======================================================================================= --
-- Author:  Karthik Gowtham                                                                --
-- Create date: 7/31/2015                                                                  --
-- Description: Create sp loading daily employee activity for different group of employee  --
-- ======================================================================================= --
CREATE PROCEDURE [dbo].[KeyStats_EmployeeActivityDaily_Load] --'1/1/2015','6/9/2015',11  
 @BEGINDATE AS datetime,   
 @ENDDATE AS datetime,  
 @GroupNo as int  
AS  
BEGIN   
 SET NOCOUNT ON;  
  DECLARE @BeginDate_t AS datetime  
  
  SET @BeginDate_t = @BeginDate  
  
  DECLARE @ENDDATE_t AS datetime  
  
  SET @ENDDATE_t = @ENDDATE  

	IF OBJECT_ID('tempDB..#ActivityDates') IS NOT NULL
	BEGIN
		DROP TABLE #ActivityDates
	END
	IF OBJECT_ID('tempDB..#Users') IS NOT NULL
	BEGIN
		DROP TABLE #Users
	END
	IF OBJECT_ID('tempDB..#UserActivityDates') IS NOT NULL
	BEGIN
		DROP TABLE #UserActivityDates
	END
	IF OBJECT_ID('tempDB..#SpectorActivities') IS NOT NULL
	BEGIN
		DROP TABLE #SpectorActivities
	END
	IF OBJECT_ID('tempDB..#FINALACTIVITY') IS NOT NULL
	BEGIN
		DROP TABLE #FINALACTIVITY
	END
	
	
	;WITH runningDate AS
	(
		SELECT cast(@BeginDate_t AS DATETIME) DateValue
		UNION ALL
		SELECT DateValue + 1 
		FROM    runningDate  
		WHERE   DateValue +1  <= @ENDDATE_t
	)
	SELECT  runningDate.DateValue INTO #ActivityDates
	FROM    runningDate
	OPTION (MAXRECURSION 0)



	
	CREATE TABLE #Users(FirstName VARCHAR(100), LastName VARCHAR(100), UserName AS (SUBSTRING(FirstName, 1, 1)) + (LastName))
	INSERT INTO #Users (FirstName, LastName)
	VALUES  
		('Bonnie', 'Landsberger'),
		('Cindy', 'Colosimo'),
		('Sue', 'Gerhardt'),
		('Roberta', 'Erickson'),
		('Marie', 'Geschke')
SELECT	e.username, e.StartDate, r.IsMiscellaneous INTO #UserData FROM
dbo.KeyStats_AllEmployees e
  inner join dbo.KeyStats_Category_Employee_Relation r on r.CompanyID=e.Company and r.EmployeeID=e.UserID  
  inner join dbo.KeyStats_Categories c on c.CategoryID=r.CategoryID  
  WHERE  c.CategoryID=@GroupNo


	SELECT * INTO #TempUserActivityDates FROM #Users FULL OUTER JOIN #ActivityDates ON 1=1
	SELECT #TempUserActivityDates.*, StartDate, IsMiscellaneous INTO #UserActivityDates FROM #TempUserActivityDates INNER JOIN #UserData  ON #UserData.username = #TempUserActivityDates.UserName

 select   
  [DirectoryName], DATEADD(day, datediff(day, 0, s.SnapshotDate), 0) SnapshotDate,
 sum([TotalActiveHr]) as totalActiveHours  
 ,sum([NonWorkHours]) as [Non Work Hours]  
 ,SUM(TotalHours) AS [WorkHours]  
   
 ,ISNULL(avg([DailyStartMin]),0) as startdateminute  
 ,ISNULL(avg([DailyEndMin]),0) as enddateminute  
 ,ISNULL(  
  
      CONVERT(varchar(10), avg([DailyStartMin]) / 60) + ':' +  
  
                                                                        CASE  
  
                                                                          WHEN  
  
                                                                            LEN(CONVERT(varchar(10), avg([DailyStartMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), avg([DailyStartMin]) % 60)  
  
                                                                          ELSE CONVERT(varchar(10), avg([DailyStartMin]) % 60)  
  
                                                                        END, 0) AS [Daily Start],  
  
      ISNULL(  
  
      CONVERT(varchar(10), avg([DailyEndMin]) / 60) + ':' +  
  
                                                                      CASE  
  
                                                                        WHEN  
  
                                                                          LEN(CONVERT(varchar(10), avg([DailyEndMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), avg([DailyEndMin]) % 60)  
  
                                                                        ELSE CONVERT(varchar(10),avg([DailyEndMin]) % 60)  
  
                                                                      END, 0) AS [Daily End]  
 ,sum([PhoneCalls]) as totalcall  
 , CASE  
  
      WHEN COUNT([PhoneCalls]) > 0 THEN SUM([PhoneCalls]) / COUNT([PhoneCalls])  
  
      ELSE NULL  
  
    END AS avgcalls  
      ,sum([CallDuration]) as totaldurationmin  
  
  
  
,case when sum([PhoneCalls])> 0 then sum([CallDuration])/sum([PhoneCalls]) else null end as avgCallDuration  
,case when sum([PhoneCalls])> 0 then sum([CallDuration])/sum([PhoneCalls])*60 else null end as avgcalldurationmin  
,sum([TotalInboundCalls]) as totalcallin  
,sum([TotalOutboundCalls]) as totalcallout  
,sum([TotalForwardCalls])+sum([TotalInternalCalls]) as totalcallint  
,sum([KeyStrokes]) as keystroke  
,sum([EmailSent]) as totalemails  
  INTO #SpectorActivities
  FROM  LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot s
 where [SnapshotDate] BETWEEN @BeginDate_t and @ENDDATE_t
 group by [DirectoryName], 
DATEADD(DAY, DATEDIFF(DAY, 0, s.SnapshotDate),0)

 SELECT UserName DirectoryName,#UserActivityDates.StartDate, #UserActivityDates.DateValue,#UserActivityDates.isMiscellaneous, ISNULL(totalActiveHours,0) totalActiveHours, ISNULL([Non Work Hours],0) [Non Work Hours], ISNULL(WorkHours,0) WorkHours, ISNULL(startdateminute,0) startdateminute,
 ISNULL(enddateminute,0) enddateminute, ISNULL([Daily Start],'0') [Daily Start],  ISNULL([Daily End],'0') [Daily End],  ISNULL(totalcall,0) totalcall,  ISNULL(avgcalls,0) avgcalls,  
 ISNULL(totaldurationmin,0) totaldurationmin,   ISNULL(avgCallDuration,0) avgCallDuration, ISNULL(avgcalldurationmin,0) avgcalldurationmin, ISNULL(totalcallin,0) totalcallin, ISNULL(totalcallout,0) totalcallout,
 ISNULL(totalcallint,0) totalcallint, ISNULL(keystroke,0) keystroke, ISNULL(totalemails,0) totalemails INTO #FINALACTIVITY
 FROM #UserActivityDates FULL OUTER JOIN #SpectorActivities ACTIVTY ON #UserActivityDates.DateValue = ACTIVTY.SnapshotDate
 AND #UserActivityDates.UserName = ACTIVTY.DirectoryName
 WHERE UserName IS NOT NULL
 ORDER BY UserName, DateValue
 
 --UPDATE A SET A.STARTDATE='', A.ISMISCELLANEOUS=0 FROM #FINALACTIVITY A INNER JOIN #UserActivityDates
 --UPDATE A SET A.STARTDATE = B.STARTDATE, A.ISMISCELLANEOUS = B.ISMISCELLANEOUS FROM #FINALACTIVITY A INNER JOIN #FINALACTIVITY B ON A.DirectoryName = B.DirectoryName AND B.StartDate IS NOT NULL AND A.StartDate IS NULL AND B.isMiscellaneous IS NOT NULL

 SELECT * FROM #FINALACTIVITY A
END  
GO
