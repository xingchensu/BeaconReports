SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SalesRanking_IsConfidentailEvaluationViewer]--'EC857A0B-0E3B-E111-8A82-78E7D1F817F8',1
	@uid uniqueidentifier,
	@result bit out
AS
BEGIN
	--one-off manager is qualified viewer
	if exists(select LastName + ', ' + FirstName AS fullname, su.SystemUserId FROM dbo.systemuser su
INNER JOIN
dbo.SystemUserRoles sur
on su.SystemUserId = sur.SystemUserId
WHERE (IsDisabled = 0 AND (sur.RoleId = 'B17C396F-34DB-DC11-AAED-0017A4477DFB')
and  su.SystemUserId= @uid) or @uid='EC857A0B-0E3B-E111-8A82-78E7D1F817F8'--ruonan
)
set @result=1
else
set @result=0
END
select @result
GO
