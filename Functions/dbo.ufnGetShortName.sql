SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Beno Philip Mathew
-- Create date: 12/11/2015
-- Description:	To get the first name initial + , + last name
-- =============================================

CREATE FUNCTION [dbo].[ufnGetShortName]
    (
      @FName AS VARCHAR(20) ,
      @LName AS VARCHAR(20) ,
      @MaxLenth AS INT
    )
RETURNS VARCHAR(50)
AS 
    BEGIN
        DECLARE @Result AS VARCHAR(50);

        SET @FName = LTRIM(@FName);
        SET @LName = LTRIM(@LName);

        IF LEN(@LName) < @MaxLenth 
            BEGIN
                SET @Result = SUBSTRING(@FName, 1, 1) + ', '
                    + SUBSTRING(@LName, 1, @MaxLenth);
            END
        ELSE 
            BEGIN
                SET @Result = SUBSTRING(@FName, 1, 1) + ', '
                    + SUBSTRING(@LName, 1, @MaxLenth) + '..';
            END

        RETURN @Result;
    END
GO
