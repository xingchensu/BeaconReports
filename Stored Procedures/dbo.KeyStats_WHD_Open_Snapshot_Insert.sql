SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==================================================================
-- Author		: Beno Philip Mathew
-- Create date	: 12/15/2015
-- Description	: To Get the snapshot of WHD open stats
-- ==================================================================

CREATE PROCEDURE [dbo].[KeyStats_WHD_Open_Snapshot_Insert]
AS
BEGIN
	DECLARE @SnapshotFromDate AS DATE = GETDATE();

	-- WHD TECH DATA : START ===============
        IF OBJECT_ID('tempdb..#WHDTech') IS NOT NULL 
            BEGIN
                DROP TABLE #WHDTech;
            END;
        SELECT  e.* ,
                e.[FName] + ' ' + e.[LName] AS fullname ,
                r.IsMiscellaneous
        INTO    #WHDTech
        FROM    LINK_SQLPROD02.[Intranet_Beaconfunding].[dbo].[KeyStats_AllEmployees] e
                INNER JOIN LINK_SQLPROD02.[Intranet_Beaconfunding].[dbo].[KeyStats_Category_Employee_Relation] r ON r.CompanyID = e.Company
                                                              AND r.EmployeeID = e.UserID
                INNER JOIN LINK_SQLPROD02.[Intranet_Beaconfunding].[dbo].[KeyStats_Categories] c ON c.CategoryID = r.CategoryID
        WHERE   c.CategoryID = 9; 
	-- WHD TECH  DATA : END ===============
	
	-- WHD Ticket Details : START ===================
        IF OBJECT_ID('tempdb..#WHDTickets') IS NOT NULL 
            BEGIN
                DROP TABLE #WHDTickets;
            END;

        SELECT  vw.[JOB_TICKET_ID] AS 'TicketID',
				-- Tech Details---
                wt.CRMGuid AS 'Tech_Guid' ,
                wt.UserID AS 'Tech_UID' ,
                wt.username AS 'Tech_UName' ,
                wt.fullname AS 'Tech_FullName' ,
                wt.FName AS 'Tech_FName' ,
                wt.LName AS 'Tech_LName' ,
                wt.StartDate AS 'Tech_StartDate' ,
                wt.IsMiscellaneous AS 'Tech_IsMisc' ,
                wt.[UniqueUserId] AS 'Tech_UniqueUserId',
	
				-- Ticket Details---
                CAST(vw.UnassignedTime AS DECIMAL) AS 'UnassignedTime' ,
                CAST(( vw.FirstResponseTimeByLocation - vw.UnassignedTime ) AS DECIMAL) AS 'FirstResponseTime' ,
                CAST(vw.[TimeOpenByLocation] AS DECIMAL) AS 'TotalTimeOpen' ,
                CAST(vw.[Number_of_hours_worked] AS FLOAT) AS 'TotalTimeWorked' ,
                CAST(vw.[# of  Email Recipients] AS DECIMAL) AS 'PeopleCcPerTicket' ,
                CAST(vw.[# of Reassigns] AS INT) AS 'ReassignmentsCount' ,
                CAST(vw.[Past Due Alerts] AS INT) AS 'PastDueAlerts' ,
                CAST(vw.[# of Tech Notes] AS INT) AS 'TotalNoofTechNotes' ,
                CAST(vw.[Rating] AS DECIMAL) AS 'Evaluation',

				-- Extra Details
                CASE WHEN vw.[Assigned Tech Name] IS NOT NULL
                     THEN vw.[Assigned Tech Name]
                     ELSE 'Unassigned'
                END AS 'AssignedTech' ,
                vw.[STATUS_TYPE_NAME] AS 'StatusType' ,
                vw.CLOSE_DATE AS 'ClosedDate' ,
                vw.[Client Name] AS 'ClientName' ,
                vw.[PROBLEM_TYPE_NAME] AS 'ProblemType' ,
                vw.[SUBJECT] AS 'Subject' ,
                vw.LOCATION_NAME AS 'LocationName' ,
                vw.REPORT_DATE AS 'ReportedDate' ,
				vw.ReopenCounter
        INTO    #WHDTickets
        FROM    [LINK_WHD].[whd].dbo.vw_WHDTickets vw -- Splitting is important because few tech name are diff in both tables
				LEFT JOIN [LINK_WHD].[whd].[dbo].[TECH] t ON t.EMAIL = vw.TechEmail
				LEFT JOIN #WHDTech wt ON wt.[username] = t.[USER_NAME]
		WHERE	vw.[STATUS_TYPE_NAME] IN ('In Progress', 'Opened')
	-- WHD Ticket Details : END =====================

	-- Delete existing tickets in the same time span before inserting it
	DELETE FROM [dbo].[KeyStats_WHD_OpenTickets_Pipeline]
	WHERE CAST([SnapshotDate] AS DATE) = @SnapshotFromDate;
		
	INSERT  INTO [dbo].[KeyStats_WHD_OpenTickets_Pipeline]
                ( TicketID ,
                  Tech_Guid ,
                  Tech_UID ,
                  Tech_UName ,
                  Tech_FullName ,
                  Tech_FName ,
                  Tech_LName ,
                  Tech_StartDate ,
                  Tech_IsMisc ,
                  Tech_UniqueUserId ,
                  UnassignedTime ,
                  FirstResponseTime ,
                  TotalTimeOpen ,
                  TotalTimeWorked ,
                  PeopleCcPerTicket ,
                  ReassignmentsCount ,
                  PastDueAlerts ,
                  TotalNoofTechNotes ,
                  Evaluation ,
                  AssignedTech ,
                  StatusType ,
                  ClosedDate ,
                  ClientName ,
                  ProblemType ,
                  [Subject] ,
                  LocationName ,
                  ReportedDate ,
				  ReopenCounter ,
				  SnapshotDate,
				  IsPastDue
                )
                SELECT  TicketID ,
                        Tech_Guid ,
                        Tech_UID ,
                        Tech_UName ,
                        Tech_FullName ,
                        Tech_FName ,
                        Tech_LName ,
                        Tech_StartDate ,
                        Tech_IsMisc ,
                        Tech_UniqueUserId ,
                        UnassignedTime ,
                        FirstResponseTime ,
                        TotalTimeOpen ,
                        TotalTimeWorked ,
                        PeopleCcPerTicket ,
                        ReassignmentsCount ,
                        PastDueAlerts ,
                        TotalNoofTechNotes ,
                        Evaluation ,
                        AssignedTech ,
                        StatusType ,
                        ClosedDate ,
                        ClientName ,
                        ProblemType ,
                        [Subject] ,
                        LocationName ,
                        ReportedDate ,
						ReopenCounter ,
						GETDATE(),
						0
                FROM    #WHDTickets;

	DECLARE @UpdatedRecords AS INT;
	SELECT @UpdatedRecords = COUNT(*) FROM #WHDTickets;

	SELECT 'No of tickets inserted - ' + CONVERT(Varchar(100), @UpdatedRecords) AS [Result];
END
GO
