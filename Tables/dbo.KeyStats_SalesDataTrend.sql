CREATE TABLE [dbo].[KeyStats_SalesDataTrend]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[metric] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[formatedValue] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[metricType] [int] NULL,
[startDate] [datetime] NULL,
[endDate] [datetime] NULL,
[quarterName] [nvarchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userID] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userRole] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_SalesDataTrend] ADD CONSTRAINT [pk_TrendID] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
