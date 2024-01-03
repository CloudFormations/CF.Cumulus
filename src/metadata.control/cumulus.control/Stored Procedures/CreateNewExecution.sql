CREATE PROCEDURE [cumulus.control].[CreateNewExecution]
	(
	@CallingOrchestratorName NVARCHAR(200),
	@LocalExecutionId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @BatchId UNIQUEIDENTIFIER;

	IF([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '0'
		BEGIN
			SET @LocalExecutionId = NEWID();

			TRUNCATE TABLE [cumulus.control].[CurrentExecution];

			--defensive check
			IF NOT EXISTS
				(
				SELECT
					1
				FROM
					[cumulus.control].[Pipelines] p
					INNER JOIN [cumulus.control].[Stages] s
						ON p.[StageId] = s.[StageId]
					INNER JOIN [cumulus.control].[Orchestrators] d
						ON p.[OrchestratorId] = d.[OrchestratorId]
				WHERE
					p.[Enabled] = 1
					AND s.[Enabled] = 1
				)
				BEGIN
					RAISERROR('Requested execution run does not contain any enabled stages/pipelines.',16,1);
					RETURN 0;
				END;

			INSERT INTO [cumulus.control].[CurrentExecution]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName]
				)
			SELECT
				@LocalExecutionId,
				p.[StageId],
				p.[PipelineId],
				@CallingOrchestratorName,
				d.[ResourceGroupName],
				d.[OrchestratorType],
				d.[OrchestratorName],
				p.[PipelineName]
			FROM
				[cumulus.control].[Pipelines] p
				INNER JOIN [cumulus.control].[Stages] s
					ON p.[StageId] = s.[StageId]
				INNER JOIN [cumulus.control].[Orchestrators] d
					ON p.[OrchestratorId] = d.[OrchestratorId]
			WHERE
				p.[Enabled] = 1
				AND s.[Enabled] = 1;

			SELECT
				@LocalExecutionId AS ExecutionId;
		END
	ELSE IF ([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
		BEGIN
			DELETE FROM 
				[cumulus.control].[CurrentExecution]
			WHERE
				[LocalExecutionId] = @LocalExecutionId;

			SELECT
				@BatchId = [BatchId]
			FROM
				[cumulus.control].[BatchExecution]
			WHERE
				[ExecutionId] = @LocalExecutionId;
			
			--defensive check
			IF NOT EXISTS
				(
				SELECT
					1
				FROM
					[cumulus.control].[Pipelines] p
					INNER JOIN [cumulus.control].[Stages] s
						ON p.[StageId] = s.[StageId]
					INNER JOIN [cumulus.control].[Orchestrators] d
						ON p.[OrchestratorId] = d.[OrchestratorId]
					INNER JOIN [cumulus.control].[BatchStageLink] b
						ON b.[StageId] = s.[StageId]
				WHERE
					b.[BatchId] = @BatchId
					AND p.[Enabled] = 1
					AND s.[Enabled] = 1
				)
				BEGIN
					RAISERROR('Requested execution run does not contain any enabled stages/pipelines.',16,1);
					RETURN 0;
				END;

			INSERT INTO [cumulus.control].[CurrentExecution]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName]
				)
			SELECT
				@LocalExecutionId,
				p.[StageId],
				p.[PipelineId],
				@CallingOrchestratorName,
				d.[ResourceGroupName],
				d.[OrchestratorType],
				d.[OrchestratorName],
				p.[PipelineName]
			FROM
				[cumulus.control].[Pipelines] p
				INNER JOIN [cumulus.control].[Stages] s
					ON p.[StageId] = s.[StageId]
				INNER JOIN [cumulus.control].[Orchestrators] d
					ON p.[OrchestratorId] = d.[OrchestratorId]
				INNER JOIN [cumulus.control].[BatchStageLink] b
					ON b.[StageId] = s.[StageId]
			WHERE
				b.[BatchId] = @BatchId
				AND p.[Enabled] = 1
				AND s.[Enabled] = 1;
				
			SELECT
				@LocalExecutionId AS ExecutionId;
		END;

	ALTER INDEX [IDX_GetPipelinesInStage] ON [cumulus.control].[CurrentExecution]
	REBUILD;
END;