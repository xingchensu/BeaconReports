CREATE TABLE [dbo].[CRM_BeaconIntranet_SubmitReviewedTerms_Hourly]
(
[appid] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[opportunityid] [uniqueidentifier] NOT NULL,
[consultantid] [uniqueidentifier] NOT NULL,
[consultant] [nvarchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SharedCredit] [uniqueidentifier] NULL,
[SharedCredit2] [uniqueidentifier] NULL,
[SharedCredit3] [uniqueidentifier] NULL,
[SharedCredit4] [uniqueidentifier] NULL,
[SharedCredit5] [uniqueidentifier] NULL,
[FundingMethod] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[termid] [uniqueidentifier] NOT NULL,
[termname] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[new_isinlcw] [bit] NULL,
[lcw_termid] [uniqueidentifier] NOT NULL,
[lcw_termname] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[lcw_fundingmethod] [int] NULL,
[Min. Pts. Profit] [float] NULL,
[Payment Type] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Credit Approval Date] [datetime] NULL,
[Submission Date] [datetime] NULL,
[Submitted by] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[reviewedOn] [datetime] NULL,
[reviewed by] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[creditmanager] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[credit decision] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[comments] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[ID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[CRM_BeaconIntranet_SubmitReviewedTerms_Hourly] ADD CONSTRAINT [PK__CRM_Beac__3214EC270EA330E9] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
