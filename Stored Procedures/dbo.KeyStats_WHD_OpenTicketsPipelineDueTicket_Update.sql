SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/16/2015
-- Description:	To update the past due flag using ticket id
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_WHD_OpenTicketsPipelineDueTicket_Update] @ticket_id INT
AS
    BEGIN
        UPDATE  [dbo].[KeyStats_WHD_OpenTickets_Pipeline]
        SET     IsPastDue = 1
        WHERE   TicketID = @ticket_id
		AND CAST(SnapshotDate AS DATE) = CAST(GETDATE() AS DATE);
    END
GO
