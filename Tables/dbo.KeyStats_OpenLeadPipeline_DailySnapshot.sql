CREATE TABLE [dbo].[KeyStats_OpenLeadPipeline_DailySnapshot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[leadid] [uniqueidentifier] NOT NULL,
[SnapshotDate] [date] NULL,
[EquipmentCost] [money] NULL,
[consultantid] [uniqueidentifier] NOT NULL,
[insideSales] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[insideSalesId] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_OpenLeadPipeline_DailySnapshot] ADD CONSTRAINT [PK_KeyStats_OpenLeadPipeline_DailySnapshot] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
