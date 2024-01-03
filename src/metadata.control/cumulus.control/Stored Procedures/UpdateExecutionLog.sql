CREATE PROCEDURE [cumulus.control].[UpdateExecutionLog]
	(
	@PerformErrorCheck BIT = 1,
	@ExecutionId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @AllCount INT
	DECLARE @SuccessCount INT

	IF([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '0'
		BEGIN
			IF @PerformErrorCheck = 1
			BEGIN
				--Check current execution
				SELECT @AllCount = COUNT(0) FROM [cumulus.control].[CurrentExecution]
				SELECT @SuccessCount = COUNT(0) FROM [cumulus.control].[CurrentExecution] WHERE [PipelineStatus] = 'Success'

				IF @AllCount <> @SuccessCount
					BEGIN
						RAISERROR('Framework execution complete but not all Worker pipelines succeeded. See the [cumulus.control].[CurrentExecution] table for details',16,1);
						RETURN 0;
					END;
			END;

			--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
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
				[cumulus.control].[CurrentExecution];

			TRUNCATE TABLE [cumulus.control].[CurrentExecution];
		END
	ELSE IF ([cumulus.control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
		BEGIN
			IF @PerformErrorCheck = 1
			BEGIN
				--Check current execution
				SELECT 
					@AllCount = COUNT(0) 
				FROM 
					[cumulus.control].[CurrentExecution] 
				WHERE 
					[LocalExecutionId] = @ExecutionId;
				
				SELECT 
					@SuccessCount = COUNT(0) 
				FROM 
					[cumulus.control].[CurrentExecution] 
				WHERE 
					[LocalExecutionId] = @ExecutionId 
					AND [PipelineStatus] = 'Success';

				IF @AllCount <> @SuccessCount
					BEGIN
						UPDATE
							[cumulus.control].[BatchExecution]
						SET
							[BatchStatus] = 'Stopped',
							[EndDateTime] = GETUTCDATE()
						WHERE
							[ExecutionId] = @ExecutionId;
						
						RAISERROR('Framework execution complete for batch but not all Worker pipelines succeeded. See the [cumulus.control].[CurrentExecution] table for details',16,1);
						RETURN 0;
					END;
				ELSE
					BEGIN
						UPDATE
							[cumulus.control].[BatchExecution]
						SET
							[BatchStatus] = 'Success',
							[EndDateTime] = GETUTCDATE()
						WHERE
							[ExecutionId] = @ExecutionId;
					END;
			END; --end check

			--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
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
				[cumulus.control].[CurrentExecution]
			WHERE 
				[LocalExecutionId] = @ExecutionId;

			DELETE FROM
				[cumulus.control].[CurrentExecution]
			WHERE
				[LocalExecutionId] = @ExecutionId;
		END;
END;