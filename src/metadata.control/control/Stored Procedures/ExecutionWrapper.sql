﻿CREATE PROCEDURE [control].[ExecutionWrapper]
	(
	@CallingOrchestratorName NVARCHAR(200) = NULL,
	@BatchName VARCHAR(255) = NULL
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @RestartStatus BIT
	DECLARE @BatchId UNIQUEIDENTIFIER
	DECLARE @BLocalExecutionId UNIQUEIDENTIFIER --declared here for batches

	IF @CallingOrchestratorName IS NULL
		SET @CallingOrchestratorName = 'Unknown';

	--get restart overide property	
	SELECT @RestartStatus = [control].[GetPropertyValueInternal]('OverideRestart')

	IF([control].[GetPropertyValueInternal]('UseExecutionBatches')) = '0'
		BEGIN
			SET @BatchId = NULL;

			--check for running execution
			IF EXISTS
				(
				SELECT * FROM [control].[CurrentExecution] WHERE ISNULL([PipelineStatus],'') = 'Running'
				)
				BEGIN
					RAISERROR('There is already an execution run in progress. Stop this via the Orchestrator before restarting.',16,1);
					RETURN 0;
				END;	

			--reset and restart execution
			IF EXISTS
				(
				SELECT 1 FROM [control].[CurrentExecution] WHERE ISNULL([PipelineStatus],'') <> 'Success'
				) 
				AND @RestartStatus = 0
				BEGIN
					EXEC [control].[ResetExecution]
				END
			--capture failed execution and run new anyway
			ELSE IF EXISTS
				(
				SELECT 1 FROM [control].[CurrentExecution]
				)
				AND @RestartStatus = 1
				BEGIN
					EXEC [control].[UpdateExecutionLog]
						@PerformErrorCheck = 0; --Special case when OverideRestart = 1;

					EXEC [control].[CreateNewExecution] 
						@CallingOrchestratorName = @CallingOrchestratorName
				END
			--no restart considerations, just create new execution
			ELSE
				BEGIN
					EXEC [control].[CreateNewExecution] 
						@CallingOrchestratorName = @CallingOrchestratorName
				END
		END
	ELSE IF ([control].[GetPropertyValueInternal]('UseExecutionBatches')) = '1'
		BEGIN						
			IF @BatchName IS NULL
				BEGIN
					RAISERROR('A NULL batch name cannot be passed when the UseExecutionBatches property is set to 1 (true).',16,1);
					RETURN 0;
				END;
			
			SELECT 
				@BatchId = [BatchId]
			FROM
				[control].[Batches]
			WHERE
				[BatchName] = @BatchName;
			
			--create local execution id now for the batch
			EXEC [control].[BatchWrapper]
				@BatchId = @BatchId,
				@LocalExecutionId = @BLocalExecutionId OUTPUT;
				
			--reset and restart execution
			IF EXISTS
				(
				SELECT 1 
				FROM 
					[control].[CurrentExecution] 
				WHERE 
					[LocalExecutionId] = @BLocalExecutionId 
					AND ISNULL([PipelineStatus],'') <> 'Success'
				) 
				AND @RestartStatus = 0
				BEGIN
					EXEC [control].[ResetExecution]
						@LocalExecutionId = @BLocalExecutionId;
				END
			--capture failed execution and run new anyway
			ELSE IF EXISTS
				(
				SELECT 1 
				FROM 
					[control].[CurrentExecution]
				WHERE
					[LocalExecutionId] = @BLocalExecutionId 
				)
				AND @RestartStatus = 1
				BEGIN
					EXEC [control].[UpdateExecutionLog]
						@PerformErrorCheck = 0, --Special case when OverideRestart = 1;
						@ExecutionId = @BLocalExecutionId;

					EXEC [control].[CreateNewExecution]
						@CallingOrchestratorName = @CallingOrchestratorName,
						@LocalExecutionId = @BLocalExecutionId;
				END
			--no restart considerations, just create new execution
			ELSE
				BEGIN
					EXEC [control].[CreateNewExecution] 
						@CallingOrchestratorName = @CallingOrchestratorName,
						@LocalExecutionId = @BLocalExecutionId;
				END
			
		END
	ELSE
		BEGIN
			--metadata integrity checks should mean this condition is never hit
			RAISERROR('Unknown batch handling configuration. Update properties with UseExecutionBatches value and try again.',16,1);
			RETURN 0;
		END
END;