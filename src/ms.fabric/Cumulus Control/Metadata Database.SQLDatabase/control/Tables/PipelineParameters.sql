CREATE TABLE [control].[PipelineParameters] (
    [ParameterId]            INT            IDENTITY (1, 1) NOT NULL,
    [PipelineId]             INT            NOT NULL,
    [ParameterName]          VARCHAR (128)  NOT NULL,
    [ParameterValue]         NVARCHAR (MAX) NULL,
    [ParameterValueLastUsed] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_PipelineParameters] PRIMARY KEY CLUSTERED ([ParameterId] ASC),
    CONSTRAINT [FK_PipelineParameters_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId])
);


GO

