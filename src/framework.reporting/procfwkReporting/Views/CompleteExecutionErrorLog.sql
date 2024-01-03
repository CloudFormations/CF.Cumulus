CREATE VIEW [procfwkReporting].[CompleteExecutionErrorLog]
AS

SELECT
	exeLog.[LogId] AS ExecutionLogId,
	errLog.[LogId] AS ErrorLogId,
	exeLog.[LocalExecutionId],
	exeLog.[StartDateTime] AS ProcessingDateTime,
	exeLog.[CallingOrchestratorName],
	exeLog.[OrchestratorType] AS WorkerOrchestartorType,
	exeLog.[OrchestratorName] AS WorkerOrchestrator,
	exeLog.[PipelineName] AS WorkerPipelineName,
	exeLog.[PipelineStatus],
	errLog.[ActivityRunId],
	errLog.[ActivityName],
	errLog.[ActivityType],
	errLog.[ErrorCode],
	errLog.[ErrorType],
	errLog.[ErrorMessage]
FROM
	[control].[ExecutionLog] exeLog
	INNER JOIN [control].[ErrorLog] errLog
		ON exeLog.[LocalExecutionId] = errLog.[LocalExecutionId]
			AND exeLog.[PipelineRunId] = errLog.[PipelineRunId]
	INNER JOIN [control].[Stages] stgs
		ON exeLog.[StageId] = stgs.[StageId]
;