CREATE PROCEDURE [control].[GetPipelinesInStage]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
		[PipelineId]
	FROM 
		[control].[CurrentExecution]
	WHERE 
		[LocalExecutionId] = @ExecutionId
		AND [StageId] = @StageId
		AND ISNULL([PipelineStatus],'') <> 'Success'
		AND [IsBlocked] <> 1
	ORDER BY
		[PipelineId] ASC;
END;