SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Leo
-- Create date: 7/30/2015
-- Description:	Inserts one employee from the KeyStats_AllEmployee to a specific category and with isMisc
-- =============================================
--[KeyStats_EmployeeList_RemoveEmployee] 2442,7,0
CREATE PROCEDURE [dbo].[KeyStats_EmployeeList_RemoveEmployee]

@ID AS INT,
@CategoryID AS INT,
@isMisc AS INT

AS

DECLARE @isUser int
DECLARE @IsAdded int

BEGIN	
    
    SELECT @isUser = COUNT(1) FROM BeaconReports.[dbo].[KeyStats_AllEmployees]
    WHERE UniqueUserId = @ID
    
    SELECT @isAdded = COUNT(1) FROM BeaconReports.[dbo].[KeyStats_Category_Employee_Relation]
    WHERE UniqueUserId = @ID AND CategoryId = @CategoryID AND IsMiscellaneous = @isMisc
    
    IF @isUser > 0 AND @isAdded = 1
    BEGIN
	
	DELETE FROM BeaconReports.[dbo].[KeyStats_Category_Employee_Relation]
    WHERE UniqueUserId = @ID AND CategoryId = @CategoryID AND IsMiscellaneous = @isMisc
   
    END
END
GO
