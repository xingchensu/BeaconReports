SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ruonan	
-- Create date: 8/19/2015
-- Description:	import online test result from careers db when add employee to the category group
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_Employee_TestScore_Update]--2442,1
	@UniqueUserId as int,
	--result
	--1: already exist
	--2: not exist, found one in the careers db and imported
	--3: not exist, not found in the careers db
	--4: not exist, found multiple in the careers db
	@Result as int output
AS
BEGIN
	
	SET NOCOUNT ON;
	declare @count as int
	select  @count=count(*) from dbo.KeyStats_Employee_TestScore
	where UniqueUserId=@UniqueUserId
	if @count>0
	begin
		set @Result=1
	end
	else 
	begin
		declare @fname as nvarchar(255)
		declare @lname as nvarchar(255)
		select @fname=FName , @lname=LName
		from dbo.KeyStats_AllEmployees 
		where UniqueUserId=@UniqueUserId
		declare @count_testresult as int
		SELECT @count_testresult=count(*)
  FROM LINK_BFCSQL02.[CareersDB].[dbo].[vwGetScores]
  where [First Name]=@fname and [Last Name]=@lname
  if @count_testresult=1
  begin
	insert into dbo.KeyStats_Employee_TestScore([UniqueUserId]
      ,[ApplicationID]
      ,[FirstName]
      ,[LastNmae]
      --,[Test Date]
      ,[MathTest]
      ,[MathTestAttempt]
      ,[ProofReadingTestA]
      ,[ProofReadingTestAAttempt]
      ,[ProofReadingTestB]
      ,[ProofReadingTestBAttepmt]
      ,[TypingTestWPM]
      ,[TypingTestAccuracy]
      ,[TypingTestKeyStrokes])
      select  @UniqueUserId,[ApplicationID]
      ,[First Name]
      ,[Last Name]
      ,[Math Test]
      ,[MathTest Attempted]
      ,[Proof Reading Test A]
      ,[Prooftest A Attempted]
      ,[Proof Reading Test B]
      ,[Prooftest B Attempted]
      ,[Typing Test - WPM]
      ,[Typing Test - Accuracy]
      ,[TypingTest KeyStrokes]
        FROM LINK_BFCSQL02.[CareersDB].[dbo].[vwGetScores]
  where [First Name]=@fname and [Last Name]=@lname
  set @Result=2
  end
  else
  begin
	if @count_testresult=0
	begin
		 set @Result=3
	end
	else
	begin
		SELECT *
  FROM LINK_BFCSQL02.[CareersDB].[dbo].[vwGetScores]
  where [First Name]=@fname and [Last Name]=@lname
	end
  end
	end
	select @Result
END
GO
