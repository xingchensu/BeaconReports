CREATE TABLE [dbo].[KeyStats_ExpectedHours]
(
[hoursID] [int] NOT NULL IDENTITY(1, 1),
[userName] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[categoryID] [int] NULL,
[expectedWorkHours] [float] NULL,
[activeStatus] [bit] NULL,
[createdDate] [datetime] NULL,
[activeTillDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_ExpectedHours] ADD CONSTRAINT [PK__KeyStats__8405D38A1EF03DF9] PRIMARY KEY CLUSTERED  ([hoursID]) ON [PRIMARY]
GO
