SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:    ruonan
-- Create date: 12/17/2014
-- Description:  load inside sales INCENTIVE
-- =============================================
--[dbo].[SalesRanking_LoadInsideSalesIncentive]'8/1/2015','10/31/2015 23:59:59','10/1/2015',1
CREATE PROCEDURE [dbo].[SalesRanking_LoadInsideSalesIncentive] @STARTDATE AS datetime = NULL, @ENDDATE AS datetime = NULL,
@ENDmonthSTARTDATE AS datetime = NULL,
@takingSnapShot AS bit = 0

AS

if exists(select * from dbo.CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot
where [Month]=month(@ENDDATE) and  [year]=year(@ENDDATE))
begin
	  SELECT
	  [agentcode],
               [CRMGuid],
          SUM([Connects]) AS [Connects],
        SUM([Leads]) AS [Leads],
        SUM([Oppty]) AS [Oppty],
        SUM([ConnectsBonus]) AS [ConnectsBonus],
        SUM([OpptyBonus]) AS [OpptyBonus],
        SUM(ISNULL([ConnectsLeadsBonus], 0)) AS [ConnectsLeadsBonus],
        SUM([ConnectsOpptyBonus]) AS [ConnectsOpptyBonus],
        SUM([TotalBonus]) AS [TotalBonus],
        max(SnapShotDateTime) AS dateupdated
      FROM CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot
      WHERE CAST((CONVERT(varchar(10), [Month]) + '/1/' + CONVERT(varchar(10), [year])) AS date) <= @ENDDATE
      AND CAST((CONVERT(varchar(10), [Month]) + '/1/' + CONVERT(varchar(10), [year])) AS date) >= @STARTDATE
        GROUP BY [agentcode],
               [CRMGuid]

