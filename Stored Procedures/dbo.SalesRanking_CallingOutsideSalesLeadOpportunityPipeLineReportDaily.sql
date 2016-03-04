SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Ruonan 4/28/2014
CREATE PROCEDURE [dbo].[SalesRanking_CallingOutsideSalesLeadOpportunityPipeLineReportDaily]
AS
BEGIN

	declare @PreDay as date
	if (datepart(dw, getdate()) = 2)
	begin
		--If it is Monday, set PreDay as last Friday
		set @PreDay = dateadd(day, -3, cast(getdate() as date))
	end
	else
	begin
		set @PreDay = dateadd(day, -1, cast(getdate() as date))
	END
	
		
	if object_id('tempdb..#Opps') is not null
	begin
		drop table #Opps
	END
	select 
	createdon, o.OpportunityId,o.salesstagecode,	ISNULL(ot.New_AmountFinanced, o.CFCLeaseAmount)LeaseAmount,o.ownerid into #Opps
	 from  dbo.Opportunity o 
	LEFT JOIN (SELECT New_OpportunityId, New_AmountFinanced FROM dbo.New_OpportunityTerm WHERE  New_IsInLCW = 1) ot ON o.OpportunityId = ot.New_OpportunityId		
	WHERE o.StateCode = 0 
	
	INSERT INTO   dbo.SalesRanking_OutSideSalesDailyPipeLine
	( ReportDate,
	          SalesConsultantId ,	      
	          Leads ,
	          LeadsAmount ,
	          Opportunities ,
	          OpportunitiesAmount,
	          Opportunities2 ,
	          OpportunitiesAmount2,
	          Opportunities3 ,
	          OpportunitiesAmount3,
	          Opportunities4 ,
	          OpportunitiesAmount4,
	          Opportunities5 ,
	          OpportunitiesAmount5,
	          Opportunities6 ,
	          OpportunitiesAmount6,
	          Opportunities7 ,
	          OpportunitiesAmount7
	        )

select  @PreDay as ReportDate,l.ownerid,--l.owneridname,
l.leadid,
l.CFCEstimatedEquipCost as leadamount,
opp.opportunityid as opp,opp.LeaseAmount as oppamount ,
opp_2.opportunityid as opp2,opp_2.LeaseAmount as opp2amount ,
opp_3.opportunityid as opp3,opp_3.LeaseAmount as opp3amount ,
opp_4.opportunityid as opp4,opp_4.LeaseAmount as opp4amount ,
opp_5.opportunityid as opp5,opp_5.LeaseAmount as opp5amount ,
opp_6.opportunityid as opp6,opp_6.LeaseAmount as opp6amount ,
opp_7.opportunityid as opp7,opp_7.LeaseAmount as opp7amount 
from (select count(leadid) as leadid,sum(CFCEstimatedEquipCost) as CFCEstimatedEquipCost,ownerid from lead where StateCode = 0  group by ownerid)l

LEFT JOIN (SELECT ownerid, COUNT(OpportunityId) AS opportunityid, SUM(LeaseAmount) AS LeaseAmount FROM #Opps GROUP BY ownerid) opp ON l.ownerid=opp.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=2  group by ownerid ) opp_2 on l.ownerid=opp_2.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=3  group by ownerid ) opp_3 on l.ownerid=opp_3.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=4  group by ownerid ) opp_4 on l.ownerid=opp_4.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=5  group by ownerid ) opp_5 on l.ownerid=opp_5.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=6  group by ownerid ) opp_6 on l.ownerid=opp_6.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=7  group by ownerid ) opp_7 on l.ownerid=opp_7.ownerid	
 where l.ownerid in 

(select  su.SystemUserId as id 
			from systemuser su
			INNER JOIN
			dbo.SystemUserRoles sur
			on su.SystemUserId = sur.SystemUserId
			WHERE IsDisabled = 0 and sur.roleid='925BDCD4-9621-4BCC-B3A0-52D932529A8E' and fullname not in
				(
					Select systemusername from dbo.XCelsius_Excluded_Users_When_Calculating_Avg
				)  
) 
union
--miscellanous
	select  @PreDay as ReportDate,null as ownerid,
sum(l.leadid) as leadid,
sum(l.CFCEstimatedEquipCost) as leadamount,
sum(opp.opportunityid) as opp,sum(opp.LeaseAmount) as oppamount ,
sum(opp_2.opportunityid) as opp2,sum(opp_2.LeaseAmount) as opp2amount ,
sum(opp_3.opportunityid) as opp3,sum(opp_3.LeaseAmount) as opp3amount ,
sum(opp_4.opportunityid) as opp4,sum(opp_4.LeaseAmount) as opp4amount ,
sum(opp_5.opportunityid) as opp5,sum(opp_5.LeaseAmount) as opp5amount ,
sum(opp_6.opportunityid) as opp6,sum(opp_6.LeaseAmount) as opp6amount ,
sum(opp_7.opportunityid) as opp7,sum(opp_7.LeaseAmount) as opp7amount 
from (select count(leadid) as leadid,sum(CFCEstimatedEquipCost) as CFCEstimatedEquipCost,ownerid ,owneridname from lead where StateCode = 0 group by ownerid,owneridname)l

LEFT JOIN (SELECT ownerid, COUNT(OpportunityId) AS opportunityid, SUM(LeaseAmount) AS LeaseAmount FROM #Opps GROUP BY ownerid) opp ON l.ownerid=opp.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=2  group by ownerid ) opp_2 on l.ownerid=opp_2.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=3  group by ownerid ) opp_3 on l.ownerid=opp_3.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=4  group by ownerid ) opp_4 on l.ownerid=opp_4.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=5  group by ownerid ) opp_5 on l.ownerid=opp_5.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=6  group by ownerid ) opp_6 on l.ownerid=opp_6.ownerid	
left join (select ownerid, COUNT(OpportunityId) as opportunityid,SUM(LeaseAmount) AS LeaseAmount from #Opps where salesstagecode=7  group by ownerid ) opp_7 on l.ownerid=opp_7.ownerid	
 where l.ownerid not in 

(select  su.SystemUserId as id 
			from systemuser su
			INNER JOIN
			dbo.SystemUserRoles sur
			on su.SystemUserId = sur.SystemUserId
			WHERE IsDisabled = 0 and sur.roleid='925BDCD4-9621-4BCC-B3A0-52D932529A8E' and fullname not in
				(
					Select systemusername from dbo.XCelsius_Excluded_Users_When_Calculating_Avg
				)  
) 
and l.ownerid not in 

(	SELECT  su.SystemUserId AS guid
			
FROM dbo.systemuser su
INNER JOIN
dbo.SystemUserRoles sur
on su.SystemUserId = sur.SystemUserId
WHERE 
sur.RoleId = 'ED4FDE05-3337-E111-98DF-78E7D1F817F8' 
) 


end

GO
