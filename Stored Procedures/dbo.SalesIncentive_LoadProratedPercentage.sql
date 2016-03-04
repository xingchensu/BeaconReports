SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
 --Created by Ruonan Wen 05/31/12 to load all the users have consultant user role
*/

CREATE PROCEDURE [dbo].[SalesIncentive_LoadProratedPercentage]-- 2013,3
@year as int,
@month as int
AS
begin
	
		if @year =year(getdate()) and @month=month(getdate()) 
		begin
			declare @ytd as money
			declare @ytdly as money
			SELECT @ytd=sum(leaseAmt) 
			FROM CRM_BeaconIntranet_SalesDetails_Hourly
			WHERE acceptanceDate<  getdate()
			AND acceptanceDate>= cast ('01/01/'+cast(year(getdate()) as varchar)+' 0:0:0' as datetime )

			SELECT @ytdly=sum(leaseAmt) 
			FROM CRM_BeaconIntranet_SalesDetails_Hourly
			WHERE acceptanceDate< dateadd(year,-1, getdate())
			AND acceptanceDate>= dateadd(year,-1, cast ('01/01/'+cast(year(getdate()) as varchar)+' 0:0:0' as datetime ))
			if @ytd<@ytdly
			begin
				select  @ytd/@ytdly as rate
			end
			else 
				select 1 as rate
		end
		else
		begin
			if (exists (select * from [CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot] where [month]=@month and [year]=@year))
			begin 
				select rate from 
				[CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot] 
				where [month]=@month and [year]=@year
			end	
			else 
				select 1	as rate
		end	
end


		
GO
