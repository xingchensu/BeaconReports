CREATE TABLE [dbo].[CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[rate] [float] NULL,
[Month] [int] NULL,
[Year] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot] ADD CONSTRAINT [PK_CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
