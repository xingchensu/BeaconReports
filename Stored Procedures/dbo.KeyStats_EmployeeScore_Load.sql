SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      Ruonan
-- Create date: 5/14/2015
-- Description:	load all evaluation
-- =============================================
--[dbo].[KeyStats_EmployeeScore_Load]2
create PROCEDURE [dbo].[KeyStats_EmployeeScore_Load]--2
@groupNo AS int
AS
BEGIN

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

  WHERE t.rn = 1


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

  WHERE t.rn = 1


  IF OBJECT_ID('tempdb..#SCORE') IS NOT NULL
    DROP TABLE #SCORE


  SELECT
    e.UserID,
    e.LName + ', ' + e.FName AS fullname,
	e.CRMGuid,
      S.*,
    sft.[overall results],
    sft.[result file link],

    bs.beacon_score,
    fs.fico_score,
    r.IsMiscellaneous INTO #SCORE
  FROM dbo.KeyStats_AllEmployees e
  INNER JOIN dbo.KeyStats_Category_Employee_Relation r
    ON r.CompanyID = e.Company
    AND r.EmployeeID = e.UserID
  INNER JOIN dbo.KeyStats_Categories c
    ON c.CategoryID = r.CategoryID
    left join dbo.KeyStats_Employee_TestScore s
        on s.UniqueUserId=e.UniqueUserId   
          LEFT JOIN LINK_BFCSQL02.CareersDB.dbo.Tbl_CareersDB_SalesFitTest_Employee_Score sft
    ON e.CRMGuid = sft.UserGuid

    
    
  --LEFT JOIN #TestScore t
  --  ON t.domainname = 'ecs\' + e.username
  LEFT JOIN #BeaconScore bs
    ON e.LName + ', ' + e.FName = bs.fullname
    AND e.dob = bs.date_of_birth
  LEFT JOIN #ficoscore fs
    ON e.LName + ', ' + e.FName = fs.fullname
    AND e.dob = fs.date_of_birth
  WHERE c.CategoryID = @groupNo

  SELECT
    *
  FROM #SCORE
  WHERE IsMiscellaneous = 0

  --BFC AVG
  SELECT
    AVG([MATH TEST]) AS [MATH TEST],
    AVG([MATH TEST ATTEMPT]) AS [MATH TEST ATTEMPT],
    AVG([PROOF READING TEST A]) AS [PROOF READING TEST A],
    AVG([PROOF READING TEST A ATTEMPT]) AS [PROOF READING TEST A ATTEMPT],
    AVG([PROOF READING TEST B]) AS [PROOF READING TEST B],
    AVG([Proof Reading Test B Attepmt]) AS [Proof Reading Test B Attepmt],
    AVG([TYPING TEST - WPM]) AS [TYPING TEST - WPM],
    AVG([TYPING TEST - ACCURACY]) AS [TYPING TEST - ACCURACY],
    AVG([TypingTest KeyStrokes]) AS [TypingTest KeyStrokes],
    AVG([overall results]) AS [overall results],
    AVG([BEACON_SCORE]) AS [BEACON_SCORE],
    AVG([FICO_SCORE]) AS [FICO_SCORE]
  FROM #SCORE
  WHERE IsMiscellaneous = 0

  --MISCELLANEOUS

  SELECT
    AVG([MATH TEST]) AS [MATH TEST],
    AVG([MATH TEST ATTEMPT]) AS [MATH TEST ATTEMPT],
    AVG([PROOF READING TEST A]) AS [PROOF READING TEST A],
    AVG([PROOF READING TEST A ATTEMPT]) AS [PROOF READING TEST A ATTEMPT],
    AVG([PROOF READING TEST B]) AS [PROOF READING TEST B],
    AVG([Proof Reading Test B Attepmt]) AS [Proof Reading Test B Attepmt],
    AVG([TYPING TEST - WPM]) AS [TYPING TEST - WPM],
    AVG([TYPING TEST - ACCURACY]) AS [TYPING TEST - ACCURACY],
    AVG([TypingTest KeyStrokes]) AS [TypingTest KeyStrokes],
    AVG([overall results]) AS [overall results],
    AVG([BEACON_SCORE]) AS [BEACON_SCORE],
    AVG([FICO_SCORE]) AS [FICO_SCORE]
  FROM #SCORE
  WHERE IsMiscellaneous = 1
END
GO
