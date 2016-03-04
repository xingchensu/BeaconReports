CREATE TABLE [dbo].[KeyStats_Categories]
(
[CategoryID] [tinyint] NOT NULL IDENTITY(1, 1),
[CategoryName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompanyName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_Categories] ADD CONSTRAINT [pk_CategoryID] PRIMARY KEY CLUSTERED  ([CategoryID]) ON [PRIMARY]
GO
