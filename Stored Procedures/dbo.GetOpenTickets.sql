
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/16/2015
-- Description:	Get all open tickets
-- =============================================
CREATE PROCEDURE [dbo].[GetOpenTickets]
    @ENDDATE AS DATETIME ,
    @UniqueID AS INT = NULL ,
    @IsMisc AS BIT = NULL ,
    @Location AS VARCHAR(50) = NULL ,
    @Status AS VARCHAR(50) = NULL ,
    @RequestType AS VARCHAR(50) = NULL ,
    @ClientName AS VARCHAR(50) = NULL
AS 
    BEGIN
  --xsu1  
        SET NOCOUNT ON;

        SELECT  p.TicketID ,
                p.[Subject] ,
                p.ReportedDate ,
                p.AssignedTech ,
                p.TotalTimeOpen ,
                p.FirstResponseTime ,
                p.ProblemType ,
                p.StatusType ,
				p.ClientName ,
                p.LocationName
        FROM    [dbo].[KeyStats_WHD_OpenTickets_Pipeline] p
        WHERE   CAST(p.SnapshotDate AS DATE) = @ENDDATE
                AND p.Tech_UniqueUserId = ISNULL(@UniqueID,
                                                 p.Tech_UniqueUserId)
                AND p.[Tech_IsMisc] = ISNULL(@IsMisc, p.[Tech_IsMisc])
                AND LOWER(p.LocationName) = ISNULL(@Location,
                                                   LOWER(p.LocationName))
                AND LOWER(p.StatusType) = ISNULL(@Status, LOWER(p.StatusType))
                AND LOWER(p.ProblemType) = ISNULL(@RequestType,
                                                  LOWER(p.ProblemType))
                AND LOWER(p.ClientName) = ISNULL(@ClientName,
                                                 LOWER(p.ClientName))

    END
GO
