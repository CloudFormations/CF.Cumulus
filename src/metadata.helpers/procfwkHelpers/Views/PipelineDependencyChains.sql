CREATE VIEW [procfwkHelpers].[PipelineDependencyChains]
AS

SELECT 
	ps.[StageName] AS PredecessorStage,
	pp.[PipelineName] AS PredecessorPipeline,
	ds.[StageName] AS DependantStage,
	dp.[PipelineName] AS DependantPipeline
FROM 
	[cumulus.control].[PipelineDependencies]					pd --pipeline dependencies
	INNER JOIN [cumulus.control].[Pipelines]					pp --predecessor pipelines
		ON pd.[PipelineId] = pp.[PipelineId]
	INNER JOIN [cumulus.control].[Pipelines]					dp --dependant pipelines
		ON pd.[DependantPipelineId] = dp.[PipelineId]
	INNER JOIN [cumulus.control].[Stages]						ps --predecessor stage
		ON pp.[StageId] = ps.[StageId]
	INNER JOIN [cumulus.control].[Stages]						ds --dependant stage
		ON dp.[StageId] = ds.[StageId];