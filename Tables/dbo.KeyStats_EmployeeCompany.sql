CREATE TABLE [dbo].[KeyStats_EmployeeCompany]
(
[CompanyID] [tinyint] NOT NULL IDENTITY(1, 1),
[CompanyName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DisplayName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompanyStatus] [bit] NOT NULL CONSTRAINT [DF_KeyStats_EmployeeCompany_CompanyStatus] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_EmployeeCompany] ADD CONSTRAINT [pk_CompanyID] PRIMARY KEY CLUSTERED  ([CompanyID]) ON [PRIMARY]
GO
