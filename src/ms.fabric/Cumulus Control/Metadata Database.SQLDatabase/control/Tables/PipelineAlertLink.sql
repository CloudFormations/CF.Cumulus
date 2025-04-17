CREATE TABLE [control].[PipelineAlertLink] (
    [AlertId]          INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]       INT NOT NULL,
    [RecipientId]      INT NOT NULL,
    [OutcomesBitValue] INT NOT NULL,
    [Enabled]          BIT DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_PipelineAlertLink] PRIMARY KEY CLUSTERED ([AlertId] ASC),
    CONSTRAINT [FK_PipelineAlertLink_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]),
    CONSTRAINT [FK_PipelineAlertLink_Recipients] FOREIGN KEY ([RecipientId]) REFERENCES [control].[Recipients] ([RecipientId])
);


GO

