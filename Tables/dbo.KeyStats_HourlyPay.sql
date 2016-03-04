CREATE TABLE [dbo].[KeyStats_HourlyPay]
(
[hourlyPayID] [int] NOT NULL IDENTITY(1, 1),
[userName] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[categoryID] [int] NULL,
[payPerHour] [float] NULL,
[activeStatus] [bit] NULL,
[createdDate] [datetime] NULL,
[activeTillDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_HourlyPay] ADD CONSTRAINT [PK__KeyStats__229F6F2B66E0EF00] PRIMARY KEY CLUSTERED  ([hourlyPayID]) ON [PRIMARY]
GO
