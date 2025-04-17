CREATE PROCEDURE [ingest].[RefreshTokenWaitLogic] (
	@DatasetId INT
)
AS
WITH CTE AS (
SELECT
	ROW_NUMBER() OVER (ORDER BY DatasetId) PositionalNumber,
	d.*
FROM ingest.Datasets AS d
INNER JOIN common.Connections AS c 
ON d.ConnectionFK = c.ConnectionId
WHERE c.ConnectionId in (SELECT ConnectionFK FROM ingest.Datasets
WHERE DatasetId = @DatasetId)
AND d.Enabled = 1
)
SELECT 
	CASE 
		WHEN PositionalNumber = 1 THEN PositionalNumber
		WHEN PositionalNumber < 4 THEN (PositionalNumber - 1) * 30
		ELSE 90
	END AS WaitTimeSeconds
FROM CTE
WHERE DatasetId = @DatasetId

GO

