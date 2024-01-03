CREATE PROCEDURE [cumulus.control].[BatchWrapper]
	(
	@BatchId UNIQUEIDENTIFIER,
	@LocalExecutionId UNIQUEIDENTIFIER OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @RestartStatus BIT

	--get restart overide property	
	SELECT @RestartStatus = [cumulus.control].[GetPropertyValueInternal]('OverideRestart')

	--check for running batch execution
	IF EXISTS
		(
		SELECT 1 FROM [cumulus.control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'') = 'Running'
		)
		BEGIN
			SELECT
				@LocalExecutionId = [ExecutionId]
			FROM
				[cumulus.control].[BatchExecution]
			WHERE
				[BatchId] = @BatchId;
			
			--should never actually be called as handled within Orchestrator pipelines using the Pipeline Run Check utility
			RAISERROR('There is already an batch execution run in progress. Stop the related parent pipeline via the Orchestrator first.',16,1);
			RETURN 0;
		END
	ELSE IF EXISTS
		(
		SELECT 1 FROM [cumulus.control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'') = 'Stopped'
		)
		AND @RestartStatus = 0
		BEGIN
			SELECT
				@LocalExecutionId = [ExecutionId]
			FROM
				[cumulus.control].[BatchExecution]
			WHERE
				[BatchId] = @BatchId
				AND ISNULL([BatchStatus],'') = 'Stopped';

			RETURN 0;
		END
	ELSE IF EXISTS
		(
		SELECT 1 FROM [cumulus.control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'') = 'Stopped'
		)
		AND @RestartStatus = 1
		BEGIN
			--clean up current execution table and abandon batch
			SELECT
				@LocalExecutionId = [ExecutionId]
			FROM
				[cumulus.control].[BatchExecution]
			WHERE
				[BatchId] = @BatchId
				AND ISNULL([BatchStatus],'') = 'Stopped';
			
			EXEC [cumulus.control].[UpdateExecutionLog]
				@PerformErrorCheck = 0, --Special case when OverideRestart = 1;
				@ExecutionId = @LocalExecutionId;
			
			--abandon previous batch execution
			UPDATE
				[cumulus.control].[BatchExecution]
			SET
				[BatchStatus] = 'Abandoned'
			WHERE
				[BatchId] = @BatchId 
				AND ISNULL([BatchStatus],'') = 'Stopped';
	
			SET @LocalExecutionId = NEWID();

			--create new batch run record
			INSERT INTO [cumulus.control].[BatchExecution]
				(
				[BatchId],
				[ExecutionId],
				[BatchName],
				[BatchStatus],
				[StartDateTime]
				)
			SELECT
				[BatchId],
				@LocalExecutionId,
				[BatchName],
				'Running',
				GETUTCDATE()
			FROM
				[cumulus.control].[Batches]
			WHERE
				[BatchId] = @BatchId;			
		END
	ELSE
		BEGIN
			SET @LocalExecutionId = NEWID();

			--create new batch run record
			INSERT INTO [cumulus.control].[BatchExecution]
				(
				[BatchId],
				[ExecutionId],
				[BatchName],
				[BatchStatus],
				[StartDateTime]
				)
			SELECT
				[BatchId],
				@LocalExecutionId,
				[BatchName],
				'Running',
				GETUTCDATE()
			FROM
				[cumulus.control].[Batches]
			WHERE
				[BatchId] = @BatchId;
		END;
END;