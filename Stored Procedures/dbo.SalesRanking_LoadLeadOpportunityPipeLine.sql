SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		ruonan
-- Create date: 3/12/2014
-- Description:	load inside sales employee activity info for sales ranking
-- Updated:		4/6/2015 - Commented out the last else for the date - Leo
-- =============================================
CREATE PROCEDURE [dbo].[SalesRanking_LoadLeadOpportunityPipeLine] --'4/5/2015',0
	@ENDDATE as date,
	@IsInsideSales as bit=1
AS
declare @reportdate as date
declare @max_date as date

if @IsInsideSales =1
begin
	select @max_date= max([ReportDate])FROM [CRMReplication].[dbo].[Noble_DailyReports]
    if exists (    
    select [ReportDate]
 FROM [CRMReplication].[dbo].[Noble_DailyReports]
  where [ReportDate]= DATEADD(dd, 0, DATEDIFF(dd, 0, @ENDDATE)))
  begin
	select @reportdate= DATEADD(dd, 0, DATEDIFF(dd, 0, @ENDDATE))
  end
  
  else begin 
	
		if datepart(dw, @ENDDATE) = 7 and  exists (    
		select [ReportDate]
		FROM [CRMReplication].[dbo].[Noble_DailyReports]
		where [ReportDate]= DATEADD(dd, -1, DATEDIFF(dd, 0, @ENDDATE)))
		begin 
			select @reportdate= DATEADD(dd, -1, DATEDIFF(dd, 0, @ENDDATE)) 
		end
		else begin 
			if datepart(dw, @ENDDATE) = 1 and  exists (    
			select [ReportDate]
			FROM [CRMReplication].[dbo].[Noble_DailyReports]
			where [ReportDate]= DATEADD(dd, -2, DATEDIFF(dd, 0, @ENDDATE)))
			begin 
				select @reportdate= DATEADD(dd, -2, DATEDIFF(dd, 0, @ENDDATE)) 
			end
			else begin 
				if  @ENDDATE>=@max_date
				begin 
					select @reportdate=max([ReportDate])FROM [CRMReplication].[dbo].[Noble_DailyReports]
				end
				--else
				--begin
				--	 select @reportdate=min([ReportDate])FROM [CRMReplication].[dbo].[Noble_DailyReports]
				--end
			end
		end
end  
SELECT [ReportDate]
       ,[AgentCode]
      ,[CRMGuid]
      ,[Leads]
      ,[LeadsAmount]
      ,isnull([Opportunities2],0)+ isnull([Opportunities3],0)+ isnull([Opportunities4],0)+ isnull([Opportunities5],0)+ isnull([Opportunities6],0)
      as opportunity_total
       ,isnull([OpportunitiesAmount2],0)+ isnull([OpportunitiesAmount3],0)+ isnull([OpportunitiesAmount4],0)+ isnull([OpportunitiesAmount5],0)+ isnull([OpportunitiesAmount6],0)
      as  opportunityamount_total
      ,[Opportunities2]as opportunity_disc
      ,[OpportunitiesAmount2] as opportunityamount_disc
      ,[Opportunities3]as opportunity_incredit
      ,[OpportunitiesAmount3]as opportunityamount_incredit
      ,[Opportunities4]as opportunity_creditapproval
      ,[OpportunitiesAmount4]as opportunityamount_creditapproval
      ,[Opportunities5]as opportunity_creditdeclined
      ,[OpportunitiesAmount5]as opportunityamount_creditdeclined
      ,[Opportunities6]as opportunity_docs
      ,[OpportunitiesAmount6]as opportunityamount_docs
      ,[Opportunities7]
      ,[OpportunitiesAmount7]
 FROM [CRMReplication].[dbo].[Noble_DailyReports]
  where [ReportDate]= @reportdate
SELECT sum([Leads]) as leads, sum([LeadsAmount]) as [LeadsAmount]
      --,sum([Opportunities]) as opportunity_total
  ,sum(isnull([Opportunities2],0))+sum(isnull([Opportunities3],0))+sum(isnull([Opportunities4],0))+sum(isnull([Opportunities5],0))+sum(isnull([Opportunities6],0))as opportunity_total
 ,sum(isnull([OpportunitiesAmount2],0))+sum(isnull([OpportunitiesAmount3],0))+sum(isnull([OpportunitiesAmount4],0))+sum(isnull([OpportunitiesAmount5],0))+sum(isnull([OpportunitiesAmount6],0))as opportunityAmount_total




     ,sum([Opportunities2])as opportunity_disc,  sum([OpportunitiesAmount2])as opportunityAmount_disc
      ,sum([Opportunities3])as opportunity_incredit,  sum([OpportunitiesAmount3])as opportunityAmount_incredit
      ,sum([Opportunities4])as opportunity_creditapproval,  sum([OpportunitiesAmount4])as opportunityAmount_creditapproval
      ,sum([Opportunities5])as opportunity_creditdeclined,  sum([OpportunitiesAmount5])as opportunityAmount_creditdeclined
      ,sum([Opportunities6])as opportunity_docs,  sum([OpportunitiesAmount6])as opportunityAmount_docs
   
 FROM [CRMReplication].[dbo].[Noble_DailyReports]
  where [ReportDate]= @reportdate

