CREATE TABLE [dbo].[CRM_BeaconIntranet_SalesIncentive_Consultant_MonthlySnapShot]
(
[FullName] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Id] [uniqueidentifier] NULL,
[EmailAddress] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Month] [int] NULL,
[Year] [int] NULL,
[OneOffProfitBonus] [float] NULL,
[OneOffProfit] [numeric] (18, 0) NULL,
[OneOffOriginations] [numeric] (18, 0) NULL,
[OneOffPts] [numeric] (18, 2) NULL,
[IRRBonus] [float] NULL,
[IRR] [numeric] (18, 2) NULL,
[PortfolioOriginations] [numeric] (18, 0) NULL,
[TotalOriginations] [numeric] (18, 0) NULL,
[PurchaseOptionBonus] [float] NULL,
[PurchaseOption] [numeric] (18, 0) NULL,
[EquipmentCost] [numeric] (18, 0) NULL,
[PurchaseOptionPts] [numeric] (18, 2) NULL,
[SecurityDepositBonus] [float] NULL,
[SecurityDeposit] [numeric] (18, 0) NULL,
[AbsolutePayment] [numeric] (18, 0) NULL,
[SecurityDepositPts] [numeric] (18, 2) NULL,
[OtherIncomeExpense] [numeric] (18, 0) NULL,
[RecordID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_SalesIncentive_Consultant_MonthlySnapShot] ADD CONSTRAINT [PK__CRM_Beac__FBDF78C93F466844] PRIMARY KEY CLUSTERED  ([RecordID]) ON [PRIMARY]
GO
