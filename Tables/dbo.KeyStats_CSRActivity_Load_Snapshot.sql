CREATE TABLE [dbo].[KeyStats_CSRActivity_Load_Snapshot]
(
[userName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[startDate] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activityDate] [datetime] NOT NULL,
[isMiscellaneouos] [bit] NULL,
[workHours] [float] NULL,
[noOfEmails] [int] NULL,
[noOfCalls] [int] NULL,
[noOfCDs] [int] NULL,
[noOfchats] [int] NULL,
[refundAmount] [float] NULL,
[refundCount] [smallint] NULL CONSTRAINT [DF__Temp_KeyS__refun__03482384] DEFAULT ((0)),
[hourlyPay] [decimal] (10, 2) NULL,
[workedHoursPay] [decimal] (10, 2) NULL,
[articles] [int] NULL,
[projects] [int] NULL,
[refundReview] [int] NULL,
[vendorReview] [int] NULL,
[expectedWorkHours] [decimal] (10, 2) NOT NULL CONSTRAINT [DF__Temp_KeyS__expec__1B1FAD15] DEFAULT ((0)),
[noOfUnAnsweredChats] [int] NULL,
[FName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userEmail] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avgChatDurationTime] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avgChatDuration] [float] NULL,
[avgFirstResponseTime] [float] NULL,
[avgResponseTime] [float] NULL,
[characterCountAgent] [int] NULL,
[characterCountVisitor] [int] NULL,
[avgChatRating] [float] NULL,
[noOfChatLeads] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_CSRActivity_Load_Snapshot] ADD CONSTRAINT [PK_KeyStats_CSRActivity_Load_Snapshot] PRIMARY KEY CLUSTERED  ([userName], [activityDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [NIdx_CSRActivity_ActivityDate] ON [dbo].[KeyStats_CSRActivity_Load_Snapshot] ([activityDate]) ON [PRIMARY]
GO
