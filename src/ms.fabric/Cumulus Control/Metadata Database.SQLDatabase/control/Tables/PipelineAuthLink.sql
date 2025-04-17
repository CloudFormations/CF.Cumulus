CREATE TABLE [control].[PipelineAuthLink] (
    [AuthId]         INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]     INT NOT NULL,
    [OrchestratorId] INT NOT NULL,
    [CredentialId]   INT NOT NULL,
    CONSTRAINT [PK_PipelineAuthLink] PRIMARY KEY CLUSTERED ([AuthId] ASC),
    CONSTRAINT [FK_PipelineAuthLink_Orchestrators] FOREIGN KEY ([OrchestratorId]) REFERENCES [control].[Orchestrators] ([OrchestratorId]),
    CONSTRAINT [FK_PipelineAuthLink_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]),
    CONSTRAINT [FK_PipelineAuthLink_ServicePrincipals] FOREIGN KEY ([CredentialId]) REFERENCES [dbo].[ServicePrincipals] ([CredentialId])
);


GO

