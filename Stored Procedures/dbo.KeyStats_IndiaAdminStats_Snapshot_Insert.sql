SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ================================================================================================================================
-- Author		: Beno Mathew
-- Create date	: 11/12/2015
-- Description	: This sp is to take snapshot of the live tables stats on daily basis
-- 
-- TEST			: [dbo].[KeyStats_IndiaAdminStats_Snapshot_Insert]
-- ================================================================================================================================
CREATE PROCEDURE [dbo].[KeyStats_IndiaAdminStats_Snapshot_Insert]
AS
BEGIN
	DECLARE @DATE AS DATE;
	DECLARE @CurrentDate AS DATE = GETDATE();
	SET @DATE = DATEADD(MONTH,-1,@CurrentDate); -- Default Initial Date
	
	SELECT @DATE;

	-- DELETE ALL RECORDS FROM SNAPSHOT TABLE
	DELETE FROM dbo.[KeyStats_IndiaAdminStats_Snapshot] WHERE ActivityDate >= @DATE;
	
	WHILE(@DATE <= @CurrentDate)
	BEGIN
		-- INDIA ADMIN EMPLOYEE DATA : START ===============
		IF OBJECT_ID('tempdb..#IndiaAdminEmployees') IS NOT NULL
		BEGIN
			Drop Table #IndiaAdminEmployees
		END
		SELECT
			e.*, e.[fname] + ' ' + e.[lname] as fullname, e.[lname] + ', ' + e.[fname] as [fullname2], r.IsMiscellaneous, edsalary.HourlyPayUSD
		INTO #IndiaAdminEmployees
		FROM [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_AllEmployees e 
			 INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Category_Employee_Relation r on r.CompanyID=e.Company and r.EmployeeID=e.UserID
			 INNER JOIN [LINK_SQLPROD02].[Intranet_Beaconfunding].dbo.KeyStats_Categories c on c.CategoryID=r.CategoryID
			 LEFT JOIN link_edsql04.[EmbroideryDesigns_Sites].[ADMIN].[vw_printart_salaryinfo] edsalary ON edsalary.UserName = e.username
			 WHERE c.CategoryID=4
		-- INDIA ADMIN EMPLOYEE DATA : END ===============
		
		-- CAFE PRESS DATA : START ===============
		IF OBJECT_ID('tempdb..#CafePressData') IS NOT NULL
		BEGIN
			Drop Table #CafePressData
		END
		SELECT
			[fullloginname], cp.[CP_TotalHrs], cp.[CP_FocusHrs], cp.[CP_ActiveHrs]
		INTO #CafePressData
		FROM (SELECT [fullloginname]
		, SUM(ISNULL([TotalTime_Hrs], 0)) AS 'CP_TotalHrs'
		, SUM(ISNULL([focustime_Hrs], 0)) AS 'CP_FocusHrs'
		, SUM(ISNULL([ActiveTime_Hrs], 0)) AS 'CP_ActiveHrs'
		FROM [LINK_BFCSQL01].[SPCTR_ADMIN_ARCHIVE_CUSTOM].[dbo].[Webactivity_Daily_Cafepress]
		WHERE [ActivityDate] = @DATE
		GROUP BY [fullloginname]) cp
		-- CAFE PRESS DATA : END ===============
		
		-- ZAZZLE DATA : START ===============
		IF OBJECT_ID('tempdb..#ZazzleData') IS NOT NULL
		BEGIN
			Drop Table #ZazzleData
		END
		SELECT
			[fullloginname], zz.[ZZ_TotalHrs], zz.[ZZ_FocusHrs], zz.[ZZ_ActiveHrs]
		INTO #ZazzleData
		FROM (SELECT [fullloginname]
		, SUM(ISNULL([TotalTime_Hrs], 0)) AS 'ZZ_TotalHrs'
		, SUM(ISNULL([focustime_Hrs], 0)) AS 'ZZ_FocusHrs'
		, SUM(ISNULL([ActiveTime_Hrs], 0)) AS 'ZZ_ActiveHrs'
		FROM [LINK_BFCSQL01].[SPCTR_ADMIN_ARCHIVE_CUSTOM].[dbo].[Webactivity_Daily_Zazzle]
		WHERE [ActivityDate] = @DATE
		GROUP BY [fullloginname]) zz
		-- ZAZZLE DATA : END ===============

		-- SHUTTER SHOCK DATA : START ===============
		IF OBJECT_ID('tempdb..#ShutterStockData') IS NOT NULL
		BEGIN
			Drop Table #ShutterStockData
		END
		SELECT
			[fullloginname], ss.[SS_TotalHrs], ss.[SS_FocusHrs], ss.[SS_ActiveHrs]
		INTO #ShutterStockData
		FROM (SELECT [fullloginname]
		, SUM(ISNULL([TotalTime_Hrs], 0)) AS 'SS_TotalHrs'
		, SUM(ISNULL([focustime_Hrs], 0)) AS 'SS_FocusHrs'
		, SUM(ISNULL([ActiveTime_Hrs], 0)) AS 'SS_ActiveHrs'
		FROM [LINK_BFCSQL01].[SPCTR_ADMIN_ARCHIVE_CUSTOM].[dbo].[Webactivity_Daily_Shutterstock]
		WHERE [ActivityDate] = @DATE
		GROUP BY [fullloginname]) ss
		-- SHUTTER SHOCK DATA : END ===============

		-- DREAMS TIME DATA : START ===============
		IF OBJECT_ID('tempdb..#DreamsTimeData') IS NOT NULL
		BEGIN
			Drop Table #DreamsTimeData
		END
		SELECT
			[fullloginname], dt.[DT_TotalHrs], dt.[DT_FocusHrs], dt.[DT_ActiveHrs]
		INTO #DreamsTimeData
		FROM (SELECT [fullloginname]
		, SUM(ISNULL([TotalTime_Hrs], 0)) AS 'DT_TotalHrs'
		, SUM(ISNULL([focustime_Hrs], 0)) AS 'DT_FocusHrs'
		, SUM(ISNULL([ActiveTime_Hrs], 0)) AS 'DT_ActiveHrs'
		FROM [LINK_BFCSQL01].[SPCTR_ADMIN_ARCHIVE_CUSTOM].[dbo].[Webactivity_Daily_Dreamstime]
		WHERE [ActivityDate] = @DATE
		GROUP BY [fullloginname]) dt
		-- DREAMS TIME DATA : END ===============

		-- 123 RF DATA : START ===============
		IF OBJECT_ID('tempdb..#123RFData') IS NOT NULL
		BEGIN
			Drop Table #123RFData
		END
		SELECT
			[fullloginname], rf.[RF_TotalHrs], rf.[RF_FocusHrs], rf.[RF_ActiveHrs]
		INTO #123RFData
		FROM (SELECT [fullloginname]
		, SUM(ISNULL([TotalTime_Hrs], 0)) AS 'RF_TotalHrs'
		, SUM(ISNULL([focustime_Hrs], 0)) AS 'RF_FocusHrs'
		, SUM(ISNULL([ActiveTime_Hrs], 0)) AS 'RF_ActiveHrs'
		FROM [LINK_BFCSQL01].[SPCTR_ADMIN_ARCHIVE_CUSTOM].[dbo].[Webactivity_Daily_123rf]
		WHERE [ActivityDate] = @DATE
		GROUP BY [fullloginname]) rf
		-- 123 RF DATA : END ===============

		-- Design Count from Design Added Table : START ===============
		IF OBJECT_ID('tempdb..#DesignAdded') IS NOT NULL
		BEGIN
			Drop Table #DesignAdded
		END
		SELECT
			[UserName], da.[CP_Designs], da.[ZZ_Designs], da.[SS_Designs], da.[DT_Designs], da.[RF_Designs]
		INTO #DesignAdded
		FROM (SELECT ed.[UserName]
		, COUNT(CASE WHEN ed.[DisplayName] = 'Cafe Press' THEN 1 ELSE NULL END) AS 'CP_Designs'
		, COUNT(CASE WHEN ed.[DisplayName] = 'Zazzle' THEN 1 ELSE NULL END) AS 'ZZ_Designs'
		, COUNT(CASE WHEN ed.[DisplayName] = 'ShutterStock' THEN 1 ELSE NULL END) AS 'SS_Designs'
		, COUNT(CASE WHEN ed.[DisplayName] = 'DreamsTime' THEN 1 ELSE NULL END) AS 'DT_Designs'
		, COUNT(CASE WHEN ed.[DisplayName] = '123RF' THEN 1 ELSE NULL END) AS 'RF_Designs'
		FROM [LINK_EDSQL04].[EmbroideryDesigns_Sites].[ADMIN].[vw_printart_designsadded] ed
		WHERE  dateadded = @DATE
		GROUP BY ed.[UserName]) da
		-- Design Count from Design Added Table : END ===============

		-- Reported Hours from TimeSheets Table : START ===============
		IF OBJECT_ID('tempdb..#ReportedHours') IS NOT NULL
		BEGIN
			Drop Table #ReportedHours
		END
		SELECT
			[UserName], rh.[CP_RepotedHrs], rh.[ZZ_RepotedHrs], rh.[SS_RepotedHrs], rh.[DT_RepotedHrs], rh.[RF_RepotedHrs]
			, rh.[CP_ReportedDesigns], rh.[ZZ_ReportedDesigns], rh.[SS_ReportedDesigns], rh.[DT_ReportedDesigns], rh.[RF_ReportedDesigns]
		INTO #ReportedHours
		FROM (SELECT ts.[UserName]
		-- Reported Design Count
		, COUNT(CASE WHEN ts.[DisplayName] = 'Cafe Press' THEN 1 ELSE NULL END) AS 'CP_ReportedDesigns'
		, COUNT(CASE WHEN ts.[DisplayName] = 'Zazzle' THEN 1 ELSE NULL END) AS 'ZZ_ReportedDesigns'
		, COUNT(CASE WHEN ts.[DisplayName] = 'ShutterStock' THEN 1 ELSE NULL END) AS 'SS_ReportedDesigns'
		, COUNT(CASE WHEN ts.[DisplayName] = 'DreamsTime' THEN 1 ELSE NULL END) AS 'DT_ReportedDesigns'
		, COUNT(CASE WHEN ts.[DisplayName] = '123RF' THEN 1 ELSE NULL END) AS 'RF_ReportedDesigns' 
		-- Reported Hours
		, SUM(CASE WHEN ts.[DisplayName] = 'Cafe Press' THEN ts.[Hours] ELSE NULL END) AS 'CP_RepotedHrs'
		, SUM(CASE WHEN ts.[DisplayName] = 'Zazzle' THEN ts.[Hours] ELSE NULL END) AS 'ZZ_RepotedHrs'
		, SUM(CASE WHEN ts.[DisplayName] = 'ShutterStock' THEN ts.[Hours] ELSE NULL END) AS 'SS_RepotedHrs'
		, SUM(CASE WHEN ts.[DisplayName] = 'DreamsTime' THEN ts.[Hours] ELSE NULL END) AS 'DT_RepotedHrs'
		, SUM(CASE WHEN ts.[DisplayName] = '123RF' THEN ts.[Hours] ELSE NULL END) AS 'RF_RepotedHrs'
		FROM [LINK_EDSQL04].[EmbroideryDesigns_Sites].[ADMIN].[vw_printart_timesheets] ts
		WHERE ts.[DateAudited] = @DATE
		GROUP BY ts.[UserName]) rh
		-- Reported Hours from TimeSheets Table : END ===============
		
		-- ==== INSERT DATA INTO SNAPSHOT TABLE [Grouped By Employee] : START =======================
		-- ==========================================================================================

		INSERT INTO dbo.KeyStats_IndiaAdminStats_Snapshot
		([ActivityDate]

      ,[CP_Designs]
      ,[CP_ReportedDesigns]
      ,[CP_TotalHrs]
      ,[CP_ActiveHrs]
      ,[CP_RepotedHrs]
	  ,[CP_Cost]
	  ,[CP_CostPerDesign]

      ,[ZZ_Designs]
      ,[ZZ_ReportedDesigns]
      ,[ZZ_TotalHrs]
      ,[ZZ_ActiveHrs]
      ,[ZZ_RepotedHrs]
	  ,[ZZ_Cost]
	  ,[ZZ_CostPerDesign]

      ,[SS_Designs]
      ,[SS_ReportedDesigns]
      ,[SS_TotalHrs]
      ,[SS_ActiveHrs]
      ,[SS_RepotedHrs]
	  ,[SS_Cost]
	  ,[SS_CostPerDesign]

      ,[DT_Designs]
      ,[DT_ReportedDesigns]
      ,[DT_TotalHrs]
      ,[DT_ActiveHrs]
      ,[DT_RepotedHrs]
	  ,[DT_Cost]
	  ,[DT_CostPerDesign]

      ,[RF_Designs]
      ,[RF_ReportedDesigns]
      ,[RF_TotalHrs]
      ,[RF_ActiveHrs]
      ,[RF_RepotedHrs]
	  ,[RF_Cost]
	  ,[RF_CostPerDesign]

      ,[IsDeleted]
	  ,[UserID]
	  ,[FName]
	  ,[LName]
	  ,[username]
	  ,[UniqueUserId]
	  ,[shift]
	  ,[StartDate]
	  ,[fullname]
	  ,[fullname2]
	  ,[IsMiscellaneous]
	  , [HourlyPayUSD])
		SELECT @DATE as [ActivityDate]		-- ActivityDate

		, da.[CP_Designs]				-- CP_Designs
		, rh.[CP_ReportedDesigns]		-- CP_ReportedDesigns
		, cp.[CP_TotalHrs]				-- CP_TotalHrs
		, cp.[CP_ActiveHrs]				-- CP_ActiveHrs
		, rh.[CP_RepotedHrs]			-- CP_RepotedHrs
		, rh.[CP_RepotedHrs] * e.[HourlyPayUSD]		-- CP_Cost
		, CASE WHEN ISNULL(da.[CP_Designs], 0) <> 0 THEN (rh.[CP_RepotedHrs] * e.[HourlyPayUSD])/da.[CP_Designs] ELSE 0 END	-- CP_CostPerDesign

		, da.[ZZ_Designs]				-- ZZ_Designs
		, rh.[ZZ_ReportedDesigns]		-- ZZ_ReportedDesigns
		, zz.[ZZ_TotalHrs]				-- ZZ_TotalHrs
		, zz.[ZZ_ActiveHrs]				-- ZZ_ActiveHrs
		, rh.[ZZ_RepotedHrs]			-- ZZ_RepotedHrs
		, rh.[ZZ_RepotedHrs] * e.[HourlyPayUSD]		-- ZZ_Cost
		, CASE WHEN ISNULL(da.[ZZ_Designs], 0) <> 0 THEN (rh.[ZZ_RepotedHrs] * e.[HourlyPayUSD])/da.[ZZ_Designs] ELSE 0 END	-- ZZ_CostPerDesign

		, da.[SS_Designs]				-- SS_Designs
		, rh.[SS_ReportedDesigns]		-- SS_ReportedDesigns
		, ss.[SS_TotalHrs]				-- SS_TotalHrs
		, ss.[SS_ActiveHrs]				-- SS_ActiveHrs
		, rh.[SS_RepotedHrs]			-- SS_RepotedHrs
		, rh.[SS_RepotedHrs] * e.[HourlyPayUSD]		-- SS_Cost
		, CASE WHEN ISNULL(da.[SS_Designs], 0) <> 0 THEN (rh.[SS_RepotedHrs] * e.[HourlyPayUSD])/da.[SS_Designs] ELSE 0 END	-- SS_CostPerDesign

		, da.[DT_Designs]				-- DT_Designs
		, rh.[DT_ReportedDesigns]		-- DT_ReportedDesigns
		, dt.[DT_TotalHrs]				-- DT_TotalHrs
		, dt.[DT_ActiveHrs]				-- DT_ActiveHrs
		, rh.[DT_RepotedHrs]			-- DT_RepotedHrs
		, rh.[DT_RepotedHrs] * e.[HourlyPayUSD]		-- DT_Cost
		, CASE WHEN ISNULL(da.[DT_Designs], 0) <> 0 THEN (rh.[DT_RepotedHrs] * e.[HourlyPayUSD])/da.[DT_Designs] ELSE 0 END	-- DT_CostPerDesign

		, da.[RF_Designs]				-- RF_Designs
		, rh.[RF_ReportedDesigns]		-- RF_ReportedDesigns
		, rf.[RF_TotalHrs]				-- RF_TotalHrs
		, rf.[RF_ActiveHrs]				-- RF_ActiveHrs
		, rh.[RF_RepotedHrs]			-- RF_RepotedHrs
		, rh.[RF_RepotedHrs] * e.[HourlyPayUSD]		-- RF_Cost
		, CASE WHEN ISNULL(da.[RF_Designs], 0) <> 0 THEN (rh.[RF_RepotedHrs] * e.[HourlyPayUSD])/da.[RF_Designs] ELSE 0 END	-- RF_CostPerDesign

		, 0	AS [IsDeleted]				-- IsDeleted
		, e.[UserID]					-- userid
		, e.[FName]						-- FName
		, e.[LName]						-- LName
		, e.[username]					-- username
		, e.[UniqueUserId]				-- UniqueUserId
		, e.[shift]
		, e.[StartDate]					-- StartDate
		, e.[fullname]					-- userid
		, e.[fullname2]					-- userid
		, e.[IsMiscellaneous]			-- IsMiscellaneous
		, e.[HourlyPayUSD]			-- HourlyPayUSD
		FROM #IndiaAdminEmployees e
		LEFT JOIN #CafePressData cp on LOWER(cp.[fullloginname]) = LOWER(e.[username])
		LEFT JOIN #ZazzleData zz on LOWER(zz.[fullloginname]) = LOWER(e.[username])
		LEFT JOIN #ShutterStockData ss on LOWER(ss.[fullloginname]) = LOWER(e.[username])
		LEFT JOIN #DreamsTimeData dt on LOWER(dt.[fullloginname]) = LOWER(e.[username])
		LEFT JOIN #123RFData rf on LOWER(rf.[fullloginname]) = LOWER(e.[username])
		LEFT JOIN #DesignAdded da on LOWER(da.[UserName]) = LOWER(e.[username])
		LEFT JOIN #ReportedHours rh on LOWER(rh.[UserName]) = LOWER(e.[username])

		-- ==== INSERT DATA INTO SNAPSHOT TABLE [Grouped By Employee] : END =========================
		-- ==========================================================================================
		
		
		-- INCREMENT COUNTER VALUE
		SET @DATE = DATEADD(DAY, 1, @DATE);
	END
END
GO
