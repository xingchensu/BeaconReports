CREATE TABLE [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly]
(
[name] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[opid] [uniqueidentifier] NOT NULL,
[aid] [uniqueidentifier] NULL,
[consultant] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consultantId] [uniqueidentifier] NULL,
[companyName] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acceptanceDate] [datetime] NULL,
[leaseAmt] [money] NULL,
[NetVendorAmount] [money] NULL,
[FundingMethod] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BFCDownPayment] [real] NULL,
[DocFee] [real] NULL,
[securityDeposit] [real] NULL,
[purchaseOption] [real] NULL,
[AdvancedPayment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment] [real] NULL,
[GrossDueToVendorExcluded] [real] NULL,
[EquipmentCost] [real] NULL,
[totalReferralFee] [real] NULL,
[CreditManager] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oneoffProfit] [real] NULL,
[IRR] [real] NULL,
[image] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[beacon_score] [int] NULL,
[fico_score] [int] NULL,
[tib] [int] NULL,
[paydex] [int] NULL,
[repeatclient] [int] NULL,
[programname] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SDEligibility] [bit] NULL,
[POEligibility] [bit] NULL,
[OtherIncomeExpense] [real] NULL,
[SharedCredit] [uniqueidentifier] NULL,
[SharedCredit2] [uniqueidentifier] NULL,
[SharedCredit3] [uniqueidentifier] NULL,
[SharedCredit4] [uniqueidentifier] NULL,
[SharedCredit5] [uniqueidentifier] NULL,
[CFSLeaseNumber] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[createdon] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_SalesDetails_Hourly] ADD CONSTRAINT [pk_CRM_BeaconIntranet_SalesDetails_Hourly_OppID] PRIMARY KEY CLUSTERED  ([opid]) ON [PRIMARY]
GO
