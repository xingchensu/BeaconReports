SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:    Ruonan
-- Create date: 5/14/2015
-- Description:  load all evaluation
-- =============================================
--[dbo].[KeyStats_EmployeeEvaluation_Load]'10/1/2015','10/6/2015',14,1
CREATE PROCEDURE [dbo].[KeyStats_EmployeeEvaluation_TakingDailySnapshot] 

AS
BEGIN

  SET NOCOUNT ON;

  

    IF OBJECT_ID('TEMPDB..#Evaluation') IS NOT NULL

    BEGIN

      DROP TABLE #Evaluation

    END





    CREATE TABLE #Evaluation (
      EvaluationTypeValue int,
      EvaluationType nvarchar(50),
      EvaluatedByType nvarchar(50),
      EvaluatedByID uniqueidentifier,
      EvaluatedByName nvarchar(250),    
      EvaluateForID uniqueidentifier,
      
      EvaluateForName nvarchar(250),
      Rating int,
      Comments varchar(4000),
      OpportunityID uniqueidentifier,
      Opportunity nvarchar(500),
      ActualCloseDate datetime,
      IsConfidential int,
        EvaluateForUsername varchar(100),
    )



    IF OBJECT_ID('tempdb..#evaluation_user_itemBase') IS NOT NULL
      DROP TABLE #evaluation_user_itemBase
    SELECT
      * INTO #evaluation_user_itemBase
    FROM BeaconFunding_MSCRM.dbo.new_evaluation_user_itemBase

    INSERT INTO #Evaluation
    

      --client evaluation
      SELECT DISTINCT      
       et.[EvaluationTypeID] as EvaluationTypeValue
        ,EvaluationTypeName AS EvaluationType
         , CASE [Type]
          WHEN 5 THEN 'Lessee'
          WHEN 6 THEN 'Referal'
          WHEN 7 THEN 'PersonalGuarantor'
          ELSE 'Vendor'
        END AS EvaluatedByType,
        e.contactid AS EvaluatedByID,
        c.fullname COLLATE Latin1_General_CI_AI AS EvaluatedByName,
        r.EvaluatedForUserGuid AS EvaluateForID,
        r.EvaluatedForUserName AS EvaluateForName,
        r.Rating,
        r.Comments,
        o.OpportunityID,
        o.name AS opportunity,
        o.ActualCloseDate,
        NULL AS IsConfidential
        ,null as EvaluateForUsername
      FROM CRMReplication2013.dbo.Vendor_Lessee_Evaluation e
      INNER JOIN CRMReplication2013.dbo.Vendor_Lessee_Evaluation_Results r
        ON e.ID = r.EvalID    
      INNER JOIN CRMReplication2013.dbo.opportunity o
        ON o.opportunityid = e.OpportunityID
      INNER JOIN CRMReplication2013.dbo.AccountExtensionBase a
        ON a.AccountId = o.AccountID
      INNER JOIN CRMReplication2013.dbo.contact c
        ON e.contactid = c.contactid        
      inner join KeyStats_EvaluationTypes et on [EvaluationTypeID]=1
      WHERE r.Rating IS NOT NULL
      AND r.Rating > 0

      UNION ALL

      --old evauation
      SELECT DISTINCT

        et.EvaluationTypeID AS EvaluationTypeValue,
        et.EvaluationTypeName AS EvaluationType,
        'LeaseAdministrator' AS EvaluatedByType,
        o.new_leaseadministratorid AS EvaluatedByID,
        u.fullname AS EvaluatedByName,       
        o.ownerid AS EvaluateForID,
        o.owneridname AS EvaluateForName,
        LeaseAdministratorRating AS Rating,
        CONVERT(varchar(4000), LeaseAdministratorComments) AS Comments,
        o.OpportunityID,
        o.name AS opportunity,
        o.ActualCloseDate,
        NULL AS IsConfidential   ,null as EvaluateForUsername
      FROM freestuf.dbo.O_Evaluation_SideTab e
      INNER JOIN CRMReplication2013.dbo.Opportunity o
        ON o.opportunityid = e.GuidID
      LEFT JOIN CRMReplication2013.dbo.systemuser u
        ON u.systemuserid = o.new_leaseadministratorid
      INNER JOIN CRMReplication2013.dbo.AccountExtensionBase a
        ON a.AccountId = o.AccountID
      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2     
      WHERE LeaseAdministratorRating IS NOT NULL
      AND LeaseAdministratorRating > 0

      UNION ALL

      --internal 
      SELECT
      DISTINCT
        et.EvaluationTypeID AS EvaluationTypeValue,
        et.EvaluationTypeName AS EvaluationType,
        CASE
          WHEN o.ownerid = evl.new_evaluatedby THEN 'Consultant'
          WHEN ((o.New_ShareCreditId IS NOT NULL AND
            o.New_ShareCreditId = evl.new_evaluatedby) OR
            (o.New_ShareCredit2Id IS NOT NULL AND
            o.New_ShareCredit2Id = evl.new_evaluatedby) OR
            (o.New_ShareCredit3Id IS NOT NULL AND
            o.New_ShareCredit3Id = evl.new_evaluatedby) OR
            (o.New_ShareCredit4Id IS NOT NULL AND
            o.New_ShareCredit4Id = evl.new_evaluatedby) OR
            (o.New_ShareCredit5Id IS NOT NULL AND
            o.New_ShareCredit5Id = evl.new_evaluatedby)) THEN 'SharedCredit'
          WHEN o.new_leaseadministratorid = evl.new_evaluatedby THEN 'LeaseAdministrator'
          WHEN o.[New_SyndicationsManagerId] = evl.new_evaluatedby THEN 'Syndications Manager'
          ELSE 'Other'
        END AS evaluatedByType,
        evl.createdby AS EvaluatedByID,
        CAST(evl.createdbyname AS nvarchar(250)) AS EvaluatedByName,
        eu.systemuserid AS EvaluateForID,
        sb.fullname AS EvaluateForName,
        evl.new_rating AS Rating,
        CONVERT(varchar(4000), New_Description COLLATE Latin1_General_CI_AS) AS Comments,
        o.OpportunityId,
        o.name AS opportunity,
        o.ActualCloseDate,
        ISNULL(New_IsConfidential, 1) AS IsConfidential  
         ,null as EvaluateForUsername
      FROM CRMReplication2013.dbo.new_opportunityevaluation evl
      INNER JOIN #evaluation_user_itemBase eu
        ON evl.new_opportunityevaluationid = eu.new_opportunityevaluationid
      INNER JOIN CRMReplication2013.dbo.Opportunity o
        ON o.opportunityid = evl.new_opportunityid
        --AND o.ownerid = eu.systemuserid
      INNER JOIN CRMReplication2013.dbo.AccountExtensionBase a
        ON a.AccountId = o.AccountID
      INNER JOIN CRMReplication2013.dbo.SystemUserBase sb
        ON sb.SystemUserId = eu.systemuserid
      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2    
      WHERE evl.new_rating IS NOT NULL

     union
     --whd evaluation
        SELECT
      DISTINCT
        et.EvaluationTypeID AS EvaluationTypeValue,
        et.EvaluationTypeName AS EvaluationType,
        'WHD Client' as EvaluatedByType ,
        null as EvaluatedByID ,
        c.LAST_NAME+', '+c.FIRST_NAME    as EvaluatedByName,
          null as EvaluateForID ,       
          
        
           isnull(
           substring(uws.[EvaluatedFor],charindex(' ',uws.[EvaluatedFor])+1,len(uws.[EvaluatedFor])-charindex(' ',uws.[EvaluatedFor]))
          +', '+substring(uws.[EvaluatedFor],1,charindex(' ',uws.[EvaluatedFor])-1)
           
          ,t.LAST_NAME+', '+t.FIRST_NAME  )            AS EvaluateForName ,
        	  uws.[Rating] AS Rating,	
	   uws.Comments AS Comments,
	   null as OpportunityID ,
	   null as Opportunity ,	   
	    jt.CLOSE_DATE AS ActualCloseDate,
	   null as IsConfidential 
	      ,isnull(uws_t.[user_name],t.[user_name]) as EvaluateForUsername
	   FROM LINK_WHD.whd.dbo.JOB_TICKET AS jt
	       LEFT JOIN LINK_WHD.whd.dbo.TECH AS t
      ON t.CLIENT_ID = jt.ASSIGNED_TECH_ID
      LEFT JOIN LINK_WHD.whd.dbo.CLIENT AS c
      ON c.CLIENT_ID = jt.CLIENT_ID
	LEFT JOIN LINK_WHD.whd.dbo.udt_WHDCustomSurvey uws	
	  ON uws.TicketNumber = jt.JOB_TICKET_ID
	  left join LINK_WHD.whd.dbo.TECH AS uws_t
	  on uws.EvaluatedFor=uws_t.FIRST_NAME + ' ' + uws_t.LAST_NAME
	     INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2    
        where  uws.Rating is not null
        and uws.Rating>0
        --order by uws.Rating
        
        --and t.FIRST_NAME + ' ' + t.LAST_NAME='ruonan wen'
	  
    UPDATE #Evaluation
    SET evaluateforname = 'Shumaker, Dan'
    WHERE evaluateforname = 'Shumaker, Danal'

    TRUNCATE TABLE 
     dbo.KeyStats_EmployeeEvaluation_DailySnapShot
    INSERT INTO dbo.KeyStats_EmployeeEvaluation_DailySnapShot (EvaluationTypeValue, [EvaluationType]
    , [EvaluatedByType]
    , [EvaluatedByID]
    , [EvaluatedByName]   
    , [EvaluateForID]
    , [EvaluateForName]
    , [Rating]
    , [Comments]
    , [OpportunityID]
    , [Opportunity]
    , [ActualCloseDate]
    , [IsConfidential],EvaluateForUsername)
      SELECT
       EvaluationTypeValue, [EvaluationType]
    , [EvaluatedByType]
    , [EvaluatedByID]
    , [EvaluatedByName]   
    , [EvaluateForID]
    , [EvaluateForName]
    , [Rating]
    , [Comments]
    , [OpportunityID]
    , [Opportunity]
    , [ActualCloseDate]
    , [IsConfidential],EvaluateForUsername
      FROM #Evaluation

END
GO
