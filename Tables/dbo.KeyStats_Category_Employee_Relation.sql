CREATE TABLE [dbo].[KeyStats_Category_Employee_Relation]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[CompanyID] [tinyint] NOT NULL,
[CompanyName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmployeeID] [int] NULL,
[FName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CategoryID] [tinyint] NOT NULL,
[IsMiscellaneous] [bit] NULL,
[UniqueUserId] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_Category_Employee_Relation] ADD CONSTRAINT [pk_ID] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_Category_Employee_Relation] ADD CONSTRAINT [fk_Employee_CategoryID] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[KeyStats_Categories] ([CategoryID])
GO
ALTER TABLE [dbo].[KeyStats_Category_Employee_Relation] ADD CONSTRAINT [fk_Employee_CompanyID] FOREIGN KEY ([CompanyID]) REFERENCES [dbo].[KeyStats_EmployeeCompany] ([CompanyID])
GO
