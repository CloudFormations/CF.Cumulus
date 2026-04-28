CREATE PROCEDURE [procfwkHelpers].[SetDefaultBatchStageLink]
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
END;