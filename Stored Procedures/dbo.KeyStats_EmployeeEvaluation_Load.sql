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
CREATE PROCEDURE [dbo].[KeyStats_EmployeeEvaluation_Load] @BEGINDATE AS datetime, @ENDDATE AS datetime
, @groupNo AS int
, @takingOpenSnapShot AS bit = 0
AS
BEGIN

  SET NOCOUNT ON;

  IF @takingOpenSnapShot = 1
  BEGIN




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
      EvaluateForType nvarchar(50),
      EvaluateForID uniqueidentifier,
      EvaluateForName nvarchar(250),
      Rating int,
      Comments varchar(4000),
      OpportunityID uniqueidentifier,
      Opportunity nvarchar(500),
      ActualCloseDate datetime,
      IsConfidential int,
      EvaluateForTypeValue int
    )



    IF OBJECT_ID('tempdb..#evaluation_user_itemBase') IS NOT NULL
      DROP TABLE #evaluation_user_itemBase
    SELECT
      * INTO #evaluation_user_itemBase
    FROM BeaconFunding_MSCRM.dbo.new_evaluation_user_itemBase

    INSERT INTO #Evaluation

      --client evaluation
      SELECT DISTINCT
        et.EvaluationTypeID AS EvaluationTypeValue,
        et.EvaluationTypeName AS EvaluationType,

        CASE [Type]

          WHEN 5 THEN 'Lessee'

          WHEN 6 THEN 'Referal'

          WHEN 7 THEN 'PersonalGuarantor'

          ELSE 'Vendor'

        END AS EvaluatedByType,
        e.contactid AS EvaluatedByID,
        c.fullname COLLATE Latin1_General_CI_AI AS EvaluatedByName,
        eft.EvaluatedForTypeName AS EvaluateForType,
        r.EvaluatedForUserGuid AS EvaluateForID,
        r.EvaluatedForUserName AS EvaluateForName,
        r.Rating,
        r.Comments,
        o.OpportunityID,
        o.name AS opportunity,
        o.ActualCloseDate,
        NULL AS IsConfidential,
        eft.EvaluatedForTypeID AS EvaluateForTypeValue
      FROM CRMReplication.dbo.Vendor_Lessee_Evaluation e
      INNER JOIN CRMReplication.dbo.Vendor_Lessee_Evaluation_Results r
        ON e.ID = r.EvalID
      INNER JOIN CRMReplication.[dbo].[Vendor_Lessee_Evaluation_EvaluatedForType_Relationship] eft
        ON eft.EvaluatedForTypeID = r.EvaluatedForType
      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 1
      INNER JOIN CRMReplication.dbo.opportunity o
        ON o.opportunityid = e.OpportunityID
      INNER JOIN CRMReplication.dbo.AccountExtensionBase a
        ON a.AccountId = o.AccountID
      INNER JOIN CRMReplication2013.dbo.contact c
        ON e.contactid = c.contactid
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
        ieft.InternalEvaluationForTypeName AS EvaluateForType,
        o.ownerid AS EvaluateForID,
        o.owneridname AS EvaluateForName,
        LeaseAdministratorRating AS Rating,
        CONVERT(varchar(4000), LeaseAdministratorComments) AS Comments,
        o.OpportunityID,
        o.name AS opportunity,
        o.ActualCloseDate,
        NULL AS IsConfidential,
        InternalEvaluationForTypeID AS EvaluateForTypeValue


      FROM freestuf.dbo.O_Evaluation_SideTab e

      INNER JOIN CRMReplication.dbo.Opportunity o

        ON o.opportunityid = e.GuidID

      LEFT JOIN CRMReplication.dbo.systemuser u

        ON u.systemuserid = o.new_leaseadministratorid

      INNER JOIN CRMReplication.dbo.AccountExtensionBase a

        ON a.AccountId = o.AccountID
      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2
      INNER JOIN dbo.KeyStats_InternalEvaluationForTypes ieft
        ON ieft.InternalEvaluationForTypeID = 1
      WHERE LeaseAdministratorRating IS NOT NULL

      AND LeaseAdministratorRating > 0

      UNION ALL

      --internal owner
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
          ELSE ''
        END AS evaluatedByType,
        evl.createdby AS EvaluatedByID,
        CAST(evl.createdbyname AS nvarchar(250)) AS EvaluatedByName,
        ieft.InternalEvaluationForTypeName AS EvaluatedforType,
        eu.systemuserid AS EvaluateForID,
        sb.fullname AS EvaluateForName,
        evl.new_rating AS Rating,
        CONVERT(varchar(4000), New_Description COLLATE Latin1_General_CI_AS) AS Comments,
        o.OpportunityId,
        o.name AS opportunity,
        o.ActualCloseDate,
        ISNULL(New_IsConfidential, 1) AS IsConfidential,
        ieft.InternalEvaluationForTypeID AS EvaluatedforTypeValue
      FROM CRMReplication.dbo.new_opportunityevaluation evl
      INNER JOIN #evaluation_user_itemBase eu
        ON evl.new_opportunityevaluationid = eu.new_opportunityevaluationid
      INNER JOIN CRMReplication.dbo.Opportunity o
        ON o.opportunityid = evl.new_opportunityid
        AND o.ownerid = eu.systemuserid
      INNER JOIN CRMReplication.dbo.AccountExtensionBase a
        ON a.AccountId = o.AccountID
      INNER JOIN CRMReplication.dbo.SystemUserBase sb
        ON sb.SystemUserId = eu.systemuserid
      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2
      INNER JOIN dbo.KeyStats_InternalEvaluationForTypes ieft
        ON ieft.InternalEvaluationForTypeID = 1
      WHERE evl.new_rating IS NOT NULL

      --internal share credit
      UNION ALL
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
          ELSE ''
        END AS evaluatedByType,
        evl.createdby AS EvaluatedByID,
        CAST(evl.createdbyname AS nvarchar(250)) AS EvaluatedByName,

        ieft.InternalEvaluationForTypeName AS EvaluatedforType,

        eu.systemuserid AS EvaluateForID,

        sb.fullname AS EvaluateForName,

        evl.new_rating AS Rating,

        CONVERT(varchar(4000), New_Description COLLATE Latin1_General_CI_AS) AS Comments,

        o.OpportunityId,

        o.name AS opportunity,

        o.ActualCloseDate,

        ISNULL(New_IsConfidential, 1) AS IsConfidential,

        ieft.InternalEvaluationForTypeID AS EvaluatedforTypeValue

      FROM CRMReplication.dbo.new_opportunityevaluation evl

      INNER JOIN #evaluation_user_itemBase eu

        ON evl.new_opportunityevaluationid = eu.new_opportunityevaluationid

      INNER JOIN CRMReplication.dbo.Opportunity o

        ON o.opportunityid = evl.new_opportunityid
        AND o.ownerid <> eu.systemuserid
        AND ((o.New_ShareCreditId IS NOT NULL
        AND o.New_ShareCreditId = eu.systemuserid)
        OR (o.New_ShareCredit2Id IS NOT NULL
        AND o.New_ShareCredit2Id = eu.systemuserid)
        OR (o.New_ShareCredit3Id IS NOT NULL
        AND o.New_ShareCredit3Id = eu.systemuserid)
        OR (o.New_ShareCredit4Id IS NOT NULL
        AND o.New_ShareCredit4Id = eu.systemuserid)
        OR (o.New_ShareCredit5Id IS NOT NULL
        AND o.New_ShareCredit5Id = eu.systemuserid))

      INNER JOIN CRMReplication.dbo.AccountExtensionBase a

        ON a.AccountId = o.AccountID

      INNER JOIN CRMReplication.dbo.SystemUserBase sb

        ON sb.SystemUserId = eu.systemuserid


      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2
      INNER JOIN dbo.KeyStats_InternalEvaluationForTypes ieft
        ON ieft.InternalEvaluationForTypeID = 2
      WHERE evl.new_rating IS NOT NULL



      --internal lease admin
      UNION ALL
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
          ELSE ''
        END AS evaluatedByType,
        evl.createdby AS EvaluatedByID,
        CAST(evl.createdbyname AS nvarchar(250)) AS EvaluatedByName,

        ieft.InternalEvaluationForTypeName AS EvaluatedforType,

        eu.systemuserid AS EvaluateForID,

        sb.fullname AS EvaluateForName,

        evl.new_rating AS Rating,

        CONVERT(varchar(4000), New_Description COLLATE Latin1_General_CI_AS) AS Comments,

        o.OpportunityId,

        o.name AS opportunity,

        o.ActualCloseDate,

        ISNULL(New_IsConfidential, 1) AS IsConfidential,

        ieft.InternalEvaluationForTypeID AS EvaluatedforTypeValue

      FROM CRMReplication.dbo.new_opportunityevaluation evl

      INNER JOIN #evaluation_user_itemBase eu

        ON evl.new_opportunityevaluationid = eu.new_opportunityevaluationid

      INNER JOIN CRMReplication.dbo.Opportunity o

        ON o.opportunityid = evl.new_opportunityid
        AND o.ownerid <> eu.systemuserid
        AND (NOT ((o.New_ShareCreditId IS NOT NULL
        AND o.New_ShareCreditId = eu.systemuserid)
        OR (o.New_ShareCredit2Id IS NOT NULL
        AND o.New_ShareCredit2Id = eu.systemuserid)
        OR (o.New_ShareCredit3Id IS NOT NULL
        AND o.New_ShareCredit3Id = eu.systemuserid)
        OR (o.New_ShareCredit4Id IS NOT NULL
        AND o.New_ShareCredit4Id = eu.systemuserid)
        OR (o.New_ShareCredit5Id IS NOT NULL
        AND o.New_ShareCredit5Id = eu.systemuserid)))

        AND o.new_leaseadministratorid = eu.systemuserid

      INNER JOIN CRMReplication.dbo.AccountExtensionBase a

        ON a.AccountId = o.AccountID

      INNER JOIN CRMReplication.dbo.SystemUserBase sb

        ON sb.SystemUserId = eu.systemuserid


      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2
      INNER JOIN dbo.KeyStats_InternalEvaluationForTypes ieft
        ON ieft.InternalEvaluationForTypeID = 3
      WHERE evl.new_rating IS NOT NULL

      --internal syndication manager
      UNION ALL
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
          ELSE ''
        END AS evaluatedByType,
        evl.createdby AS EvaluatedByID,
        CAST(evl.createdbyname AS nvarchar(250)) AS EvaluatedByName,

        ieft.InternalEvaluationForTypeName AS EvaluatedforType,

        eu.systemuserid AS EvaluateForID,

        sb.fullname AS EvaluateForName,

        evl.new_rating AS Rating,

        CONVERT(varchar(4000), New_Description COLLATE Latin1_General_CI_AS) AS Comments,

        o.OpportunityId,

        o.name AS opportunity,

        o.ActualCloseDate,

        ISNULL(New_IsConfidential, 1) AS IsConfidential,

        ieft.InternalEvaluationForTypeID AS EvaluatedforTypeValue

      FROM CRMReplication.dbo.new_opportunityevaluation evl

      INNER JOIN #evaluation_user_itemBase eu

        ON evl.new_opportunityevaluationid = eu.new_opportunityevaluationid

      INNER JOIN CRMReplication.dbo.Opportunity o

        ON o.opportunityid = evl.new_opportunityid
        AND o.ownerid <> eu.systemuserid
        AND (NOT ((o.New_ShareCreditId IS NOT NULL
        AND o.New_ShareCreditId = eu.systemuserid)
        OR (o.New_ShareCredit2Id IS NOT NULL
        AND o.New_ShareCredit2Id = eu.systemuserid)
        OR (o.New_ShareCredit3Id IS NOT NULL
        AND o.New_ShareCredit3Id = eu.systemuserid)
        OR (o.New_ShareCredit4Id IS NOT NULL
        AND o.New_ShareCredit4Id = eu.systemuserid)
        OR (o.New_ShareCredit5Id IS NOT NULL
        AND o.New_ShareCredit5Id = eu.systemuserid)))

        AND o.new_leaseadministratorid <> eu.systemuserid
        AND o.[New_SyndicationsManagerId] = eu.systemuserid
      INNER JOIN CRMReplication.dbo.AccountExtensionBase a

        ON a.AccountId = o.AccountID

      INNER JOIN CRMReplication.dbo.SystemUserBase sb

        ON sb.SystemUserId = eu.systemuserid


      INNER JOIN dbo.KeyStats_EvaluationTypes et
        ON et.EvaluationTypeID = 2
      INNER JOIN dbo.KeyStats_InternalEvaluationForTypes ieft
        ON ieft.InternalEvaluationForTypeID = 4
      WHERE evl.new_rating IS NOT NULL


    UPDATE #Evaluation
    SET evaluateforname = 'Shumaker, Dan'
    WHERE evaluateforname = 'Shumaker, Danal'

    TRUNCATE TABLE dbo.KeyStats_EmployeeEvaluation_DailySnapShot
    INSERT INTO dbo.KeyStats_EmployeeEvaluation_DailySnapShot (EvaluationTypeValue, [EvaluationType]
    , [EvaluatedByType]
    , [EvaluatedByID]
    , [EvaluatedByName]
    , [EvaluateForType]
    , [EvaluateForID]
    , [EvaluateForName]
    , [Rating]
    , [Comments]
    , [OpportunityID]
    , [Opportunity]
    , [ActualCloseDate]
    , [IsConfidential], [EvaluateForTypeValue])
      SELECT
        *
      FROM #Evaluation

  END
  ELSE
  BEGIN




    DECLARE @BeginDate_t AS datetime

    SET @BeginDate_t = @BeginDate

    DECLARE @ENDDATE_t AS datetime

    SET @ENDDATE_t = @ENDDATE


    IF OBJECT_ID('tempdb..#Evaluation_All') IS NOT NULL
      DROP TABLE #Evaluation_All

    SELECT
      ev.*,
      'ECS\' + t.username AS domainname,
      efr.EvaluationForTypeID INTO #Evaluation_All
    FROM KeyStats_EmployeeEvaluation_DailySnapShot ev
    INNER JOIN dbo.KeyStats_EvaluationForType_Relationship efr
      ON efr.EvaluationTypeID = ev.EvaluationTypeValue
      AND ev.EvaluateForTypeValue = efr.Vendor_Lessee_Evaluation_EvaluatedForType

    INNER JOIN Intranet_Beaconfunding.dbo.tblUsers t
      ON t.lname + ', ' + t.fname = ev.evaluateforname
    INNER JOIN dbo.KeyStats_AllEmployees e
      ON t.username = e.username
    INNER JOIN dbo.KeyStats_Category_Employee_Relation r
      ON r.CompanyID = e.Company
      AND r.EmployeeID = e.UserID
    INNER JOIN dbo.KeyStats_Categories c
      ON c.CategoryID = r.CategoryID
      AND efr.KeyStatsCategoryID = c.CategoryID
    WHERE efr.KeyStatsCategoryID = @GroupNo
    AND ev.EvaluationTypeValue = 1
    AND actualclosedate >= @BEGINDATE_t
    AND actualclosedate <= @ENDDATE_t

    UNION ALL
    SELECT
      ev.*,
      'ECS\' + t.username AS domainname,
      efr.EvaluationForTypeID
    FROM KeyStats_EmployeeEvaluation_DailySnapShot ev
    INNER JOIN dbo.KeyStats_EvaluationForType_Relationship efr
      ON efr.EvaluationTypeID = ev.EvaluationTypeValue
      AND ev.EvaluateForTypeValue = efr.InternalEvaluationForType

    INNER JOIN Intranet_Beaconfunding.dbo.tblUsers t
      ON t.lname + ', ' + t.fname = ev.evaluateforname
    INNER JOIN dbo.KeyStats_AllEmployees e
      ON t.username = e.username
    INNER JOIN dbo.KeyStats_Category_Employee_Relation r
      ON r.CompanyID = e.Company
      AND r.EmployeeID = e.UserID
    INNER JOIN dbo.KeyStats_Categories c
      ON c.CategoryID = r.CategoryID
      AND efr.KeyStatsCategoryID = c.CategoryID

    WHERE efr.KeyStatsCategoryID = @GroupNo
    AND ev.EvaluationTypeValue = 2
    AND actualclosedate >= @BEGINDATE_t
    AND actualclosedate <= @ENDDATE_t

    SELECT
      *
    FROM #Evaluation_All


    IF OBJECT_ID('tempdb..#Evaluation_EMP') IS NOT NULL
      DROP TABLE #Evaluation_EMP

    SELECT
      e.LName + ', ' + e.FName AS fullname,
      e.UserID,
      R.IsMiscellaneous,
      e.CRMGuid,
      eva.rating AS AvgEvaluationRating,

      eva.ratingCount AS AvgEvaluationRatingCount,

      evaIn.rating AS AvgEvaluationRatingIn,

      evaIn.ratingCount AS AvgEvaluationRatingCountIn,

      evaExt.rating AS AvgEvaluationRatingExt,

      evaExt.ratingCount AS AvgEvaluationRatingCountExt INTO #Evaluation_EMP
    FROM dbo.KeyStats_AllEmployees e --on  t.username=e.username 
    INNER JOIN dbo.KeyStats_Category_Employee_Relation r
      ON r.CompanyID = e.Company
      AND r.EmployeeID = e.UserID
    INNER JOIN dbo.KeyStats_Categories c
      ON c.CategoryID = r.CategoryID
    LEFT JOIN (SELECT
      EvaluateForID,
      EvaluateForName,
      AVG(CAST(rating AS float)) AS rating,
      COUNT(*) AS ratingCount
    FROM #Evaluation_All

    GROUP BY EvaluateForID,

             EvaluateForName) eva

      ON e.LName + ', ' + e.FName = eva.EvaluateForName

    LEFT JOIN (SELECT

      EvaluateForID,

      EvaluateForName,

      AVG(CAST(rating AS float)) AS rating,

      COUNT(*) AS ratingCount

    FROM #Evaluation_All

    WHERE evaluationtype = 'Internal'

    GROUP BY EvaluateForID,

             EvaluateForName) evaIn

      ON e.LName + ', ' + e.FName = evaIn.EvaluateForName

    LEFT JOIN (SELECT

      EvaluateForID,

      EvaluateForName,

      AVG(CAST(rating AS float)) AS rating,

      COUNT(*) AS ratingCount

    FROM #Evaluation_All

    WHERE evaluationtype = 'Client'

    GROUP BY EvaluateForID,

             EvaluateForName) evaExt

      ON e.LName + ', ' + e.FName = evaExt.EvaluateForName
    WHERE c.CategoryID = @GroupNo

    SELECT
      *
    FROM #Evaluation_EMP
    WHERE IsMiscellaneous = 0

    /* TABLE 3 - BFC AVG EVALUATION FOR GROUP */
    SELECT
      AVG(AvgEvaluationRating) AS AvgEvaluationRating,
      AVG(AvgEvaluationRatingCount) AS AvgEvaluationRatingCount,
      AVG(AvgEvaluationRatingIn) AS AvgEvaluationRatingIn,
      AVG(AvgEvaluationRatingCountIn) AS AvgEvaluationRatingCountIn,
      AVG(AvgEvaluationRatingExt) AS AvgEvaluationRatingExt,
      AVG(AvgEvaluationRatingCountExt) AS AvgEvaluationRatingCountExt
    FROM #Evaluation_EMP
    WHERE IsMiscellaneous = 0
    /* TABLE 3 - BFC AVG EVALUATION FOR GROUP */

    /* TABLE 4 - MISCELLANEOUS EVALUATION FOR GROUP */
    SELECT
      AVG(AvgEvaluationRating) AS AvgEvaluationRating,
      AVG(AvgEvaluationRatingCount) AS AvgEvaluationRatingCount,
      AVG(AvgEvaluationRatingIn) AS AvgEvaluationRatingIn,
      AVG(AvgEvaluationRatingCountIn) AS AvgEvaluationRatingCountIn,
      AVG(AvgEvaluationRatingExt) AS AvgEvaluationRatingExt,
      AVG(AvgEvaluationRatingCountExt) AS AvgEvaluationRatingCountExt
    FROM #Evaluation_EMP
    WHERE IsMiscellaneous = 1
  /* TABLE 4 - MISCELLANEOUS EVALUATION FOR GROUP */
  END
END
GO
