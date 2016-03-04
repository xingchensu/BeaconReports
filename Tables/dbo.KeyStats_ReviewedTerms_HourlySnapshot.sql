CREATE TABLE [dbo].[KeyStats_ReviewedTerms_HourlySnapshot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[appid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[opportunityid] [uniqueidentifier] NOT NULL,
[consultantid] [uniqueidentifier] NULL,
[consultant] [varchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingMethodvalue] [tinyint] NULL,
[termid] [uniqueidentifier] NOT NULL,
[termname] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[new_isinlcw] [bit] NULL,
[lcw_termid] [uniqueidentifier] NULL,
[lcw_termname] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[lcw_fundingmethod] [tinyint] NULL,
[Min. Pts. Profit] [float] NULL,
[Payment Type] [varchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Credit Approval Date] [datetime2] (2) NULL,
[Submission Date] [datetime2] (2) NULL,
[Submitted by] [varchar] (160) COLLATE Latin1_General_CI_AS NULL,
[reviewedOn] [datetime2] (2) NULL,
[reviewed by] [varchar] (160) COLLATE Latin1_General_CI_AS NULL,
[creditmanager] [varchar] (160) COLLATE Latin1_General_CI_AS NULL,
[CreditManagerid] [uniqueidentifier] NULL,
[credit decision] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[comments] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[insideSales] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[insideSalesId] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_ReviewedTerms_HourlySnapshot] ADD CONSTRAINT [PK_KeyStats_ReviewedTerms_HourlySnapshot] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
