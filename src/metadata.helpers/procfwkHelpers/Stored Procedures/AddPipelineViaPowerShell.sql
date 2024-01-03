CREATE PROCEDURE [procfwkHelpers].[AddPipelineViaPowerShell]
	(
	@ResourceGroup NVARCHAR(200),
	@OrchestratorName NVARCHAR(200),
	@OrchestratorType CHAR(3) = 'ADF',
	@PipelineName NVARCHAR(200)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @OrchestratorId INT
	DECLARE @StageId INT
	DECLARE @StageName VARCHAR(255) = 'PoShAdded'

	--get/set orchestrator
	IF EXISTS
		(
		SELECT * FROM [control].[Orchestrators] WHERE [OrchestratorName] = @OrchestratorName AND [ResourceGroupName] = @ResourceGroup AND [OrchestratorType] = @OrchestratorType
		)
		BEGIN
			SELECT @OrchestratorId = [OrchestratorId] FROM [control].[Orchestrators] WHERE [OrchestratorName] = @OrchestratorName AND [ResourceGroupName] = @ResourceGroup AND [OrchestratorType] = @OrchestratorType;
		END
	ELSE
		BEGIN
			INSERT INTO [control].[Orchestrators]
				(
				[OrchestratorName],
				[OrchestratorType],
				[ResourceGroupName],
				[Description],
				[SubscriptionId]
				)
			VALUES
				(
				@OrchestratorName,
				@OrchestratorType,
				@ResourceGroup,
				'Added via PowerShell.',
				'12345678-1234-1234-1234-012345678910'
				)

			SELECT
				@OrchestratorId = SCOPE_IDENTITY();
		END

	--get/set stage
	IF EXISTS
		(
		SELECT * FROM [control].[Stages] WHERE [StageName] = @StageName
		)
		BEGIN
			SELECT @StageId = [StageId] FROM [control].[Stages] WHERE [StageName] = @StageName;
		END;
	ELSE
		BEGIN
			INSERT INTO [control].[Stages]
				(
				[StageName],
				[StageDescription],
				[Enabled]
				)
			VALUES
				(
				@StageName,
				'Added via PowerShell.',
				1
				);

			SELECT
				@StageId = SCOPE_IDENTITY();
		END;

	--upsert pipeline
	;WITH sourceData AS
		(
		SELECT
			@OrchestratorId AS OrchestratorId,
			@PipelineName AS PipelineName,
			@StageId AS StageId,
			NULL AS LogicalPredecessorId,
			1 AS [Enabled]
		)
	MERGE INTO [control].[Pipelines] AS tgt
	USING 
		sourceData AS src
			ON tgt.[OrchestratorId] = src.[OrchestratorId]
				AND tgt.[PipelineName] = src.[PipelineName]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[StageId] = src.[StageId],
			tgt.[LogicalPredecessorId] = src.[LogicalPredecessorId],
			tgt.[Enabled] = src.[Enabled]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[OrchestratorId],
			[StageId],
			[PipelineName], 
			[LogicalPredecessorId],
			[Enabled]
			)
		VALUES
			(
			src.[OrchestratorId],
			src.[StageId],
			src.[PipelineName], 
			src.[LogicalPredecessorId],
			src.[Enabled]
			);
END;
