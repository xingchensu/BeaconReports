SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tony Mykhaylovsky
-- Create date: 12/10/2015
-- Description:	Gets all US States
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_GetUSAStates]
AS
BEGIN
	SELECT state FROM Intranet_BeaconFunding.dbo.[State] ORDER BY state ASC
END
GO
