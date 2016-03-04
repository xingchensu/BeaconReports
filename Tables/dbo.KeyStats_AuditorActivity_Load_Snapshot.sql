CREATE TABLE [dbo].[KeyStats_AuditorActivity_Load_Snapshot]
(
[userName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reportDate] [datetime] NULL,
[monthDate] [tinyint] NOT NULL,
[yearDate] [smallint] NOT NULL,
[hoursTotal] [tinyint] NOT NULL,
[hourlyPay] [decimal] (10, 2) NULL,
[products] [float] NULL,
[characters] [float] NULL,
[internal_isAudit] [bit] NOT NULL,
[internal_isPopularCleanUp] [bit] NOT NULL,
[internal_isCleanUp] [bit] NOT NULL,
[isActive] [bit] NULL,
[startDate] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Temp_KeyS__FName__1DC70F96] DEFAULT (''),
[LName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Temp_KeyS__LName__1EBB33CF] DEFAULT ('')
) ON [PRIMARY]
GO
