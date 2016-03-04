CREATE TABLE [dbo].[KeyStats_Employee_TestScore]
(
[UniqueUserId] [int] NOT NULL,
[ApplicationID] [int] NULL,
[FirstName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastNmae] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TestDate] [date] NULL,
[MathTest] [tinyint] NULL,
[MathTestAttempt] [tinyint] NULL,
[ProofReadingTestA] [tinyint] NULL,
[ProofReadingTestAAttempt] [tinyint] NULL,
[ProofReadingTestB] [tinyint] NULL,
[ProofReadingTestBAttepmt] [tinyint] NULL,
[TypingTestWPM] [tinyint] NULL,
[TypingTestAccuracy] [tinyint] NULL,
[TypingTestKeyStrokes] [int] NULL,
[BeaconScore] [smallint] NULL,
[FicoScore] [smallint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[KeyStats_Employee_TestScore] ADD CONSTRAINT [pk_UniqueUserId] PRIMARY KEY CLUSTERED  ([UniqueUserId]) ON [PRIMARY]
GO
