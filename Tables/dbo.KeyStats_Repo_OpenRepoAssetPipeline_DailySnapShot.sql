CREATE TABLE [dbo].[KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[new_repoid] [uniqueidentifier] NOT NULL,
[new_repoassetid] [uniqueidentifier] NOT NULL,
[EUAdminStatus] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ListEstimatedValue] [money] NULL,
[BVCost] [money] NULL,
[ListEstimatedTotalValue] [money] NOT NULL,
[EstNetGainLoss] [decimal] (8, 2) NULL,
[RepoTypeValue] [int] NULL,
[State] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EquipmentCategory] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CollectorGUID] [uniqueidentifier] NULL,
[Collector] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreditManagerGUID] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreditManager] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesPersonGUID] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesPerson] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_Repo_OpenRepoAssetPipeline_DailySnapShot] ADD CONSTRAINT [PK_KeyStats_Repo_SnapShot_OpenRepoAssetPipeline] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
