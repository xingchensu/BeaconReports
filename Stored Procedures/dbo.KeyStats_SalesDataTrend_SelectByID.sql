SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--[dbo].[KeyStats_SalesDataTrend_SelectByID] @metric='EquipmentCostVal',@ID='ce64168c-b204-e011-b009-78e7d1f817f8'
CREATE PROCEDURE [dbo].[KeyStats_SalesDataTrend_SelectByID]
    @ID nvarchar(100)=NULL,
    @metric nvarchar(100)
AS
	DECLARE @endDateStartRange AS DATETIME
	DECLARE @endDateEndRange AS DATETIME
BEGIN
	SET @endDateEndRange = DateAdd(Day, -1, DateAdd(quarter,  DatePart(Quarter, getdate())-1, '1/1/' + Convert(char(4), DatePart(Year, getdate()))))
	SET @endDateStartRange = DATEADD(month, -24, @endDateEndRange)
	
	SELECT * FROM [dbo].[KeyStats_SalesDataTrend]
	WHERE metric = @metric AND userName = 'Beacon Funding Corporation Average'
	AND endDate >= @endDateStartRange AND endDate <= @endDateEndRange
	UNION
	SELECT * FROM [dbo].[KeyStats_SalesDataTrend]
	WHERE metric = @metric AND userID = @ID
	AND endDate >= @endDateStartRange AND endDate <= @endDateEndRange
	ORDER BY userID, endDate
END
GO
