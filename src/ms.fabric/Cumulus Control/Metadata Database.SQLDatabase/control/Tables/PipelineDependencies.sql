CREATE TABLE [control].[PipelineDependencies] (
    [DependencyId]        INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]          INT NOT NULL,
    [DependantPipelineId] INT NOT NULL,
    CONSTRAINT [PK_PipelineDependencies] PRIMARY KEY CLUSTERED ([DependencyId] ASC),
    CONSTRAINT [EQ_PipelineIdDependantPipelineId] CHECK ([PipelineId]<>[DependantPipelineId]),
    CONSTRAINT [FK_PipelineDependencies_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]),
    CONSTRAINT [FK_PipelineDependencies_Pipelines1] FOREIGN KEY ([DependantPipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]),
    CONSTRAINT [UK_PipelinesToDependantPipelines] UNIQUE NONCLUSTERED ([PipelineId] ASC, [DependantPipelineId] ASC)
);


GO

