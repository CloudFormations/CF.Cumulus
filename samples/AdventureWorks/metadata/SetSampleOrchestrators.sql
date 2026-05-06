CREATE PROCEDURE [samples].[SetSampleOrchestrators]
AS
BEGIN
	DECLARE @Orchestrators TABLE 
		(
		[OrchestratorName] NVARCHAR(200) NOT NULL,
		[OrchestratorType] CHAR(3) NOT NULL,
		[IsFrameworkOrchestrator] BIT NOT NULL,
		[ResourceGroupName] NVARCHAR(200) NOT NULL,
		[SubscriptionId] UNIQUEIDENTIFIER NOT NULL,
		[Description] NVARCHAR(MAX) NULL
		)
	
	INSERT INTO @Orchestrators
		(
		[OrchestratorName],
		[OrchestratorType],
		[IsFrameworkOrchestrator],
		[Description],
		[ResourceGroupName],
		[SubscriptionId]
		)
	VALUES
		('FrameworkDataFactory','ADF',1,'Example Data Factory used for development.','CF.Cumulus.Samples','subscriptionID-12345678-1234-1234-1234-012345678910'),
		('WorkersDataFactory','ADF',0,'Example Data Factory used to house worker pipelines.','CF.Cumulus.Samples','subscriptionID-12345678-1234-1234-1234-012345678910');

	MERGE INTO [control].[Orchestrators] AS tgt
	USING 
		@Orchestrators AS src
			ON tgt.[OrchestratorName] = src.[OrchestratorName]
				AND tgt.[OrchestratorType] = src.[OrchestratorType]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[IsFrameworkOrchestrator] = src.[IsFrameworkOrchestrator],
			tgt.[Description] = src.[Description],
			tgt.[ResourceGroupName] = src.[ResourceGroupName],
			tgt.[SubscriptionId] = src.[SubscriptionId]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[OrchestratorName],
			[OrchestratorType],
			[IsFrameworkOrchestrator],
			[Description],
			[ResourceGroupName],
			[SubscriptionId]
			)
		VALUES
			(
			src.[OrchestratorName],
			src.[OrchestratorType],
			src.[IsFrameworkOrchestrator],
			src.[Description],
			src.[ResourceGroupName],
			src.[SubscriptionId]
			)
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE;
END;