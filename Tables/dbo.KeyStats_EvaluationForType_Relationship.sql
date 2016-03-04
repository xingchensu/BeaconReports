CREATE TABLE [dbo].[KeyStats_EvaluationForType_Relationship]
(
[EvaluationForTypeID] [int] NOT NULL IDENTITY(1, 1),
[EvaluationTypeID] [tinyint] NULL,
[KeyStatsCategoryID] [int] NULL,
[Vendor_Lessee_Evaluation_EvaluatedForType] [int] NULL,
[InternalEvaluationForType] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_EvaluationForType_Relationship] ADD CONSTRAINT [pk_EvaluationForTypeID] PRIMARY KEY CLUSTERED  ([EvaluationForTypeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_EvaluationForType_Relationship] ADD CONSTRAINT [fk_EvaluationTypeID] FOREIGN KEY ([EvaluationTypeID]) REFERENCES [dbo].[KeyStats_EvaluationTypes] ([EvaluationTypeID])
GO
ALTER TABLE [dbo].[KeyStats_EvaluationForType_Relationship] ADD CONSTRAINT [fk_InternalEvaluationForType] FOREIGN KEY ([InternalEvaluationForType]) REFERENCES [dbo].[KeyStats_InternalEvaluationForTypes] ([InternalEvaluationForTypeID])
GO
ALTER TABLE [dbo].[KeyStats_EvaluationForType_Relationship] ADD CONSTRAINT [FK_KeyStats_EvaluationType] FOREIGN KEY ([EvaluationTypeID]) REFERENCES [dbo].[KeyStats_EvaluationTypes] ([EvaluationTypeID])
GO
ALTER TABLE [dbo].[KeyStats_EvaluationForType_Relationship] ADD CONSTRAINT [FK_KeyStats_InternalEvaluationForTypeID] FOREIGN KEY ([InternalEvaluationForType]) REFERENCES [dbo].[KeyStats_InternalEvaluationForTypes] ([InternalEvaluationForTypeID])
GO
