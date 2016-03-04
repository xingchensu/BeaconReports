SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ruonan
-- Create date: 6/22/2015
-- Description:	Create sp loading employee list
-- Updated by Leo on 06/30/2015 adding CRMGuid
-- Update by Leo on 07/16/2015 added @isMisc functionality
-- =============================================
--[KeyStats_EmployeeList_Load] 13,0
CREATE PROCEDURE [dbo].[KeyStats_EmployeeList_Load]--1,null,1
	@GroupNo as int=null,
	@isMisc as int = NULL,
	@loadall as bit =0
AS
if @loadall=1
begin
	SELECT e.fname,e.lname, e.fname + ' ' + e.lname as fullname,  e.[lname] + ', ' + e.[fname] as [fullname2],  
	username,e.Companyname,startdate,shift,userid,e.CRMGuid,UniqueUserId
	FROM
	dbo.KeyStats_AllEmployees e 
    order by e.Companyname,e.[lname]
end
else
begin

IF @isMisc IS NULL
	BEGIN
		SELECT e.fname,e.lname, e.fname + ' ' + e.lname as fullname,  e.[lname] + ', ' + e.[fname] as [fullname2],  
		username,startdate,shift,userid,r.CategoryID,Categoryname,e.CRMGuid
		,r.IsMiscellaneous,e.UniqueUserID
		FROM
		dbo.KeyStats_AllEmployees e 
		INNER JOIN dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
		INNER JOIN dbo.KeyStats_Categories c ON c.CategoryID=r.CategoryID
			where c.CategoryID=@GroupNo
		order by e.[fname]
	END
ELSE
	BEGIN	
		SELECT e.fname,e.lname, e.fname + ' ' + e.lname as fullname,  e.[lname] + ', ' + e.[fname] as [fullname2],  
		username,startdate,shift,userid,r.CategoryID,Categoryname,e.CRMGuid
		,r.IsMiscellaneous,e.UniqueUserID
		FROM
		dbo.KeyStats_AllEmployees e 
		INNER JOIN dbo.KeyStats_Category_Employee_Relation r ON r.CompanyID=e.Company and r.EmployeeID=e.UserID
		INNER JOIN dbo.KeyStats_Categories c ON c.CategoryID=r.CategoryID
			where r.IsMiscellaneous = @isMisc AND c.CategoryID=@GroupNo
		order by e.[fname]
    END
    end
GO
