CREATE PROCEDURE [control].[UpdateExecutionLog]
	(
	@PerformErrorCheck BIT = 1,
	@ExecutionId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @AllCount INT
	DECLARE @SuccessCount INT

	IF([control].[GetPropertyValueInternal]('UseExecutionBatches')) = '0'
		BEGIN
			IF @PerformErrorCheck = 1
			BEGIN
				--Check current execution
				SELECT @AllCount = COUNT(0) FROM [control].[CurrentExecution]
				SELECT @SuccessCount = COUNT(0) FROM [control].[CurrentExecution] WHERE [PipelineStatus] = 'Success'

				IF @AllCount <> @SuccessCount
					BEGIN
						RAISERROR('Framework execution complete but not all Worker pipelines succeeded. See the [control].[CurrentExecution] table for details',16,1);
						RETURN 0;
					END;
			END;

			--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
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
				[control].[CurrentExecution];

			TRUNCATE TABLE [control].[CurrentExecution];
		END
	ELSE IF ([control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
		BEGIN
			IF @PerformErrorCheck = 1
			BEGIN
				--Check current execution
				SELECT 
					@AllCount = COUNT(0) 
				FROM 
					[control].[CurrentExecution] 
				WHERE 
					[LocalExecutionId] = @ExecutionId;
				
				SELECT 
					@SuccessCount = COUNT(0) 
				FROM 
					[control].[CurrentExecution] 
				WHERE 
					[LocalExecutionId] = @ExecutionId 
					AND [PipelineStatus] = 'Success';

				IF @AllCount <> @SuccessCount
					BEGIN
						UPDATE
							[control].[BatchExecution]
						SET
							[BatchStatus] = 'Stopped',
							[EndDateTime] = GETUTCDATE()
						WHERE
							[ExecutionId] = @ExecutionId;
						
						RAISERROR('Framework execution complete for batch but not all Worker pipelines succeeded. See the [control].[CurrentExecution] table for details',16,1);
						RETURN 0;
					END;
				ELSE
					BEGIN
						UPDATE
							[control].[BatchExecution]
						SET
							[BatchStatus] = 'Success',
							[EndDateTime] = GETUTCDATE()
						WHERE
							[ExecutionId] = @ExecutionId;
					END;
			END; --end check

			--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
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
				[LocalExecutionId] = @ExecutionId;

			DELETE FROM
				[control].[CurrentExecution]
			WHERE
				[LocalExecutionId] = @ExecutionId;
		END;
END;