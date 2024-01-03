CREATE PROCEDURE [cumulus.control].[CheckForBlockedPipelines]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	-- If any pipelines still have a status of running, mark as failed to block downstream processing, and add an error log
	IF EXISTS
		(
		SELECT 
			*
		FROM 
			[cumulus.control].[CurrentExecution]
		WHERE 
			[LocalExecutionId] = @ExecutionId
			AND [StageId] < @StageId
			AND [PipelineStatus] = 'Running'
		)
		BEGIN		
			DECLARE @RunningPipelineId INT;
			DECLARE @RunningPipelineStageId INT;
			DECLARE @RunId UNIQUEIDENTIFIER;
			DECLARE @ErrorJson NVARCHAR(MAX);
			DECLARE @RunningCursor CURSOR ;

			SET @RunningCursor = CURSOR FOR 
									        SELECT 
										        [PipelineId],
										        [StageId],
										        [PipelineRunId]
									        FROM 
										        [cumulus.control].[CurrentExecution] 
									        WHERE 
										        [LocalExecutionId] = @ExecutionId
										        AND [StageId] < @StageId
										        AND [PipelineStatus] = 'Running'

			OPEN @RunningCursor
			FETCH NEXT FROM @RunningCursor INTO @RunningPipelineId, @RunningPipelineStageId, @RunId
					
			WHILE @@FETCH_STATUS = 0
			BEGIN 
				EXEC [cumulus.control].SetLogPipelineFailed 
					@ExecutionId = @ExecutionId,
					@StageId = @RunningPipelineStageId,
					@PipelineId = @RunningPipelineId,
					@RunId = @RunId;

				SET @ErrorJson = '{ "RunId": "' + Cast(@RunId AS CHAR(36)) + '", "Errors": [ { "ActivityRunId": "00000000-0000-0000-0000-000000000000", "ActivityName": "Set Pipeline Result", "ActivityType": "Switch", "ErrorCode": "Unknown", "ErrorType": "Framework Error", "ErrorMessage": "Framework pipeline ''04-Infant'' failed to set the pipeline result, most likely due to a timeout or azure connectivity issue. Check the framework Data Factory monitor for more information." } ] }'
				EXEC [cumulus.control].[SetErrorLogDetails] 
					@LocalExecutionId = @ExecutionId,
                    @JsonErrorDetails = @ErrorJson;
						
				FETCH NEXT FROM @RunningCursor INTO @RunningPipelineId, @RunningPipelineStageId, @RunId;
			END;
			CLOSE @RunningCursor;
			DEALLOCATE @RunningCursor;
		END;


	IF ([cumulus.control].[GetPropertyValueInternal]('FailureHandling')) = 'None'
		BEGIN
			--do nothing allow processing to carry on regardless
			RETURN 0;
		END;
		
	ELSE IF ([cumulus.control].[GetPropertyValueInternal]('FailureHandling')) = 'Simple'
		BEGIN
			IF EXISTS
				(
				SELECT 
					*
				FROM 
					[cumulus.control].[CurrentExecution]
				WHERE 
					[LocalExecutionId] = @ExecutionId
					AND [StageId] = @StageId
					AND [IsBlocked] = 1
				)
				BEGIN		
					UPDATE
						[cumulus.control].[BatchExecution]
					SET
						[EndDateTime] = GETUTCDATE(),
						[BatchStatus] = 'Stopped'
					WHERE
						[ExecutionId] = @ExecutionId;
					
					--Saves the infant pipeline and activities being called throwing the exception at this level.
					RAISERROR('All pipelines are blocked. Stopping processing.',16,1); 
					--If not thrown here, the proc [cumulus.control].[UpdateExecutionLog] would eventually throw an exception.
					RETURN 0;
				END			
		END;
	
	ELSE IF ([cumulus.control].[GetPropertyValueInternal]('FailureHandling')) = 'DependencyChain'
		BEGIN
			IF EXISTS
				(
				SELECT 
					*
				FROM 
					[cumulus.control].[CurrentExecution]
				WHERE 
					[LocalExecutionId] = @ExecutionId
					AND [StageId] = @StageId
					AND [IsBlocked] = 1
				)
				BEGIN		
					DECLARE @PipelineId INT;
					DECLARE @Cursor CURSOR ;

					SET @Cursor = CURSOR FOR 
											SELECT 
												[PipelineId] 
											FROM 
												[cumulus.control].[CurrentExecution] 
											WHERE 
												[LocalExecutionId] = @ExecutionId
												AND [StageId] = @StageId 
												AND [IsBlocked] = 1

					OPEN @Cursor
					FETCH NEXT FROM @Cursor INTO @PipelineId
					
					WHILE @@FETCH_STATUS = 0
					BEGIN 
						EXEC [cumulus.control].[SetExecutionBlockDependants]
							@ExecutionId = @ExecutionId,
							@PipelineId = @PipelineId;
						
						FETCH NEXT FROM @Cursor INTO @PipelineId;
					END;
					CLOSE @Cursor;
					DEALLOCATE @Cursor;
				END;
		END;
	ELSE
		BEGIN
			RAISERROR('Unknown failure handling state.',16,1);
			RETURN 0;
		END;
END;
