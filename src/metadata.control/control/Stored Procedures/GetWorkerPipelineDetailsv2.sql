CREATE PROCEDURE [control].[GetWorkerPipelineDetailsv2]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT,
	@PipelineId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		orch.[SubscriptionId],
		ce.[PipelineName],
		ce.[OrchestratorName],
		ce.[OrchestratorType],
		ce.[ResourceGroupName]
	FROM 
		[control].[CurrentExecution] ce
		INNER JOIN [control].[Pipelines] p
			ON p.[PipelineId] = ce.[PipelineId]
		INNER JOIN [control].[Orchestrators] orch
			ON orch.[OrchestratorId] = p.[OrchestratorId]
	WHERE 
		ce.[LocalExecutionId] = @ExecutionId
		AND ce.[StageId] = @StageId
		AND ce.[PipelineId] = @PipelineId;
END;