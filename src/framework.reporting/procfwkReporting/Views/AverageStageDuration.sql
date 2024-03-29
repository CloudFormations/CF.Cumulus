﻿CREATE VIEW [procfwkReporting].[AverageStageDuration]
AS

WITH stageStartEnd AS
	(
	SELECT
		[LocalExecutionId],
		[StageId],
		MIN([StartDateTime]) AS 'StageStart',
		MAX([EndDateTime]) AS 'StageEnd'
	FROM
		[control].[ExecutionLog]
	GROUP BY
		[LocalExecutionId],
		[StageId]
	)

SELECT
	s.[StageId],
	s.[StageName],
	s.[StageDescription],
	AVG(DATEDIFF(MINUTE, stageStartEnd.[StageStart], stageStartEnd.[StageEnd])) 'AvgStageRunDurationMinutes'
FROM
	stageStartEnd
	INNER JOIN [control].[Stages] s
		ON stageStartEnd.[StageId] = s.[StageId]
GROUP BY
	s.[StageId],
	s.[StageName],
	s.[StageDescription]