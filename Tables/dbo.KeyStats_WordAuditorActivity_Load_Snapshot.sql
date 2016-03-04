CREATE TABLE [dbo].[KeyStats_WordAuditorActivity_Load_Snapshot]
(
[userName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reportDate] [datetime] NULL,
[workHours] [float] NULL,
[expectedWorkHours] [decimal] (10, 2) NULL,
[hourlyPay] [decimal] (10, 2) NULL,
[workedHoursPay] AS ([workHours]*[hourlyPay]) PERSISTED,
[designsHours] [decimal] (10, 2) NULL,
[noOfDesigns] [int] NULL,
[noOfCharacters] [int] NULL,
[keywordCleanupHours] [decimal] (10, 2) NULL,
[noOfDesignsCleaned] [int] NULL,
[_20orLessKeywordHours] [decimal] (10, 2) NULL,
[_20orLessDesignsCleaned] [int] NULL,
[fName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
