CREATE TABLE [control].[ExecutionLog] (
    [LogId]                   INT              IDENTITY (1, 1) NOT NULL,
    [LocalExecutionId]        UNIQUEIDENTIFIER NOT NULL,
    [StageId]                 INT              NOT NULL,
    [PipelineId]              INT              NOT NULL,
    [CallingOrchestratorName] NVARCHAR (200)   DEFAULT ('Unknown') NOT NULL,
    [ResourceGroupName]       NVARCHAR (200)   DEFAULT ('Unknown') NOT NULL,
    [OrchestratorType]        CHAR (3)         DEFAULT ('N/A') NOT NULL,
    [OrchestratorName]        NVARCHAR (200)   DEFAULT ('Unknown') NOT NULL,
    [PipelineName]            NVARCHAR (200)   NOT NULL,
    [StartDateTime]           DATETIME         NULL,
    [PipelineStatus]          NVARCHAR (200)   NULL,
    [EndDateTime]             DATETIME         NULL,
    [PipelineRunId]           UNIQUEIDENTIFIER NULL,
    [PipelineParamsUsed]      NVARCHAR (MAX)   DEFAULT ('None') NULL,
    CONSTRAINT [PK_ExecutionLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO

