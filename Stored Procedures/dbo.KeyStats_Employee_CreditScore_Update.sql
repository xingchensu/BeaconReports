SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ruonan Wen
-- Create date: 12/14/2015
-- Description:	sp update credit score in key stats test score table
-- =============================================
CREATE PROCEDURE [dbo].[KeyStats_Employee_CreditScore_Update]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#BeaconScore') IS NOT NULL

  BEGIN

    DROP TABLE #BeaconScore

  END

  SELECT
    date_of_birth,
    fullname,

    CAST(beacon_score AS int) AS beacon_score INTO #BeaconScore

  FROM (SELECT

    date_of_birth,
    ssn,

    CASE
      WHEN RTRIM([LName]) = 'HINES' AND
        RTRIM([FName]) = 'STEPHANIE' THEN 'Richards, Stephanie'

      WHEN RTRIM([LName]) = 'YOUNG' AND
        RTRIM([FName]) = 'SANDRA' THEN 'Young, Sandy'
      WHEN RTRIM([LName]) = 'Kilkenny' AND
        RTRIM([FName]) = 'Elizabeth' THEN 'Kilkenny, Liz'

      ELSE RTRIM([LName]) + ', ' + RTRIM([FName])
    END

    AS fullname,
    beacon_score,
    creditpulldate,

    ROW_NUMBER() OVER (PARTITION BY date_of_birth, ssn, fname, lname ORDER BY creditpulldate DESC) AS rn

  FROM LINK_WW02.[Beacon_Funding_CRMCredit].[dbo].[CREDIT_Equifax]) t

  WHERE t.rn = 1 and date_of_birth is not null


--select * from #BeaconScore where fullname='BARATTA, JON'
	
  IF OBJECT_ID('tempdb..#FicoScore') IS NOT NULL

  BEGIN

    DROP TABLE #FicoScore

  END

  SELECT
    date_of_birth,
    fullname,
    CASE
      WHEN ISNUMERIC(fico_score) = 1 THEN CAST(fico_score AS int)
      ELSE 0
    END AS fico_score INTO #FicoScore

  FROM (SELECT

    date_of_birth,
    ssn,

    CASE
      WHEN RTRIM([LName]) = 'HINES' AND
        RTRIM([FName]) = 'STEPHANIE' THEN 'Richards, Stephanie'

      WHEN RTRIM([LName]) = 'YOUNG' AND
        RTRIM([FName]) = 'SANDRA' THEN 'Young, Sandy'
      WHEN RTRIM([LName]) = 'Griffin' AND
        RTRIM([FName]) = 'Elizabeth' THEN 'Kilkenny, Liz'
      ELSE RTRIM([LName]) + ', ' + RTRIM([FName])
    END

    AS fullname,

    REPLACE(REPLACE(fico_score, '+', ''), '-', '') AS fico_score,
    creditpulldate,

    ROW_NUMBER() OVER (PARTITION BY date_of_birth, ssn, fname, lname ORDER BY creditpulldate DESC) AS rn

  FROM LINK_WW02.[Beacon_Funding_CRMCredit].[dbo].[CREDIT_TransUnion]) t
  WHERE t.rn = 1 and date_of_birth is not null
  
  update dbo.KeyStats_Employee_TestScore
  set [BeaconScore]=bs.beacon_score,
  [FicoScore]=fs.fico_score
  from dbo.KeyStats_Employee_TestScore ts
  left join  dbo.KeyStats_AllEmployees em
  on em. UniqueUserId=ts.UniqueUserId
	left join #FicoScore fs
	on em.LName+', '+em.FName=fs.fullname	
	and em.DOB=fs.date_of_birth
	left join #BeaconScore bs
	on em.LName+', '+em.FName=bs.fullname
	and em.DOB=bs.date_of_birth  

	
END
GO
