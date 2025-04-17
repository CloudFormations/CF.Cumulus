
	CREATE PROCEDURE [control].[SetLogPipelineLastStatusCheck]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			[LastStatusCheckDateTime] = GETUTCDATE()
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;

GO