end

else--outside sales
begin
	select @max_date=max([ReportDate])FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
   if exists (    
    select [ReportDate]
 FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
  where [ReportDate]= DATEADD(dd, 0, DATEDIFF(dd, 0, @ENDDATE)))
  begin
	select @reportdate= DATEADD(dd, 0, DATEDIFF(dd, 0, @ENDDATE))
  end
  
  else begin 
	
		if datepart(dw, @ENDDATE) = 7 and  exists (    
		select [ReportDate]
		FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
		where [ReportDate]= DATEADD(dd, -1, DATEDIFF(dd, 0, @ENDDATE)))
		begin 
			select @reportdate= DATEADD(dd, -1, DATEDIFF(dd, 0, @ENDDATE)) 
		end
		else begin 
			if datepart(dw, @ENDDATE) = 1 and  exists (    
			select [ReportDate]
			FROM [CRMReplication].[dbo].[Noble_DailyReports]
			where [ReportDate]= DATEADD(dd, -2, DATEDIFF(dd, 0, @ENDDATE)))
			begin 
				select @reportdate= DATEADD(dd, -2, DATEDIFF(dd, 0, @ENDDATE)) 
			end
			else begin 
				if  @ENDDATE>=@max_date
				begin 
					select @reportdate=max([ReportDate])FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
				end
				--else
				--begin
				--	 select @reportdate=min([ReportDate])FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
				--end
			end
		end
end  
SELECT [ReportDate]
      ,SalesConsultantId 
    ,[Leads]
      ,[LeadsAmount]
     ,isnull([Opportunities2],0)+ isnull([Opportunities3],0)+ isnull([Opportunities4],0)+ isnull([Opportunities5],0)+ isnull([Opportunities6],0)
      as opportunity_total
       ,isnull([OpportunitiesAmount2],0)+ isnull([OpportunitiesAmount3],0)+ isnull([OpportunitiesAmount4],0)+ isnull([OpportunitiesAmount5],0)+ isnull([OpportunitiesAmount6],0)
      as  opportunityamount_total
    
      ,[Opportunities2]as opportunity_disc
      ,[OpportunitiesAmount2] as opportunityamount_disc
      ,[Opportunities3]as opportunity_incredit
      ,[OpportunitiesAmount3]as opportunityamount_incredit
      ,[Opportunities4]as opportunity_creditapproval
      ,[OpportunitiesAmount4]as opportunityamount_creditapproval
      ,[Opportunities5]as opportunity_creditdeclined
      ,[OpportunitiesAmount5]as opportunityamount_creditdeclined
      ,[Opportunities6]as opportunity_docs
      ,[OpportunitiesAmount6]as opportunityamount_docs
      ,[Opportunities7]
      ,[OpportunitiesAmount7]
 FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
  where [ReportDate]= @reportdate
SELECT sum([Leads]) as leads, sum([LeadsAmount]) as [LeadsAmount]
      --,sum([Opportunities]) as opportunity_total
  ,sum(isnull([Opportunities2],0))+sum(isnull([Opportunities3],0))+sum(isnull([Opportunities4],0))+sum(isnull([Opportunities5],0))+sum(isnull([Opportunities6],0))as opportunity_total
 ,sum(isnull([OpportunitiesAmount2],0))+sum(isnull([OpportunitiesAmount3],0))+sum(isnull([OpportunitiesAmount4],0))+sum(isnull([OpportunitiesAmount5],0))+sum(isnull([OpportunitiesAmount6],0))as opportunityAmount_total




     ,sum([Opportunities2])as opportunity_disc,  sum([OpportunitiesAmount2])as opportunityAmount_disc
      ,sum([Opportunities3])as opportunity_incredit,  sum([OpportunitiesAmount3])as opportunityAmount_incredit
      ,sum([Opportunities4])as opportunity_creditapproval,  sum([OpportunitiesAmount4])as opportunityAmount_creditapproval
      ,sum([Opportunities5])as opportunity_creditdeclined,  sum([OpportunitiesAmount5])as opportunityAmount_creditdeclined
      ,sum([Opportunities6])as opportunity_docs,  sum([OpportunitiesAmount6])as opportunityAmount_docs
   
 FROM [CRMReplication].[dbo].SalesRanking_OutSideSalesDailyPipeLine
  where [ReportDate]= @reportdate


end

GO
