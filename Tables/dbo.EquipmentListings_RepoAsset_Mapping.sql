CREATE TABLE [dbo].[EquipmentListings_RepoAsset_Mapping]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[equ_id] [int] NOT NULL,
[repoAsset_id] [uniqueidentifier] NOT NULL,
[DateTimeStamp] [datetime] NULL CONSTRAINT [DF_EquipmentListings_RepoAsset_Mapping_DateTimeStamp] DEFAULT (getdate())
) ON [PRIMARY]
GO
