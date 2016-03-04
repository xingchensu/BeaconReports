SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Leonardo Tanoue
-- Create date: 7/16/2015
-- Description:	Load All Categories
-- =============================================
--[KeyStats_Category_LoadALl]
CREATE PROCEDURE [dbo].[KeyStats_Category_LoadALl]
AS
BEGIN	
	SELECT [CategoryID],[CategoryName],[CompanyName]
	FROM BeaconReports.[dbo].[KeyStats_Categories]
	ORDER BY CompanyName,CategoryName
	--ORDER BY NECESSARY HERE?
END


GO
