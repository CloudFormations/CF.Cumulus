CREATE TABLE [control].[ErrorLog] (
    [LogId]            INT              IDENTITY (1, 1) NOT NULL,
    [LocalExecutionId] UNIQUEIDENTIFIER NOT NULL,
    [PipelineRunId]    UNIQUEIDENTIFIER NOT NULL,
    [ActivityRunId]    UNIQUEIDENTIFIER NOT NULL,
    [ActivityName]     VARCHAR (100)    NOT NULL,
    [ActivityType]     VARCHAR (100)    NOT NULL,
    [ErrorCode]        VARCHAR (100)    NOT NULL,
    [ErrorType]        VARCHAR (100)    NOT NULL,
    [ErrorMessage]     NVARCHAR (MAX)   NULL,
    CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO

