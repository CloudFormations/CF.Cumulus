CREATE PROCEDURE [control].[SetExecutionBlockDependants]
	(
	@ExecutionId UNIQUEIDENTIFIER = NULL,
	@PipelineId INT
	)
AS
BEGIN
	--update dependents status
	UPDATE
		ce
	SET
		ce.[PipelineStatus] = 'Blocked',
		ce.[IsBlocked] = 1
	FROM
		[control].[PipelineDependencies] pe
		INNER JOIN [control].[CurrentExecution] ce
			ON pe.[DependantPipelineId] = ce.[PipelineId]
	WHERE
		ce.[LocalExecutionId] = @ExecutionId
		AND pe.[PipelineId] = @PipelineId
END;