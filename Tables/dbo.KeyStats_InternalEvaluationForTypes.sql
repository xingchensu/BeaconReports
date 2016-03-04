CREATE TABLE [dbo].[KeyStats_InternalEvaluationForTypes]
(
[InternalEvaluationForTypeID] [tinyint] NOT NULL IDENTITY(1, 1),
[InternalEvaluationForTypeName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_InternalEvaluationForTypes] ADD CONSTRAINT [pk_InternalEvaluationForTypeID] PRIMARY KEY CLUSTERED  ([InternalEvaluationForTypeID]) ON [PRIMARY]
GO
