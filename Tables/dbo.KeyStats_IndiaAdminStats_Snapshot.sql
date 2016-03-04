CREATE TABLE [dbo].[KeyStats_IndiaAdminStats_Snapshot]
(
[ActivityDate] [date] NULL,
[CP_Designs] [decimal] (10, 2) NULL,
[CP_ReportedDesigns] [decimal] (10, 2) NULL,
[CP_TotalHrs] [decimal] (10, 2) NULL,
[CP_ActiveHrs] [decimal] (10, 2) NULL,
[CP_RepotedHrs] [decimal] (10, 2) NULL,
[ZZ_Designs] [decimal] (10, 2) NULL,
[ZZ_ReportedDesigns] [decimal] (10, 2) NULL,
[ZZ_TotalHrs] [decimal] (10, 2) NULL,
[ZZ_ActiveHrs] [decimal] (10, 2) NULL,
[ZZ_RepotedHrs] [decimal] (10, 2) NULL,
[SS_Designs] [decimal] (10, 2) NULL,
[SS_ReportedDesigns] [decimal] (10, 2) NULL,
[SS_TotalHrs] [decimal] (10, 2) NULL,
[SS_ActiveHrs] [decimal] (10, 2) NULL,
[SS_RepotedHrs] [decimal] (10, 2) NULL,
[DT_Designs] [decimal] (10, 2) NULL,
[DT_ReportedDesigns] [decimal] (10, 2) NULL,
[DT_TotalHrs] [decimal] (10, 2) NULL,
[DT_ActiveHrs] [decimal] (10, 2) NULL,
[DT_RepotedHrs] [decimal] (10, 2) NULL,
[RF_Designs] [decimal] (10, 2) NULL,
[RF_ReportedDesigns] [decimal] (10, 2) NULL,
[RF_TotalHrs] [decimal] (10, 2) NULL,
[RF_ActiveHrs] [decimal] (10, 2) NULL,
[RF_RepotedHrs] [decimal] (10, 2) NULL,
[IsDeleted] [bit] NULL CONSTRAINT [DF__KeyStats___IsDel__56757D0D] DEFAULT ((0)),
[SnapShotDate] [datetime] NULL CONSTRAINT [DF_KeyStats_IndiaAdminStats_Snapshot_SnapShotDate] DEFAULT (getdate()),
[UserID] [int] NULL,
[FName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UniqueUserId] [int] NULL,
[shift] [int] NULL,
[StartDate] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fullname] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fullname2] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsMiscellaneous] [bit] NULL,
[HourlyPayUSD] [money] NULL,
[CP_Cost] [decimal] (10, 2) NULL,
[ZZ_Cost] [decimal] (10, 2) NULL,
[SS_Cost] [decimal] (10, 2) NULL,
[DT_Cost] [decimal] (10, 2) NULL,
[RF_Cost] [decimal] (10, 2) NULL,
[CP_CostPerDesign] [decimal] (10, 2) NULL,
[ZZ_CostPerDesign] [decimal] (10, 2) NULL,
[SS_CostPerDesign] [decimal] (10, 2) NULL,
[DT_CostPerDesign] [decimal] (10, 2) NULL,
[RF_CostPerDesign] [decimal] (10, 2) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO