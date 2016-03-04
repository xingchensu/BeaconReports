IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'ECS\jbeketa')
CREATE LOGIN [ECS\jbeketa] FROM WINDOWS
GO
CREATE USER [ECS\jbeketa] FOR LOGIN [ECS\jbeketa]
GO
