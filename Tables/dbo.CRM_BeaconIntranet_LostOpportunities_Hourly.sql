CREATE TABLE [dbo].[CRM_BeaconIntranet_LostOpportunities_Hourly]
(
[opid] [uniqueidentifier] NOT NULL,
[consultantId] [uniqueidentifier] NULL,
[consultant] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingMethod] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreditManager] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApprovalDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_LostOpportunities_Hourly] ADD CONSTRAINT [pk_CRM_BeaconIntranet_LostOpportunities_Hourly_OppID] PRIMARY KEY CLUSTERED  ([opid]) ON [PRIMARY]
GO
