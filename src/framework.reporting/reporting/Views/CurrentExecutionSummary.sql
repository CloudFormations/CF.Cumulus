CREATE VIEW [reporting].[CurrentExecutionSummary]
AS

SELECT 
	ISNULL([PipelineStatus], 'Not Started') AS 'PipelineStatus',
	COUNT(0) AS 'RecordCount'
FROM 
	[control].[CurrentExecution]
GROUP BY
	[PipelineStatus]