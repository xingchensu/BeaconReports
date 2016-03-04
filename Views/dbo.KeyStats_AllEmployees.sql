SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[KeyStats_AllEmployees]
AS
SELECT     'Beacon' AS IntranetTable, [UserID], ec.CompanyID AS Company, e.[CompanyName], [FName], [LName], [Status], e.[Title], [StartDate], [EndDate], [username], [DOB], 
                      [Roles], NULL AS shift, su.SystemUserId AS CRMGuid, CAST(CAST(ec.CompanyID AS nvarchar(2)) + CAST(e.UserID AS nvarchar(10)) AS INT) AS UniqueUserId
FROM         [Intranet_Beaconfunding].[dbo].[tblUsers] e LEFT JOIN
                      CRMReplication2013.dbo.systemuser su ON e.username = REPLACE(su.DomainName, 'ECS\', '') INNER JOIN
                      dbo.KeyStats_EmployeeCompany ec ON e.CompanyName = ec.CompanyName
WHERE     /*[Status] = 1 AND */ (ec.CompanyID = 4 OR
                      ec.CompanyID = 5 OR
                      ec.CompanyID = 6) AND NOT (username = '' OR
                      username IS NULL) AND [UserID] NOT IN (111403, 111412)
UNION
SELECT     'ECS' AS IntranetTable, [employee_#], [Company], ec.CompanyName AS CompanyName, [FN], [LN], [Status], e.[Title], [Start_Date], [End_Date], [Username], [DOB], 
                      [Roles], [Shift], NULL AS CRMGuid, CAST(CAST(ec.CompanyID AS nvarchar(2)) + CAST(e.[employee_#] AS nvarchar(10)) AS INT) AS UniqueUserId
FROM         [ECS_Intranet].[dbo].[ecs_user] e INNER JOIN
                      dbo.KeyStats_EmployeeCompany ec ON e.Company = ec.CompanyID
WHERE     NOT (username = '' OR
                      username IS NULL) AND [Company] IS NOT NULL AND [employee_#] <> 999 /*Jon B*/ AND ([employee_#] <> 1168) /*Mike Szasz*/ AND 
                      [employee_#] <> 101 /*Sam Oliva*/ AND [employee_#] <> 1431
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -96
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 17
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'KeyStats_AllEmployees', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'KeyStats_AllEmployees', NULL, NULL
GO
