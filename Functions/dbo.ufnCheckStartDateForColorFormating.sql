SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/11/2015
-- Description:	To Check Start Date For Color Formating
-- =============================================

CREATE FUNCTION [dbo].[ufnCheckStartDateForColorFormating]
    (
		@Index AS INT,
      @StrtDate AS VARCHAR(10)
    )
RETURNS INT
AS 
    BEGIN
  DECLARE @StartDate AS DATE = CONVERT(DATE, @StrtDate);
        DECLARE @Result AS INT;

        
        DECLARE @CurentDate AS DATE = GETDATE();
        DECLARE @NoOfMonths AS INT = DATEDIFF(MONTH, @StartDate, @CurentDate);
        IF @NoOfMonths <= 6 
            BEGIN
                SET @Result = 110
            END
        ELSE 
            BEGIN
                SET @Result = @Index  
            END  

        RETURN @Result;
    END


	
GO
