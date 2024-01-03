CREATE PROCEDURE [procfwkHelpers].[GetExecutionDetails]
	(
	@LocalExecutionId UNIQUEIDENTIFIER = NULL
	)
AS
BEGIN

	--Get last execution ID
	IF @LocalExecutionId IS NULL
	BEGIN
		WITH maxLog AS
			(
			SELECT
				MAX([LogId]) AS MaxLogId
			FROM
				[cumulus.control].[ExecutionLog]
			)
		SELECT
			@LocalExecutionId = el1.[LocalExecutionId]
		FROM
			[cumulus.control].[ExecutionLog] el1
			INNER JOIN maxLog
				ON maxLog.[MaxLogId] = el1.[LogId];
	END;

	--Execution Summary
	SELECT
		CAST(el2.[StageId] AS VARCHAR(5)) + ' - ' + stgs.[StageName] AS Stage,
		COUNT(0) AS RecordCount,
		DATEDIFF(MINUTE, MIN(el2.[StartDateTime]), MAX(el2.[EndDateTime])) DurationMinutes
	FROM
		[cumulus.control].[ExecutionLog] el2
		INNER JOIN [cumulus.control].[Stages] stgs
			ON el2.[StageId] = stgs.[StageId]
	WHERE
		el2.[LocalExecutionId] = @LocalExecutionId
	GROUP BY
		CAST(el2.[StageId] AS VARCHAR(5)) + ' - ' + stgs.[StageName]
	ORDER BY
		CAST(el2.[StageId] AS VARCHAR(5)) + ' - ' + stgs.[StageName];

	--Full execution details
	SELECT
		el3.[LogId],
		el3.[LocalExecutionId],
		el3.[OrchestratorType],
		el3.[OrchestratorName],
		el3.[StageId],
		stgs.[StageName],
		el3.[PipelineId],
		el3.[PipelineName],
		el3.[StartDateTime],
		el3.[EndDateTime],
		ISNULL(DATEDIFF(MINUTE, el3.[StartDateTime], el3.[EndDateTime]),0) AS DurationMinutes,
		el3.[PipelineStatus],
		el3.[PipelineRunId],
		el3.[PipelineParamsUsed],
		errLog.[ActivityRunId],
		errLog.[ActivityName],
		errLog.[ActivityType],
		errLog.[ErrorCode],
		errLog.[ErrorType],
		errLog.[ErrorMessage]
	FROM 
		[cumulus.control].[ExecutionLog] el3
		LEFT OUTER JOIN [cumulus.control].[ErrorLog] errLog
			ON el3.[LocalExecutionId] = errLog.[LocalExecutionId]
				AND el3.[PipelineRunId] = errLog.[PipelineRunId]
		INNER JOIN [cumulus.control].[Stages] stgs
			ON el3.[StageId] = stgs.[StageId]
	WHERE
		el3.[LocalExecutionId] = @LocalExecutionId
	ORDER BY
		el3.[PipelineId],
		el3.[StartDateTime];
END;