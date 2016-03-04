SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Leo
-- Create date: 7/30/2015
-- Description:	Inserts one employee from the KeyStats_AllEmployee to a specific category and with isMisc
-- =============================================
--[KeyStats_EmployeeList_AddEmployee] 2442,7,0
CREATE PROCEDURE [dbo].[KeyStats_EmployeeList_AddEmployee]
    @ID AS INT ,
    @CategoryID AS INT ,
    @isMisc AS INT
AS 
    DECLARE @isUser INT
    DECLARE @isAdded INT
    DECLARE @CompanyID INT
    DECLARE @EmployeeID INT
    DECLARE @CompanyName NVARCHAR(50)
    DECLARE @FirstName NVARCHAR(100)
    DECLARE @LastName NVARCHAR(100)

    BEGIN	
    
        SELECT  @isUser = COUNT(1)
        FROM    BeaconReports.[dbo].[KeyStats_AllEmployees]
        WHERE   UniqueUserId = @ID
    
        SELECT  @isAdded = COUNT(1)
        FROM    BeaconReports.[dbo].[KeyStats_Category_Employee_Relation]
        WHERE   UniqueUserId = @ID
                AND CategoryId = @CategoryID
    
        IF @isUser > 0
            AND @isAdded = 0 
            BEGIN
    
                SELECT  @CompanyID = Company ,
                        @CompanyName = CompanyName ,
                        @FirstName = FName ,
                        @LastName = LName ,
                        @EmployeeID = UserID
                FROM    BeaconReports.[dbo].[KeyStats_AllEmployees]
                WHERE   UniqueUserId = @ID
	
                INSERT  INTO BeaconReports.[dbo].[KeyStats_Category_Employee_Relation]
                        ( [CompanyID] ,
                          [CompanyName] ,
                          [EmployeeID] ,
                          [FName] ,
                          [LName] ,
                          [CategoryID] ,
                          [IsMiscellaneous] ,
                          [UniqueUserID]
                        )
                VALUES  ( @CompanyID ,
                          @CompanyName ,
                          @EmployeeID ,
                          @FirstName ,
                          @LastName ,
                          @CategoryID ,
                          @isMisc ,
                          @ID
                        )
   
            END
        IF @isUser > 0
            AND @isAdded = 1 
            BEGIN
                UPDATE  [dbo].[KeyStats_Category_Employee_Relation]
                SET     IsMiscellaneous = @isMisc
                WHERE   UniqueUserId = @ID
            END  
    END
GO
