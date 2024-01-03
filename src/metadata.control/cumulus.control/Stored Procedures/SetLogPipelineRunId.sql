CREATE PROCEDURE [cumulus.control].[SetLogPipelineRunId]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT,
	@PipelineId INT,
	@RunId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE
		[cumulus.control].[CurrentExecution]
	SET
		[PipelineRunId] = LOWER(@RunId)
	WHERE
		[LocalExecutionId] = @ExecutionId
		AND [StageId] = @StageId
		AND [PipelineId] = @PipelineId
END;