CREATE TABLE [control].[PipelineAuthLink]
	(
	[AuthId] [int] IDENTITY(1,1) NOT NULL,
	[PipelineId] [int] NOT NULL,
	[OrchestratorId] [int] NOT NULL,
	[CredentialId] [int] NOT NULL,
	CONSTRAINT [PK_PipelineAuthLink] PRIMARY KEY CLUSTERED ([AuthId] ASC),
	CONSTRAINT [FK_PipelineAuthLink_Orchestrators] FOREIGN KEY([OrchestratorId]) REFERENCES [control].[Orchestrators] ([OrchestratorId]),
	CONSTRAINT [FK_PipelineAuthLink_Pipelines] FOREIGN KEY([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]),
	CONSTRAINT [FK_PipelineAuthLink_ServicePrincipals] FOREIGN KEY([CredentialId]) REFERENCES [dbo].[ServicePrincipals] ([CredentialId])
	);