CREATE TABLE [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[EvaluationType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EvaluatedByType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EvaluatedByID] [uniqueidentifier] NULL,
[EvaluatedByName] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EvaluateForType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EvaluateForID] [uniqueidentifier] NULL,
[EvaluateForName] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Rating] [tinyint] NULL,
[Comments] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpportunityID] [uniqueidentifier] NULL,
[Opportunity] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActualCloseDate] [datetime] NULL,
[IsConfidential] [tinyint] NULL,
[SnapShotDateTime] [date] NULL CONSTRAINT [DF_KeyStats_EmployeeEvaluation_DailySnapShot_SnapShotDateTime] DEFAULT (getdate()),
[EvaluateForTypeValue] [int] NULL,
[EvaluationTypeValue] [tinyint] NULL,
[EvaluateForUsername] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_EmployeeEvaluation_DailySnapShot] ADD CONSTRAINT [PK_KeyStats_EmployeeEvaluation_DailySnapShot] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
