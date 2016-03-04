CREATE TABLE [dbo].[KeyStats_OpenOpportunityPipeline_DailySnapshot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[new_appid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpportunityId] [uniqueidentifier] NOT NULL,
[SnapshotDate] [date] NOT NULL,
[salesstagecode] [tinyint] NULL,
[statuscode] [tinyint] NULL,
[fundingmethodvalue] [tinyint] NULL,
[consultantId] [uniqueidentifier] NULL,
[owneridname] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreditManager] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[CreditManagerID] [uniqueidentifier] NULL,
[LeaseAmount] [money] NULL,
[insideSales] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[insideSalesId] [uniqueidentifier] NULL,
[New_LeaseAdministratorId] [uniqueidentifier] NULL,
[New_LeaseAdministratorIdName] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContractType] [tinyint] NULL,
[isDocusigned] [bit] NULL,
[isTitled] [bit] NULL,
[acceptanceDate] [datetime2] (2) NULL
) ON [PRIMARY]
GO
