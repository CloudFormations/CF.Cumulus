﻿CREATE PROCEDURE [control].[SetLogPipelineRunning]
	(
	@ExecutionId UNIQUEIDENTIFIER,
	@StageId INT,
	@PipelineId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE
		[control].[CurrentExecution]
	SET
		--case for clean up runs
		[StartDateTime] = CASE WHEN [StartDateTime] IS NULL THEN GETUTCDATE() ELSE [StartDateTime] END,
		[PipelineStatus] = 'Running'
	WHERE
		[LocalExecutionId] = @ExecutionId
		AND [StageId] = @StageId
		AND [PipelineId] = @PipelineId
END;
