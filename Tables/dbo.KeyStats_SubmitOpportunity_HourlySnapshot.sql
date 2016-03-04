CREATE TABLE [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot]
(
[opid] [uniqueidentifier] NOT NULL,
[consultantId] [uniqueidentifier] NULL,
[consultant] [varchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingMethodvalue] [tinyint] NULL,
[CreditManager] [varchar] (160) COLLATE Latin1_General_CI_AS NULL,
[creditmanagerid] [uniqueidentifier] NULL,
[SubmitDate] [datetime2] (2) NULL,
[insideSales] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[insideSalesId] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_SubmitOpportunity_HourlySnapshot] ADD CONSTRAINT [PK_KeyStats_SubmitOpportunity_HourlySnapshot] PRIMARY KEY CLUSTERED  ([opid]) ON [PRIMARY]
GO
