CREATE PROCEDURE [cumulus.control].[SetExecutionBlockDependants]
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
		[cumulus.control].[PipelineDependencies] pe
		INNER JOIN [cumulus.control].[CurrentExecution] ce
			ON pe.[DependantPipelineId] = ce.[PipelineId]
	WHERE
		ce.[LocalExecutionId] = @ExecutionId
		AND pe.[PipelineId] = @PipelineId
END;