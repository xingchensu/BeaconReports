SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/11/2015
-- Description:	To get individual heading
-- =============================================

CREATE FUNCTION [dbo].[ufnCheckUniqueUserIdForReusedLicenceTickets]
    (
	  @UserName AS VARCHAR(25) ,
      @ToDate AS DATE
    )
RETURNS VARCHAR(25)
AS 
    BEGIN
		
		DECLARE @ActualUserName AS VARCHAR(25) = @UserName;

		-- If Andrew Shearn's licence is having any tickets between 9/5/2014 to 10/07/15, then it will go to jamie's stats

		IF LOWER(@UserName) = 'ashearn' AND @ToDate < '10/07/15'
			SET @ActualUserName = 'JZhang';

        RETURN @ActualUserName;
    END


	
GO
