CREATE PROCEDURE [cumulus.control].[ResetExecution]
	(
	@LocalExecutionId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN 
	SET NOCOUNT	ON;

	IF([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '0'
		BEGIN
			--capture any pipelines that might be in an unexpected state
			INSERT INTO [cumulus.control].[ExecutionLog]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				[PipelineStatus],
				[EndDateTime]
				)
			SELECT
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				'Unknown',
				[EndDateTime]
			FROM
				[cumulus.control].[CurrentExecution]
			WHERE
				--these are predicted states
				[PipelineStatus] NOT IN
					(
					'Success',
					'Failed',
					'Blocked',
					'Cancelled'
					);
		
			--reset status ready for next attempt
			UPDATE
				[cumulus.control].[CurrentExecution]
			SET
				[StartDateTime] = NULL,
				[EndDateTime] = NULL,
				[PipelineStatus] = NULL,
				[LastStatusCheckDateTime] = NULL,
				[PipelineRunId] = NULL,
				[PipelineParamsUsed] = NULL,
				[IsBlocked] = 0
			WHERE
				ISNULL([PipelineStatus],'') <> 'Success'
				OR [IsBlocked] = 1;
	
			--return current execution id
			SELECT DISTINCT
				[LocalExecutionId] AS ExecutionId
			FROM
				[cumulus.control].[CurrentExecution];
		END
	ELSE IF ([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
		BEGIN
			--capture any pipelines that might be in an unexpected state
			INSERT INTO [cumulus.control].[ExecutionLog]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				[PipelineStatus],
				[EndDateTime]
				)
			SELECT
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				'Unknown',
				[EndDateTime]
			FROM
				[cumulus.control].[CurrentExecution]
			WHERE
				[LocalExecutionId] = @LocalExecutionId
				--these are predicted states
				AND [PipelineStatus] NOT IN
					(
					'Success',
					'Failed',
					'Blocked',
					'Cancelled'
					);
		
			--reset status ready for next attempt
			UPDATE
				[cumulus.control].[CurrentExecution]
			SET
				[StartDateTime] = NULL,
				[EndDateTime] = NULL,
				[PipelineStatus] = NULL,
				[LastStatusCheckDateTime] = NULL,
				[PipelineRunId] = NULL,
				[PipelineParamsUsed] = NULL,
				[IsBlocked] = 0
			WHERE
				[LocalExecutionId] = @LocalExecutionId
				AND ISNULL([PipelineStatus],'') <> 'Success'
				OR [IsBlocked] = 1;
				
			UPDATE
				[cumulus.control].[BatchExecution]
			SET
				[EndDateTime] = NULL,
				[BatchStatus] = 'Running'
			WHERE
				[ExecutionId] = @LocalExecutionId;

			SELECT 
				@LocalExecutionId AS ExecutionId
		END;
END;