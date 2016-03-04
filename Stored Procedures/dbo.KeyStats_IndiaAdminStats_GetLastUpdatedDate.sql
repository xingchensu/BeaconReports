SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ================================================================================================================================
-- Author:		Beno Mathew
-- Create date: 12/14/2015
-- Description:	Created sp to get the last update date
-- 
-- TEST :: [dbo].[KeyStats_IndiaAdminStats_GetLastUpdatedDate]
-- ================================================================================================================================
CREATE PROCEDURE [dbo].[KeyStats_IndiaAdminStats_GetLastUpdatedDate]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT MAX(SnapShotDate) AS[LastUpdatedDateTime] FROM [dbo].[KeyStats_IndiaAdminStats_Snapshot];
END
GO
