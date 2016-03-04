SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[KeyStats_SalesDataTrend_Insert]
    @dataTrend SalesDataTrend readonly
AS
BEGIN
    INSERT INTO [dbo].[KeyStats_SalesDataTrend]
    SELECT * FROM @dataTrend 
END
GO