end
else
begin
  DECLARE @STARTDATE_temp AS datetime,
          @ENDDATE_temp AS datetime

  IF @takingSnapShot = 1
  BEGIN
    SET @STARTDATE_temp = CAST(CAST(DATEADD(MONTH, -1, getdate()) AS date) AS datetime)
    SET @ENDDATE_temp = DATEADD(SECOND, -1, CAST(CAST( getdate() AS date) AS datetime))
  END
  ELSE
  BEGIN
    IF @ENDmonthSTARTDATE IS NULL
    BEGIN
      SET @STARTDATE_temp = @STARTDATE
      SET @ENDDATE_temp = @ENDDATE
    END
    ELSE
    BEGIN
      SET @ENDDATE_temp = @ENDDATE
      SET @STARTDATE_temp = @ENDmonthSTARTDATE-- CONVERT(varchar(10), MONTH(@ENDDATE_temp)) + '/1/' + CONVERT(varchar(10), YEAR(@ENDDATE_temp) - 1)


    END
  END




  IF OBJECT_ID('tempdb..#callquality') IS NOT NULL
  BEGIN
    DROP TABLE #callquality
  END

  CREATE TABLE #callquality (
    Username nvarchar(100),
    CallQuality decimal(5, 2),
    AgentCode varchar(30),
    TotalCallsEvaluated int
  )




  INSERT INTO #callquality (Username, CallQuality, AgentCode, TotalCallsEvaluated)
    SELECT

      Users.lastName + ', ' + Users.firstName AS 'Agent Name',
      AVG(Percentage) AS 'Percentage',
      R.tsr,
      COUNT(*) AS TotalCallsEvaluated
    FROM [CRMReplication].[dbo].[Noble_Recording_Evaluations] E
    JOIN [CRMReplication].[dbo].[Noble_Maestro_nsc_recordings] R
      ON E.record_id = r.record_id
    JOIN [Intranet_Beaconfunding].[dbo].[CallCenter_ActionAgentInfo] Users
      ON r.tsr = Users.nobleAgentID

    WHERE E.createdon >= @STARTDATE_temp
    AND E.createdon <= @ENDDATE_temp
    AND e.evaluation_type_id = 1
    GROUP BY tsr,
             Users.firstName,
             Users.lastName





  IF OBJECT_ID('tempdb..#Activity_temp') IS NOT NULL
  BEGIN
    DROP TABLE #Activity_temp
  END
  CREATE TABLE #Activity_temp (
    agentname varchar(200),
    agentcode varchar(10),
    CRMGuid uniqueidentifier,
    DomainName nvarchar(100)
  )
  INSERT INTO #Activity_temp (agentname,
  agentcode,
  CRMGuid,
  DomainName)

    SELECT
      su.FullName,
      ca.nobleAgentID,
      su.SystemUserId,
      su.DomainName
    FROM dbo.systemuser su
    INNER JOIN Intranet_Beaconfunding.dbo.CallCenter_ActionAgentInfo ca
      ON 'ECS\' + ca.bfcUsername = su.DomainName
    INNER JOIN dbo.Noble_AgentCode_Campaigns nac
      ON ca.nobleAgentID = nac.AgentCode
    WHERE su.IsDisabled = 0
    AND ca.nobleActive = 1
    AND nac.DefaultCampaign = 1
    AND ca.isecsagent = 0
    --and su.DomainName <>'ECS\SPearce'
    AND su.SystemUserId IN (SELECT
      su.SystemUserId
    FROM dbo.systemuser su
    INNER JOIN dbo.SystemUserRoles sur
      ON su.SystemUserId = sur.SystemUserId
    INNER JOIN Intranet_Beaconfunding.dbo.tblUsers t
      ON 'ECS\' + t.username = su.domainname

    LEFT JOIN [Intranet_Beaconfunding].[dbo].[CallCenter_ActionAgentInfo] Users
      ON users.bfcusername = t.username
    WHERE IsDisabled = 0
    AND sur.RoleId = 'ED4FDE05-3337-E111-98DF-78E7D1F817F8'
    AND (isECSAgent IS NULL
    OR (isECSAgent IS NOT NULL
    AND isECSAgent = 0))
    AND su.SystemUserId <> '8DB6B37F-6D1B-E511-9EC8-78E7D1F817F8'--not steve pearce
    )




  --select * from #Activity_temp



  IF OBJECT_ID('tempdb..#EmployeeActivities_Phone_Log_PerCall') IS NOT NULL
    DROP TABLE #EmployeeActivities_Phone_Log_PerCall
  SELECT
    COUNT(extension) AS totalcall,
    directoryname,
    fullname INTO #EmployeeActivities_Phone_Log_PerCall
  FROM LINK_BFCSQL01.SPCTR_ADMIN_ARCHIVE_CUSTOM.dbo.XCelsius_EmployeeActivities_Phone_Log_PerCall
  WHERE Date_time >= CONVERT(varchar(100), @STARTDATE_temp)
  AND Date_time <= CONVERT(varchar(100), @ENDDATE_temp)
  GROUP BY directoryname,
           fullname


  --update #EmployeeActivities_Phone_Log_PerCall
  --set fullname='Bockhorn, Steve'
  --where fullname='Bockhorn, Steven'


  --update #EmployeeActivities_Phone_Log_PerCall
  --set fullname='Kilkenny, Elizabeth'
  --where fullname='Kilkenny, Liz'


  IF OBJECT_ID('tempdb..#Activity') IS NOT NULL
  BEGIN
    DROP TABLE #Activity
  END
  CREATE TABLE #Activity (
    agentname varchar(200),
    agentcode varchar(10),
    CRMGuid uniqueidentifier,
    Connects int,
    Leads int,
    Oppty int,
    OpptyAmt money
  )






  INSERT INTO #Activity (agentname,
  agentcode,
  CRMGuid,
  Connects,
  Leads,
  Oppty,
  OpptyAmt)

    SELECT
      agentname,
      agentcode,
      at.CRMGuid,
      e.totalcall AS Connects,
      leads,
      Oppty,
      OpptyAmt--,Startdate
    FROM #Activity_temp at
    LEFT JOIN #EmployeeActivities_Phone_Log_PerCall e
      ON (at.domainname = 'ecs\' + e.directoryname)

    -- e.fullname=at.agentname
    LEFT JOIN (SELECT
      CRMGuid,
      COUNT(leadtemp.leadid) AS leads
    FROM #Activity_temp at
    LEFT JOIN (SELECT
      L.LEADID,
      --per Toby, if original created by is crm admin, use original owner instead--9/9/2015
      --   CASE WHEN  L.CREATEDON>='6/5/2015' THEN L.new_originalcreatedbyid
      --ELSE 
      --CASE WHEN L.new_originalcreatedbyid ='CA9C6436-B204-E011-B009-78E7D1F817F8' THEN L.new_originalownerid
      --ELSE L.new_originalcreatedbyid
      --END
      --END AS new_originalcreatedbyid 
      CASE
        WHEN L.new_originalcreatedbyid IS NOT NULL AND
          L.new_originalcreatedbyid = 'CA9C6436-B204-E011-B009-78E7D1F817F8' THEN L.new_originalownerid
        ELSE L.new_originalcreatedbyid
      END AS new_originalcreatedbyid

    FROM lead l
    WHERE (CAST(dbo.ConvertUTCToLocalTime(CreatedOn) AS date) >= @STARTDATE_temp
    AND CAST(dbo.ConvertUTCToLocalTime(CreatedOn) AS date) <= @ENDDATE_temp)

    AND statuscode <> 15) leadtemp
      ON leadtemp.new_originalcreatedbyid = at.CRMGuid
    GROUP BY CRMGuid) lead_t
      ON at.CRMGuid = lead_t.CRMGuid
    LEFT JOIN (SELECT
      CRMGuid,
      COUNT(opp.OpportunityId) AS Oppty,
      SUM(opp.OpptyAmt) AS OpptyAmt
    FROM #Activity_temp at
    LEFT JOIN (SELECT
      t.new_amountfinanced - ISNULL(otvE.NetDueToVendor, 0) AS OpptyAmt,
      o.opportunityid,
      --per Toby, if original created by is crm admin, use original owner instead--9/9/2015
      --CASE WHEN  O.CREATEDON>='6/5/2015' THEN o.new_originalcreatedbyid
      --ELSE 
      --CASE WHEN o.new_originalcreatedbyid ='CA9C6436-B204-E011-B009-78E7D1F817F8' THEN O.new_originalownerid
      --ELSE o.new_originalcreatedbyid
      --END
      --END AS new_originalcreatedbyid      ,


      CASE
        WHEN o.new_originalcreatedbyid IS NOT NULL AND
          o.new_originalcreatedbyid = 'CA9C6436-B204-E011-B009-78E7D1F817F8' THEN O.new_originalownerid
        ELSE o.new_originalcreatedbyid
      END AS new_originalcreatedbyid,

      o.new_originalownerid,
      o.originatingleadid,
      o.OwnerId,
      o.New_ShareCreditId,
      o.New_ShareCredit2Id,
      o.New_ShareCredit3Id,
      o.New_ShareCredit4Id,
      o.New_ShareCredit5Id

    FROM Opportunity o
    LEFT JOIN (SELECT
      New_opportunityid,
      new_opportunitytermid,
      new_amountfinanced
    FROM New_opportunityterm
    WHERE new_isinlcw = 1) t
      ON o.opportunityid = t.New_opportunityid

    LEFT JOIN (SELECT
      New_opportunitytermid,

      SUM(ISNULL(New_VendorTotalEquipmentCost, 0)) AS NetDueToVendor
    FROM New_opportunitytermvendor
    WHERE New_isuserselected = 1
    AND New_opportunitytermid IS NOT NULL

    AND (New_AccountIdName IN (SELECT
      ExcludedVendorName COLLATE SQL_Latin1_General_CP1_CI_AS
    FROM dbo.XCelsius_ExcludedVendors)
    )
    GROUP BY New_opportunitytermid) otvE
      ON otvE.New_opportunitytermid = t.new_opportunitytermid
    WHERE CAST(dbo.ConvertUTCToLocalTime(CreatedOn) AS date) >= @STARTDATE_temp
    AND CAST(dbo.ConvertUTCToLocalTime(CreatedOn) AS date) <= @ENDDATE_temp
    AND statuscode <> 24) opp
      ON opp.new_originalcreatedbyid = at.CRMGuid-- or (opp.new_originalcreatedbyid= 'CA9C6436-B204-E011-B009-78E7D1F817F8' and opp.new_originalownerid= at.CRMGuid )


    GROUP BY CRMGuid) opp_t
      ON at.CRMGuid = opp_t.CRMGuid

  --select * from #Activity
  IF @STARTDATE >= '4/1/2015' and @endDATE<'5/1/2015'
  BEGIN
    UPDATE #Activity
    SET Leads = Leads + 18
    WHERE CRMGuid = '1E810236-7616-E311-90DE-78E7D1F817F8'
  END

  IF OBJECT_ID('tempdb..#Final_t') IS NOT NULL
  BEGIN
    DROP TABLE #Final_t
  END
  CREATE TABLE #Final_t (
    agentcode varchar(10),
    CRMGuid uniqueidentifier,
    Connects int,
    Leads int,
    Oppty int,
    OpptyAmt money,
    Username nvarchar(100),
    CallQuality decimal(5, 2),
    TotalCallsEvaluated int,
    dateupdated date,
    ConnectsBonus int,
    OpptyBonus int
  --,
  --ConnectsLeadsBonus int,
  --ConnectsOpptyBonus int
  )
  INSERT INTO #Final_t (agentcode,
  CRMGuid,

  Connects,

  Leads,
  Oppty,
  OpptyAmt,
  Username,
  CallQuality,
  TotalCallsEvaluated,
  dateupdated,
  ConnectsBonus,
  OpptyBonus)
    SELECT
      a.agentcode,
      a.CRMGuid,
      a.Connects,
      a.Leads,
      a.Oppty AS opps,
      a.OpptyAmt,
      q.Username,
      q.CallQuality,
      q.TotalCallsEvaluated,
      GETDATE() AS dateupdated,

      CASE
        WHEN a.Connects >= 1750 AND
          ROW_NUMBER() OVER (ORDER BY a.Connects DESC, q.CallQuality DESC) = 1 THEN 225
        WHEN a.Connects >= 1750 AND
          ROW_NUMBER() OVER (ORDER BY a.Connects DESC, q.CallQuality DESC) = 2 THEN 150
        WHEN a.Connects >= 1750 AND
          ROW_NUMBER() OVER (ORDER BY a.Connects DESC, q.CallQuality DESC) = 3 THEN 75
        ELSE 0
      END AS ConnectsBonus,

      CASE
        WHEN a.Oppty >= 5 AND
          ROW_NUMBER() OVER (ORDER BY a.Oppty DESC, a.OpptyAmt DESC) = 1 THEN 225
        WHEN a.Oppty >= 5 AND
          ROW_NUMBER() OVER (ORDER BY a.Oppty DESC, a.OpptyAmt DESC) = 2 THEN 150
        WHEN a.Oppty >= 5 AND
          ROW_NUMBER() OVER (ORDER BY a.Oppty DESC, a.OpptyAmt DESC) = 3 THEN 75
        ELSE 0
      END AS OpptyBonus



    FROM #Activity a
    LEFT JOIN #callquality q
      ON a.agentcode = q.AgentCode




  IF OBJECT_ID('tempdb..#Final') IS NOT NULL
  BEGIN
    DROP TABLE #Final
  END

  SELECT
    f.*,
    clb.ConnectsLeadsBonus,
    cob.ConnectsOpptyBonus,
    (ISNULL(f.ConnectsBonus, 0) + ISNULL(f.OpptyBonus, 0) + ISNULL(clb.ConnectsLeadsBonus, 0) + ISNULL(cob.ConnectsOpptyBonus, 0)) AS totalBonus INTO #Final
  FROM #Final_t f
  LEFT JOIN (SELECT
    agentcode,
    CRMGuid,
    CASE

      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Leads, Leads DESC) = 1 THEN 225
      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Leads, Leads DESC) = 2 THEN 150
      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Leads, Leads DESC) = 3 THEN 75
      ELSE 0
    END AS ConnectsLeadsBonus
  FROM #Final_t
  WHERE Leads >= 20) clb
    ON f.agentcode = clb.agentcode
    AND f.CRMGuid = clb.CRMGuid
  LEFT JOIN (SELECT
    agentcode,
    CRMGuid,
    CASE

      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Oppty, Oppty DESC) = 1 THEN 225
      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Oppty, Oppty DESC) = 2 THEN 150
      WHEN ROW_NUMBER() OVER (ORDER BY Connects / Oppty, Oppty DESC) = 3 THEN 75

      ELSE 0
    END AS ConnectsOpptyBonus
  FROM #Final_t
  WHERE Oppty >= 5) cob
    ON f.agentcode = cob.agentcode
    AND f.CRMGuid = cob.CRMGuid



  IF @takingSnapShot = 1
  BEGIN
    INSERT INTO dbo.CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot
    ( [agentcode]
      ,[CRMGuid]
      ,[Connects]
      ,[Leads]
      ,[Oppty]
      ,[Username]
      ,[ConnectsBonus]
      ,[OpptyBonus]
      ,[ConnectsLeadsBonus]
      ,[ConnectsOpptyBonus]
      ,[TotalBonus]
      ,[Month]
      ,[Year])
      SELECT
        [agentcode],
        [CRMGuid],
        [Connects],
        [Leads],
        [Oppty],
       -- [OpptyAmt],
        [Username],
        --[CallQuality],
        --[TotalCallsEvaluated],
        [ConnectsBonus],
        [OpptyBonus],
        [ConnectsLeadsBonus],
        [ConnectsOpptyBonus],
        [TotalBonus],
        MONTH(@STARTDATE_temp) AS [Month],
        YEAR(@STARTDATE_temp) AS [Year]
      FROM #Final
  END
  ELSE
  BEGIN



    IF @ENDmonthSTARTDATE IS NULL
    BEGIN
      SELECT
        *
      FROM #Final

    END
    ELSE
    BEGIN
      DECLARE @dateupdated AS datetime
      SELECT TOP 1
        @dateupdated = dateupdated
      FROM #Final
      SELECT
        [agentcode],
        [CRMGuid],

        SUM([Connects]) AS [Connects],
        SUM([Leads]) AS [Leads],
        SUM([Oppty]) AS [Oppty],
        SUM([ConnectsBonus]) AS [ConnectsBonus],
        SUM([OpptyBonus]) AS [OpptyBonus],
        SUM(ISNULL([ConnectsLeadsBonus], 0)) AS [ConnectsLeadsBonus],
        SUM([ConnectsOpptyBonus]) AS [ConnectsOpptyBonus],
        SUM([TotalBonus]) AS [TotalBonus],
        @dateupdated AS dateupdated
      FROM (SELECT
        [agentcode],
        [CRMGuid],
        [Connects],
        [Leads],
        [Oppty],
        [Username],
        [ConnectsBonus],
        [OpptyBonus],
        [ConnectsLeadsBonus],
        [ConnectsOpptyBonus],
        [TotalBonus]
      FROM #Final

      UNION

      SELECT
        [agentcode],
        [CRMGuid],
        [Connects],
        [Leads],
        [Oppty],
        [Username],
        [ConnectsBonus],
        [OpptyBonus],
        [ConnectsLeadsBonus],
        [ConnectsOpptyBonus],
        [TotalBonus]
      FROM CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot
      WHERE CAST((CONVERT(varchar(10), [Month]) + '/1/' + CONVERT(varchar(10), [year])) AS date) < @STARTDATE_temp
      AND CAST((CONVERT(varchar(10), [Month]) + '/1/' + CONVERT(varchar(10), [year])) AS date) >= @STARTDATE) result
      GROUP BY [agentcode],
               [CRMGuid]


    END

    --SELECT
    --  *
    --FROM #Activity_temp
    --SELECT
    --  *
    --FROM #EmployeeActivities_Phone_Log_PerCall
    --ORDER BY fullname
  END
  end
GO
