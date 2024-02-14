CREATE VIEW [procfwkHelpers].[PipelineDependencyChains]
AS

SELECT 
	ps.[StageName] AS PredecessorStage,
	pp.[PipelineName] AS PredecessorPipeline,
	ds.[StageName] AS DependantStage,
	dp.[PipelineName] AS DependantPipeline
FROM 
	[control].[PipelineDependencies]					pd --pipeline dependencies
	INNER JOIN [control].[Pipelines]					pp --predecessor pipelines
		ON pd.[PipelineId] = pp.[PipelineId]
	INNER JOIN [control].[Pipelines]					dp --dependant pipelines
		ON pd.[DependantPipelineId] = dp.[PipelineId]
	INNER JOIN [control].[Stages]						ps --predecessor stage
		ON pp.[StageId] = ps.[StageId]
	INNER JOIN [control].[Stages]						ds --dependant stage
		ON dp.[StageId] = ds.[StageId];