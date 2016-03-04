CREATE ROLE [CrystalReportUser]
AUTHORIZATION [dbo]
GO
EXEC sp_addrolemember N'CrystalReportUser', N'ECS\BLarson'
GO
EXEC sp_addrolemember N'CrystalReportUser', N'ECS\dwallner'
GO
EXEC sp_addrolemember N'CrystalReportUser', N'ECS\jbeketa'
GO
