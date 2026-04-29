CREATE PROCEDURE [samples].[SetSampleBatchStageLink]
AS
BEGIN
	TRUNCATE TABLE [control].[BatchStageLink]

	INSERT INTO [control].[BatchStageLink]
		(
		[BatchId],
		[StageId]
		)
	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[control].[Batches] b
		INNER JOIN [control].[Stages] s
			ON s.[StageName] <> 'Speed'
			AND s.[StageName] not like '%Control%'
	WHERE
		b.[BatchName] = 'Daily'

	UNION ALL

	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[control].[Batches] b
		INNER JOIN [control].[Stages] s
			ON s.[StageName] = 'Speed'
	WHERE
		b.[BatchName] = 'Hourly'

	UNION ALL

	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[control].[Batches] b
		INNER JOIN [control].[Stages] s
			ON s.[StageName] not like '%Speed%'
			AND s.[StageName] like '%Control%'

	WHERE
		b.[BatchName] = 'ControlDemoDaily'

	UNION ALL

	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[control].[Batches] b
		INNER JOIN [control].[Stages] s
			ON s.[StageName] like '%Speed%'
			AND s.[StageName] like '%Control%'
	WHERE
		b.[BatchName] = 'ControlDemoHourly'
END;