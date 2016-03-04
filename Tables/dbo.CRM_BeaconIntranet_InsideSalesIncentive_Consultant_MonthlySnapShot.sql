CREATE TABLE [dbo].[CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot]
(
[agentcode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRMGuid] [uniqueidentifier] NULL,
[Connects] [int] NULL,
[Leads] [int] NULL,
[Oppty] [int] NULL,
[Username] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConnectsBonus] [int] NULL,
[OpptyBonus] [int] NULL,
[ConnectsLeadsBonus] [int] NULL,
[ConnectsOpptyBonus] [int] NULL,
[TotalBonus] [int] NULL,
[Month] [int] NULL,
[Year] [int] NULL,
[SnapShotDateTime] [datetime2] NULL,
[RecordID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_InsideSalesIncentive_Consultant_MonthlySnapShot] ADD CONSTRAINT [PK__CRM_Beac__FBDF78C94316F928] PRIMARY KEY CLUSTERED  ([RecordID]) ON [PRIMARY]
GO
