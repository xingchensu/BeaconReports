SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tony Mykhaylovsky
-- Create date: 12/16/2015
-- Description:	Repo Details
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_Repo_LoadRepoDetails] --@BeginDate = N'1/1/2015', @EndDate = N'12/31/2015'
	@DateRangeCode AS CHAR(3) = NULL
	,@BeginDate AS DATETIME
	,@EndDate AS DATETIME
	,@RepoTypeID AS INT = NULL
	,@SalesPersonGUID AS VARCHAR(36) = NULL
	,@CollectorGUID AS VARCHAR(36) = NULL
	,@CreditManagerGUID AS VARCHAR(36) = NULL
	,@americanStateCode AS VARCHAR(2) = NULL
	,@equipmentTypeValue AS VARCHAR(36) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @BeginDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @BeginDate)
	SET @EndDate = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), @EndDate)

	SELECT cr.*
	FROM [dbo].[KeyStats_Repo_ClosedRepos_DailySnapShot] cr
	WHERE CONVERT(DATE,cr.closedon) BETWEEN CONVERT(DATE,@beginDate) AND CONVERT(DATE,@endDate)
	AND cr.[TypeValue] = ISNULL(@repoTypeID,cr.[TypeValue]) 
	AND cr.SalesPersonGUID like ISNULL(@SalesPersonGUID,cr.SalesPersonGUID)
	AND cr.CollectorGUID = ISNULL(@CollectorGUID,cr.CollectorGUID)
	AND cr.CreditManagerGUID like ISNULL(@CreditManagerGUID,cr.CreditManagerGUID)
	AND cr.CustomerState = ISNULL(@americanStateCode,cr.CustomerState)
	AND cr.EquipTypes like ISNULL(@equipmentTypeValue,cr.EquipTypes)
END

--[dbo].[KeyStats_Repo_LoadRepoDetails] N'5/20/2015',N'12/20/2015'
GO
