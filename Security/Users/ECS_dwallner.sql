IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'ECS\dwallner')
CREATE LOGIN [ECS\dwallner] FROM WINDOWS
GO
CREATE USER [ECS\dwallner] FOR LOGIN [ECS\dwallner]
GO
