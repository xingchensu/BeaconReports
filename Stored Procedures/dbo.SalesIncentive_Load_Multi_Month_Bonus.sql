SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ruonan Wen
-- Create date: 3/25/2013
-- Description:	Load multi-month sales incentive
-- =============================================
CREATE PROCEDURE [dbo].[SalesIncentive_Load_Multi_Month_Bonus]--'9/1/2015','11/1/2015'
@StartDate as date, @EndDate as date
AS
BEGIN	
	SET NOCOUNT ON;
	declare @dateFrom as datetime=@StartDate
	declare @dateEnd as datetime=@EndDate
	
		declare @dateTo as datetime		
		declare @minoneoff as decimal=0
		IF OBJECT_ID('TEMPDB..#tempsalesincentive') IS NOT NULL
		BEGIN
		DROP TABLE #tempsalesincentive
		END

		CREATE TABLE #tempsalesincentive
		( 
			consultant nvarchar(160),
			consultantId uniqueidentifier,
			OneOffBonus float,
			IRRBonus float,
			PurchaseOptionBonus float,
			SecurityDepositBonus float
		)


		while @dateFrom<@dateEnd
		begin 
			
			set @dateTo=dateadd(month,1,@dateFrom)
			
			if @dateFrom>='3/1/2013 0:0:0'
			set @minoneoff=7
			declare @prorate as float=1
			if exists(select rate from  CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot where [month]=month(@dateFrom) and [year]=year(@dateFrom)and rate>0)
			select @prorate=rate 
				from  CRM_BeaconIntranet_SalesIncentive_ProratedPercentage_MonthlySnapShot where [month]=month(@dateFrom) and [year]=year(@dateFrom) and rate>0
			if exists(select * FROM CRM_BeaconIntranet_SalesDetails_Hourly_MonthlySnapShot
						WHERE [month]=month(@dateFrom) and [year]=year(@dateFrom))
			begin
			
				
				
				insert into #tempsalesincentive
				select 
				[FullName]
      ,[Id]
     
      ,[OneOffProfitBonus]
     
      ,[IRRBonus]
    
      ,[PurchaseOptionBonus]
    
      ,[SecurityDepositBonus]
      from  [dbo].[CRM_BeaconIntranet_SalesIncentive_Consultant_MonthlySnapShot]
    	WHERE [month]=month(@dateFrom) and [year]=year(@dateFrom)
			
			end
			else
			begin
				insert into #tempsalesincentive
				select consultants.*,-- month(@dateFrom) as [month],year(@dateFrom) as [year],
			 
				 --one-off
				case 
				when currentmonth_oneoff.AdjustOneoff_pts >0 and currentmonth_oneoff.AdjustOneoff_pts >=@minoneoff and row_number() OVER (ORDER BY currentmonth_oneoff.AdjustOneoff_pts desc,currentmonth_oneoff.oneoffProfit DESC) = 1 then 450*@prorate
				when currentmonth_oneoff.AdjustOneoff_pts >0 and currentmonth_oneoff.AdjustOneoff_pts >=@minoneoff and row_number() OVER (ORDER BY currentmonth_oneoff.AdjustOneoff_pts desc,currentmonth_oneoff.oneoffProfit DESC) = 2 then 250*@prorate
				when currentmonth_oneoff.AdjustOneoff_pts >0 and currentmonth_oneoff.AdjustOneoff_pts >=@minoneoff and row_number() OVER (ORDER BY currentmonth_oneoff.AdjustOneoff_pts desc,currentmonth_oneoff.oneoffProfit DESC) = 3 then 100*@prorate
				else 0
				end as OneoffProfitBonus,
				--isnull(currentmonth_oneoff.oneoffProfit ,0) as OneoffProfit,
				--isnull(currentmonth_oneoff.oneoff_originations,0) as oneofforiginations,
				--isnull(currentmonth_oneoff.oneoff_pts ,0) as oneoffpts,
				
				--IRR
				case 
				when  currentmonth_irr.AdjustAvgIRR >0 and row_number() OVER (ORDER BY currentmonth_irr.AdjustAvgIRR desc,currentmonth_irr.portfolio_originations DESC) = 1 then 450*@prorate
				when  currentmonth_irr.AdjustAvgIRR >0 and row_number() OVER (ORDER BY currentmonth_irr.AdjustAvgIRR desc,currentmonth_irr.portfolio_originations DESC) = 2 then 250*@prorate
				when  currentmonth_irr.AdjustAvgIRR >0 and row_number() OVER (ORDER BY currentmonth_irr.AdjustAvgIRR desc,currentmonth_irr.portfolio_originations DESC) = 3 then 100*@prorate
				else 0
				end as IRRBonus,
				--isnull(currentmonth_irr.AvgIRR,0) as IRR ,
				--isnull(currentmonth_irr.portfolio_originations,0) as portfoliooriginations,
				--isnull(currentmonth_irr.total_originations,0) as totaloriginations,
				
				--po
				case 
				when  currentmonth_po.AdjustpurchaseOptionPercentage >0 and row_number() OVER (ORDER BY currentmonth_po.AdjustpurchaseOptionPercentage desc,currentmonth_po.purchaseOption DESC) = 1 then 450*@prorate
				when  currentmonth_po.AdjustpurchaseOptionPercentage >0 and row_number() OVER (ORDER BY currentmonth_po.AdjustpurchaseOptionPercentage desc,currentmonth_po.purchaseOption DESC) = 2 then 250*@prorate
				when  currentmonth_po.AdjustpurchaseOptionPercentage >0 and row_number() OVER (ORDER BY currentmonth_po.AdjustpurchaseOptionPercentage desc,currentmonth_po.purchaseOption DESC) = 3 then 100*@prorate
				else 0
				end as PurchaseOptionBonus,
				--isnull(currentmonth_po.purchaseOption,0) as PurchaseOption ,isnull(currentmonth_po.EquipmentCost,0) as EquipmentCost,
				--isnull(currentmonth_po.purchaseOptionPercentage,0) as PurchaseOptionPts,
					
				--sd
				case 
				when  currentmonth_sd.AdjustsecurityDepositPercentage >0 and row_number() OVER (ORDER BY currentmonth_sd.AdjustsecurityDepositPercentage desc,currentmonth_sd.securityDeposit DESC) = 1 then 450*@prorate
				when  currentmonth_sd.AdjustsecurityDepositPercentage >0 and row_number() OVER (ORDER BY currentmonth_sd.AdjustsecurityDepositPercentage desc,currentmonth_sd.securityDeposit DESC) = 2 then 250*@prorate
				when  currentmonth_sd.AdjustsecurityDepositPercentage >0 and row_number() OVER (ORDER BY currentmonth_sd.AdjustsecurityDepositPercentage desc,currentmonth_sd.securityDeposit DESC) = 3 then 100*@prorate
				else 0
				end as SecurityDepositBonus
				--,
				--isnull(currentmonth_sd.securityDeposit,0) as SecurityDeposit ,
				--isnull(currentmonth_sd.AbsolutePayment,0) as AbsolutePayment,
				--isnull(currentmonth_sd.securityDepositPercentage,0) as SecurityDepositPts
				
				--consultants
				from 
				(
					select fullname , su.SystemUserId as id --, InternalEmailAddress as emailaddress	
					from systemuser su
					INNER JOIN
					dbo.SystemUserRoles sur
					on su.SystemUserId = sur.SystemUserId
					WHERE IsDisabled = 0 and sur.roleid='925BDCD4-9621-4BCC-B3A0-52D932529A8E' and fullname not in
					(
						Select systemusername from dbo.XCelsius_Excluded_Users_When_Calculating_Avg
					)  
				)consultants	
				
				left join --one-off
				(
					select a_current_oneoff.*,
					case when a_current_oneoff.oneoffProfit>=3000 then round(a_current_oneoff.oneoff_pts,2)
					else 0
					end as AdjustOneoff_pts
					from 
					(
						Select consultant, consultantid, 
						round(sum(leaseamt),0) as oneoff_originations,
						round(sum( oneoffProfit),0) AS oneoffProfit,
						round(cast(sum( oneoffProfit) as float) /cast(sum(leaseamt) as float)*100,2)  as oneoff_pts
						FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						and fundingmethod<>'portfolio'
						group by  consultantid,consultant
					)a_current_oneoff
				)currentmonth_oneoff	
				on currentmonth_oneoff.consultantId=consultants.id
				
				left join --IRR
				(
					select a_current_IRR.*,b_current_IRR.Total_originations,
					case when b_current_IRR.Total_Portfolio_originations>=125000 then round(a_current_IRR.AvgIRR,2)
					else 0
					end as AdjustAvgIRR
					from 
					(
						Select consultant,consultantid, 
						round(sum(leaseamt),0) as portfolio_originations,
						round(sum(irr * leaseamt)/sum(leaseamt),2) AS AvgIRR
						FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						and fundingmethod='portfolio'
						group by  consultantid,consultant
					)a_current_IRR
					INNER JOIN 
					(
						Select consultantid, 	
						round(sum(leaseamt),0) as Total_originations
							,round(sum(case when [FundingMethod]='Portfolio' then leaseamt else 0 end),0) as Total_Portfolio_originations		
						FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						group by  consultantid,consultant
					)B_current_IRR
					on B_current_IRR.consultantid=a_current_IRR.consultantid
				)currentmonth_IRR
				on currentmonth_IRR.consultantId=consultants.id

				left JOIN--po
				(
					select a_current_po.*,
					case when B_current_po.Total_Portfolio_originations>=125000 then round(a_current_po.purchaseOptionPercentage,2)
					else 0
					end as AdjustpurchaseOptionPercentage
					from 
					(
						Select consultantid, consultant,
						round(sum(PURCHASEOPTION),0) as PURCHASEOPTION,
						round(sum(Equipmentcost),0) as Equipmentcost,
						round(cast(sum(PURCHASEOPTION) as float) /cast (sum(Equipmentcost) as float)*100,2) as purchaseOptionPercentage
						FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						AND POELIGIBILITY=1			
						group by  consultantid,consultant
					)a_current_po
					INNER JOIN 
					(
						Select consultantid, 	
						round(sum(leaseamt),0) as Total_originations
							,round(sum(case when [FundingMethod]='Portfolio' then leaseamt else 0 end),0) as Total_Portfolio_originations		
											FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						group by  consultantid,consultant
					)B_current_po
					on B_current_po.consultantid=a_current_po.consultantid
				)currentmonth_po
				on currentmonth_po.consultantId=consultants.id
				
				left join--SD
				(
					select a_current_SD.*,
					case when B_current_SD.Total_Portfolio_originations>=125000 then round(a_current_SD.securityDepositPercentage,2)
					else 0
					end as AdjustsecurityDepositPercentage
					from 
					(
						Select consultantid, consultant,
						round(sum(securitydeposit),0) as securitydeposit,
						round(cast ((sum(payment)) as float)*2,0) as AbsolutePayment,
						round(cast(sum(securitydeposit) as float) /(cast ((sum(payment)) as float)*2)*100,2) as securityDepositPercentage
						FROM CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom
						AND SDELIGIBILITY=1
						group by  consultantid,consultant
					)a_current_SD
					inner JOIN 
					(
						Select consultantid, 	
						round(sum(leaseamt),0) as portfolio_originations
						,round(sum(case when [FundingMethod]='Portfolio' then leaseamt else 0 end),0) as Total_Portfolio_originations		
							FROM  CRM_BeaconIntranet_SalesDetails_Hourly
						WHERE acceptanceDate< @dateTo AND acceptanceDate>= @dateFrom			
						group by  consultantid,consultant
					)B_current_SD
					on B_current_SD.consultantid=a_current_SD.consultantid
				)currentmonth_SD
				on currentmonth_SD.consultantId=consultants.id

			end
			

		set @dateFrom=dateadd(month,1, @dateFrom)

		end

		select consultant, consultantid, 
		sum (oneoffbonus) as oneoffbonustotal, sum(irrbonus) as irrbonustotal,sum(purchaseoptionbonus) as purchaseoptionbonustotal, sum(securitydepositbonus) as securitydepositbonustotal
		,(sum (oneoffbonus)+ sum(irrbonus) +sum(purchaseoptionbonus)+sum(securitydepositbonus)) as bonusTotal 
		 from #tempsalesincentive
		group by consultant,consultantid
		order by consultant

END
GO
