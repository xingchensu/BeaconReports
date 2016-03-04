CREATE TABLE [dbo].[SalesRanking_OutSideSalesDailyPipeLine]
(
[ReportID] [int] NOT NULL IDENTITY(1, 1),
[ReportDate] [date] NULL,
[DateTimeStamp] [datetime] NULL,
[SalesConsultantId] [uniqueidentifier] NULL,
[Leads] [int] NULL,
[LeadsAmount] [money] NULL,
[Opportunities] [int] NULL,
[OpportunitiesAmount] [money] NULL,
[Opportunities2] [int] NULL,
[OpportunitiesAmount2] [money] NULL,
[Opportunities3] [int] NULL,
[OpportunitiesAmount3] [money] NULL,
[Opportunities4] [int] NULL,
[OpportunitiesAmount4] [money] NULL,
[Opportunities5] [int] NULL,
[OpportunitiesAmount5] [money] NULL,
[Opportunities6] [int] NULL,
[OpportunitiesAmount6] [money] NULL,
[Opportunities7] [int] NULL,
[OpportunitiesAmount7] [money] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SalesRanking_OutSideSalesDailyPipeLine] ADD CONSTRAINT [pk_ReportID] PRIMARY KEY CLUSTERED  ([ReportID]) ON [PRIMARY]
GO
