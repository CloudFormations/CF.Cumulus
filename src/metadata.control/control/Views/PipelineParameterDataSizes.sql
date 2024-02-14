CREATE VIEW [control].[PipelineParameterDataSizes]
AS

SELECT 
	[PipelineId],
	SUM(
		(CAST(
			DATALENGTH(
				STRING_ESCAPE([ParameterName] + [ParameterValue],'json')) AS DECIMAL)
			/1024) --KB
			/1024 --MB
		) AS Size
FROM 
	[control].[PipelineParameters]
GROUP BY
	[PipelineId];