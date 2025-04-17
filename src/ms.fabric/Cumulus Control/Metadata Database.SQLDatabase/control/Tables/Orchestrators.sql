CREATE TABLE [control].[Orchestrators] (
    [OrchestratorId]          INT              IDENTITY (1, 1) NOT NULL,
    [OrchestratorName]        NVARCHAR (200)   NOT NULL,
    [OrchestratorType]        CHAR (3)         NOT NULL,
    [IsFrameworkOrchestrator] BIT              DEFAULT ((0)) NOT NULL,
    [ResourceGroupName]       NVARCHAR (200)   NOT NULL,
    [SubscriptionId]          UNIQUEIDENTIFIER NOT NULL,
    [Description]             NVARCHAR (MAX)   NULL,
    CONSTRAINT [PK_Orchestrators] PRIMARY KEY CLUSTERED ([OrchestratorId] ASC),
    CONSTRAINT [OrchestratorType] CHECK ([OrchestratorType]='SYN' OR [OrchestratorType]='ADF' OR [OrchestratorType]='FAB'),
    CONSTRAINT [FK_Orchestrators_Subscriptions] FOREIGN KEY ([SubscriptionId]) REFERENCES [control].[Subscriptions] ([SubscriptionId])
);


GO

