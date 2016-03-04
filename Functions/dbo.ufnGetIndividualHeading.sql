SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/11/2015
-- Description:	To get individual heading
-- =============================================

CREATE FUNCTION [dbo].[ufnGetIndividualHeading]
    (
	  @StrtDate AS VARCHAR(10) ,
      @LName AS VARCHAR(20) ,
      @MaxLenth AS INT,
	  @LegendIndex AS INT
    )
RETURNS VARCHAR(50)
AS 
    BEGIN
		DECLARE @StartDate AS DATE = CONVERT(DATE, @StrtDate);

        DECLARE @Result AS VARCHAR(50);

        SET @LName = LTRIM(@LName);

        IF LEN(@LName) < @MaxLenth 
            BEGIN
                SET @Result = @LName;
            END
        ELSE 
            BEGIN
                SET @Result = SUBSTRING(@LName, 1, @MaxLenth) + '..';
            END
			
			DECLARE @CurentDate AS DATE = GETDATE();
        DECLARE @NoOfMonths AS INT = DATEDIFF(MONTH, @StartDate, @CurentDate);
        IF @NoOfMonths <= 6 
            BEGIN
                SET @Result = @Result + '<sup>' + CONVERT(VARCHAR(3), @LegendIndex) + '</sup>'
            END
        ELSE 
            BEGIN
                SET @Result =  @Result +  '<sup></sup>'  
            END  

        RETURN @Result;
    END


	
GO
