CREATE VIEW [procfwkReporting].[CurrentExecutionSummary]
AS

SELECT 
	ISNULL([PipelineStatus], 'Not Started') AS 'PipelineStatus',
	COUNT(0) AS 'RecordCount'
FROM 
	[cumulus.control].[CurrentExecution]
GROUP BY
	[PipelineStatus]