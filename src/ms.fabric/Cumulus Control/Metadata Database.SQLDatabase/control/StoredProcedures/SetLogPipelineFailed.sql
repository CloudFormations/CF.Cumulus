
	CREATE PROCEDURE [control].[SetLogPipelineFailed]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@RunId UNIQUEIDENTIFIER = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorDetail VARCHAR(500)

		--mark specific failure pipeline
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = 'Failed'
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId

		--persist failed pipeline records to long term log
		INSERT INTO [control].[ExecutionLog]
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
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
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
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
		FROM
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [PipelineStatus] = 'Failed'
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;
		
		IF ([control].[GetPropertyValueInternal]('FailureHandling')) = 'None'
			BEGIN
				--do nothing allow processing to carry on regardless
				RETURN 0;
			END;
			
		ELSE IF ([control].[GetPropertyValueInternal]('FailureHandling')) = 'Simple'
			BEGIN
				--flag all downstream stages as blocked
				UPDATE
					[control].[CurrentExecution]
				SET
					[PipelineStatus] = 'Blocked',
					[IsBlocked] = 1
				WHERE
					[LocalExecutionId] = @ExecutionId
					AND [StageId] > @StageId
				
				--raise error to stop processing
				IF @RunId IS NOT NULL
					BEGIN
						SET @ErrorDetail = 'Pipeline execution failed. Check Run ID: ' + CAST(@RunId AS CHAR(36)) + ' in ADF monitoring for details.'
					END;
				ELSE
					BEGIN
						SET @ErrorDetail = 'Pipeline execution failed. See ADF monitoring for details.'
					END;

				--update batch if applicable
				IF ([control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
					BEGIN
						UPDATE
							[control].[BatchExecution]
						SET
							[BatchStatus] = 'Stopping'
						WHERE
							[ExecutionId] = @ExecutionId
							AND [BatchStatus] = 'Running';
					END;

				RAISERROR(@ErrorDetail,16,1);
				RETURN 0;
			END;
		
		ELSE IF ([control].[GetPropertyValueInternal]('FailureHandling')) = 'DependencyChain'
			BEGIN
				EXEC [control].[SetExecutionBlockDependants]
					@ExecutionId = @ExecutionId,
					@PipelineId = @PipelineId
			END;
		ELSE
			BEGIN
				RAISERROR('Unknown failure handling state.',16,1);
				RETURN 0;
			END;
	END;

GO

