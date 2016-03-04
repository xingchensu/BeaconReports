IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'ECS\Sakumar')
CREATE LOGIN [ECS\Sakumar] FROM WINDOWS
GO
CREATE USER [ECS\Sakumar] FOR LOGIN [ECS\Sakumar]
GO
