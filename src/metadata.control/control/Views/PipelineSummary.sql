CREATE VIEW [control].[PipelineSummary] AS
WITH cte AS (
SELECT 
	CASE 
		WHEN ids.DatasetDisplayname IS NOT NULL THEN 'Ingest'
		WHEN tds.DatasetName IS NOT NULL THEN  'Transform'
		ELSE 'Unassigned'
	END AS ComponentName,
	CASE 
		WHEN ids.DatasetDisplayname IS NOT NULL THEN ids.DatasetDisplayname 
		WHEN tds.DatasetName IS NOT NULL THEN tds.DatasetName 
		ELSE p.PipelineName
	END AS DatasetName,
	p.PipelineName,
	pp.ParameterName,
	pp.ParameterValue,
	p.PipelineId,
	s.StageName,
	pd.DependantPipelineId
FROM control.pipelines AS p
INNER JOIN control.pipelineparameters AS pp
ON p.PipelineId = pp.PipelineId
LEFT JOIN control.pipelinedependencies AS pd
ON p.PipelineId = pd.PipelineId
INNER JOIN control.stages AS s
ON p.StageId = s.StageId
LEFT JOIN ingest.Datasets AS ids
ON pp.parametervalue = CAST(ids.datasetid AS VARCHAR(4))
AND p.pipelineName LIKE 'Ingest_PL_%'
LEFT JOIN transform.Datasets as tds
ON pp.parametervalue = CAST(tds.datasetid AS VARCHAR(4))
AND p.pipelineName LIKE 'Transform_PL_%'
)
SELECT cte.*, cte2.DatasetName AS DependsOnDataset, cte2.PipelineName AS DependsOnPipelineName, cte2.PipelineId AS DependsOnPipelineId
FROM cte
LEFT JOIN cte AS cte2
ON cte.PipelineId = cte2.DependantPipelineId
