SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/15/2015
-- Description:	To Get Perc Of Ticket Solved
-- =============================================

CREATE FUNCTION [dbo].[ufnGetPercOfTicketSolved]
    (
		@start_date AS DATE ,
		@end_date AS DATE ,
		@UniqueID AS INT = NULL,
		@IsMisc AS BIT = NULL
    )
RETURNS DECIMAL
AS 
    BEGIN
		DECLARE @PercOfTicketSolveCreatedOn AS DECIMAL = 0;
		DECLARE @PercOfTicketSolveClosedOn AS DECIMAL = 0;

		SET @PercOfTicketSolveCreatedOn = (SELECT COUNT(*) FROM [dbo].[KeyStats_WHD_ClosedTickets_Snapshot] s
		WHERE s.[StatusType] <> 'Cancelled Ticket - Self resolved issue'
		AND  CAST(s.[ClosedDate] AS DATE) >= CAST(@start_date AS DATE)
		AND  CAST(s.[ClosedDate] AS DATE) <= CAST(@end_date AS DATE)
		AND s.Tech_UniqueUserId = ISNULL(@UniqueID, s.Tech_UniqueUserId)
		AND s.Tech_IsMisc = ISNULL(@IsMisc, s.Tech_IsMisc));

		SET @PercOfTicketSolveClosedOn = (SELECT COUNT(*) FROM [dbo].[KeyStats_WHD_OpenTickets_Pipeline] s
		WHERE s.[StatusType] <> 'Cancelled Ticket - Self resolved issue'
		AND  CAST(s.[SnapshotDate] AS DATE) = CAST(@start_date AS DATE)
		AND s.Tech_UniqueUserId = ISNULL(@UniqueID, s.Tech_UniqueUserId)
		AND s.Tech_IsMisc = ISNULL(@IsMisc, s.Tech_IsMisc));

		RETURN CAST(CASE WHEN @PercOfTicketSolveCreatedOn > 0 THEN ((@PercOfTicketSolveClosedOn * 100) / @PercOfTicketSolveCreatedOn) ELSE 0 END AS DECIMAL);

    END


	
GO
