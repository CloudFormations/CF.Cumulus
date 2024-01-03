CREATE PROCEDURE [procfwkHelpers].[SetDefaultBatchStageLink]
AS
BEGIN
	TRUNCATE TABLE [cumulus.control].[BatchStageLink]

	INSERT INTO [cumulus.control].[BatchStageLink]
		(
		[BatchId],
		[StageId]
		)
	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[cumulus.control].[Batches] b
		INNER JOIN [cumulus.control].[Stages] s
			ON s.[StageName] <> 'Speed'
	WHERE
		b.[BatchName] = 'Daily'

	UNION ALL

	SELECT
		b.[BatchId],
		s.[StageId]
	FROM
		[cumulus.control].[Batches] b
		INNER JOIN [cumulus.control].[Stages] s
			ON s.[StageName] = 'Speed'
	WHERE
		b.[BatchName] = 'Hourly'
END;