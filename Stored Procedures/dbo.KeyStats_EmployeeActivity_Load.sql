SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:  	Ruonan
-- Create date: 6/8/2015
-- Description:	Create sp loading employee activity for different group of employee
-- =============================================
--[dbo].[KeyStats_EmployeeActivity_Load]'1/1/2015','7/7/2015',11
CREATE PROCEDURE [dbo].[KeyStats_EmployeeActivity_Load]--'1/1/2015','11/23/2015',1
@BEGINDATE AS datetime,
@ENDDATE AS datetime,
@GroupNo AS int
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @BeginDate_t AS datetime

  SET @BeginDate_t = @BeginDate

  DECLARE @ENDDATE_t AS datetime

  SET @ENDDATE_t = @ENDDATE

	
  IF OBJECT_ID('tempdb..#SpectorDailyAdminDataSnapShot') IS NOT NULL
    DROP TABLE #SpectorDailyAdminDataSnapShot

 select DirectoryName ,   
   [TotalActiveHr],
   [NonWorkHours],
   TotalHours,
  [DailyStartMin],
   [DailyEndMin],
   [PhoneCalls], 
   [CallDuration], 
    [TotalInboundCalls],
  [TotalOutboundCalls],
  [TotalForwardCalls],[TotalInternalCalls],
    [KeyStrokes],
  [EmailSent] 
 into #SpectorDailyAdminDataSnapShot
 from LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.SpectorDailyAdminDataSnapShot   
  WHERE [SnapshotDate] >= @BeginDate_t
  AND [SnapshotDate] <= @ENDDATE_t
  
  IF OBJECT_ID('tempdb..#ACTIVITY') IS NOT NULL
    DROP TABLE #ACTIVITY


  SELECT
    [DirectoryName],
    [CRMGuid],
    CAST([StartDate] AS datetime) AS [StartDate],
    r.IsMiscellaneous,
    SUM([TotalActiveHr]) AS totalActiveHours,
    SUM([NonWorkHours]) AS [Non Work Hours],
    SUM(TotalHours) AS [WorkHours],
    AVG([DailyStartMin]) AS startdateminute,
    AVG([DailyEndMin]) AS enddateminute,
    ISNULL(

    CONVERT(varchar(10), AVG([DailyStartMin]) / 60) + ':' +

                                                           CASE

                                                             WHEN

                                                               LEN(CONVERT(varchar(10), AVG([DailyStartMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG([DailyStartMin]) % 60)

                                                             ELSE CONVERT(varchar(10), AVG([DailyStartMin]) % 60)

                                                           END, 0) AS [Daily Start],

    ISNULL(

    CONVERT(varchar(10), AVG([DailyEndMin]) / 60) + ':' +

                                                         CASE

                                                           WHEN

                                                             LEN(CONVERT(varchar(10), AVG([DailyEndMin]) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG([DailyEndMin]) % 60)

                                                           ELSE CONVERT(varchar(10), AVG([DailyEndMin]) % 60)

                                                         END, 0) AS [Daily End],
    SUM([PhoneCalls]) AS totalcall,
    CASE

      WHEN COUNT([PhoneCalls]) > 0 THEN SUM([PhoneCalls]) / COUNT([PhoneCalls])

      ELSE NULL

    END AS avgcalls,
    SUM([CallDuration]) AS totaldurationmin,
    CASE
      WHEN SUM([PhoneCalls]) > 0 THEN SUM([CallDuration]) / SUM([PhoneCalls])
      ELSE NULL
    END AS avgCallDuration,
    CASE
      WHEN SUM([PhoneCalls]) > 0 THEN SUM([CallDuration]) / SUM([PhoneCalls]) * 60
      ELSE NULL
    END AS avgcalldurationmin,
    SUM([TotalInboundCalls]) AS totalcallin,
    SUM([TotalOutboundCalls]) AS totalcallout,
    SUM([TotalForwardCalls]) + SUM([TotalInternalCalls]) AS totalcallint,
    SUM([KeyStrokes]) AS keystroke,
    SUM([EmailSent]) AS totalemails INTO #ACTIVITY
  FROM #SpectorDailyAdminDataSnapShot s
  INNER JOIN dbo.KeyStats_AllEmployees e
    ON s.DirectoryName = e.username
  INNER JOIN dbo.KeyStats_Category_Employee_Relation r
    ON r.CompanyID = e.Company
    AND r.EmployeeID = e.UserID
  INNER JOIN dbo.KeyStats_Categories c
    ON c.CategoryID = r.CategoryID

  WHERE 
  --[SnapshotDate] >= @BeginDate_t
  --AND [SnapshotDate] <= @ENDDATE_t
  --AND
   c.CategoryID = @GroupNo
  --and r.IsMiscellaneous=0
  GROUP BY [DirectoryName],
           [CRMGuid],
           [StartDate],
           r.IsMiscellaneous

  SELECT
    *
  FROM #ACTIVITY
  WHERE IsMiscellaneous = 0

  /*==== SECOND TABLE Return BFC TOTAL/AVG ====*/
  SELECT
    CAST(AVG(CAST([startdate] AS float)) AS datetime) AS [startdate],
    AVG(totalActiveHours) AS totalActiveHours,
    AVG([Non Work Hours]) AS [Non Work Hours],
    AVG(WorkHours) AS WorkHours,
    AVG(startdateminute) AS startdateminute,
    AVG(enddateminute) AS enddateminute,
    ISNULL(CONVERT(varchar(10), AVG(startdateminute) / 60) + ':' +
                                                                  CASE
                                                                    WHEN
                                                                      LEN(CONVERT(varchar(10), AVG(startdateminute) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG(startdateminute) % 60)
                                                                    ELSE CONVERT(varchar(10), AVG(startdateminute) % 60)
                                                                  END, 0) AS [Daily Start],
    ISNULL(CONVERT(varchar(10), AVG(enddateminute) / 60) + ':' +
                                                                CASE
                                                                  WHEN
                                                                    LEN(CONVERT(varchar(10), AVG(enddateminute) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG(enddateminute) % 60)
                                                                  ELSE CONVERT(varchar(10), AVG(enddateminute) % 60)
                                                                END, 0) AS [Daily End],
    AVG(totalcall) AS totalcall,
    AVG(avgcalls) AS avgcalls,
    AVG(totaldurationmin) AS totaldurationmin,
    AVG(avgCallDuration) AS avgCallDuration,
    AVG(avgcalldurationmin) AS avgcalldurationmin,
    AVG(totalcallin) AS totalcallin,
    AVG(totalcallout) AS totalcallout,
    AVG(totalcallint) AS totalcallint,
    AVG(keystroke) AS keystroke,
    AVG(totalemails) AS totalemails,
    SUM(totalActiveHours) AS totalActiveHours_TOT,
    SUM([Non Work Hours]) AS [Non Work Hours_TOT],
    SUM([WorkHours]) AS WorkHours_TOT,
    SUM(totalcall) AS totalcall_TOT,
    SUM(avgcalls) AS avgcalls_TOT,
    SUM(totaldurationmin) AS totaldurationmin_TOT,
    SUM(totalcallin) AS totalcallin_TOT,
    SUM(totalcallout) AS totalcallout_TOT,
    SUM(totalcallint) AS totalcallint_TOT,
    SUM(keystroke) AS keystroke_TOT,
    SUM(totalemails) AS totalemails_TOT

  FROM #ACTIVITY
  WHERE IsMiscellaneous = 0
  /*==== SECOND TABLE Return TOTAL ====*/


  /*==== THIRD TABLE Return Mis Avg ====*/

  SELECT
    CAST(AVG(CAST([startdate] AS float)) AS datetime) AS [startdate],
    AVG(totalActiveHours) AS totalActiveHours,
    AVG([Non Work Hours]) AS [Non Work Hours],
    AVG(WorkHours) AS WorkHours,
    AVG(startdateminute) AS startdateminute,
    AVG(enddateminute) AS enddateminute,
    ISNULL(CONVERT(varchar(10), AVG(startdateminute) / 60) + ':' +
                                                                  CASE
                                                                    WHEN
                                                                      LEN(CONVERT(varchar(10), AVG(startdateminute) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG(startdateminute) % 60)
                                                                    ELSE CONVERT(varchar(10), AVG(startdateminute) % 60)
                                                                  END, 0) AS [Daily Start],
    ISNULL(CONVERT(varchar(10), AVG(enddateminute) / 60) + ':' +
                                                                CASE
                                                                  WHEN
                                                                    LEN(CONVERT(varchar(10), AVG(enddateminute) % 60)) = 1 THEN '0' + CONVERT(varchar(10), AVG(enddateminute) % 60)
                                                                  ELSE CONVERT(varchar(10), AVG(enddateminute) % 60)
                                                                END, 0) AS [Daily End],
    AVG(totalcall) AS totalcall,
    AVG(avgcalls) AS avgcalls,
    AVG(totaldurationmin) AS totaldurationmin,
    AVG(avgCallDuration) AS avgCallDuration,
    AVG(avgcalldurationmin) AS avgcalldurationmin,
    AVG(totalcallin) AS totalcallin,
    AVG(totalcallout) AS totalcallout,
    AVG(totalcallint) AS totalcallint,
    AVG(keystroke) AS keystroke,
    AVG(totalemails) AS totalemails,
    SUM(totalActiveHours) AS totalActiveHours_TOT,
    SUM([Non Work Hours]) AS [Non Work Hours_TOT],
    SUM([WorkHours]) AS WorkHours_TOT,
    SUM(totalcall) AS totalcall_TOT,
    SUM(avgcalls) AS avgcalls_TOT,
    SUM(totaldurationmin) AS totaldurationmin_TOT,
    SUM(totalcallin) AS totalcallin_TOT,
    SUM(totalcallout) AS totalcallout_TOT,
    SUM(totalcallint) AS totalcallint_TOT,
    SUM(keystroke) AS keystroke_TOT,
    SUM(totalemails) AS totalemails_TOT

  FROM #ACTIVITY
  WHERE IsMiscellaneous = 1
/*==== THIRD TABLE Return Mis Avg ====*/
--SELECT * FROM #ACTIVITY WHERE IsMiscellaneous =1
END
GO
