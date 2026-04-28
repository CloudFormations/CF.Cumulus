CREATE PROCEDURE [control].[SetLogPipelineSuccess]
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
		--case for clean up runs
		[EndDateTime] = CASE WHEN [EndDateTime] IS NULL THEN GETUTCDATE() ELSE [EndDateTime] END,
		[PipelineStatus] = 'Success'
	WHERE
		[LocalExecutionId] = @ExecutionId
		AND [StageId] = @StageId
		AND [PipelineId] = @PipelineId
END;
