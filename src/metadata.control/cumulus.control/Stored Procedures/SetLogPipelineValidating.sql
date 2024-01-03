CREATE PROCEDURE [cumulus.control].[SetLogPipelineValidating]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT,
	@PipelineId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE
		[cumulus.control].[CurrentExecution]
	SET
		[PipelineStatus] = 'Validating'
	WHERE
		[LocalExecutionId] = @ExecutionId
		AND [StageId] = @StageId
		AND [PipelineId] = @PipelineId
END;
