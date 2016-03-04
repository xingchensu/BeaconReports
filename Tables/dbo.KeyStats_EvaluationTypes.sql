CREATE TABLE [dbo].[KeyStats_EvaluationTypes]
(
[EvaluationTypeID] [tinyint] NOT NULL IDENTITY(1, 1),
[EvaluationTypeName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_EvaluationTypes] ADD CONSTRAINT [pk_EvaluationTypeID] PRIMARY KEY CLUSTERED  ([EvaluationTypeID]) ON [PRIMARY]
GO
