

CREATE PROCEDURE [ingest].[GetAPIPayload] (
@DatasetId INT
)
AS

DECLARE @LoadClause NVARCHAR(MAX);
DECLARE @LoadClauseReplaced NVARCHAR(MAX);

-- Define all your parameters and their corresponding values
DECLARE @params TABLE (ParamName NVARCHAR(50), ParamValue NVARCHAR(30));

INSERT INTO @params (ParamName, ParamValue)
VALUES
('PARAMETER_GT_1_YEAR', CONVERT(NVARCHAR, DATEADD(YEAR, -1, GETUTCDATE()), 126)),
('PARAMETER_GT_1_MONTH', CONVERT(NVARCHAR, DATEADD(MONTH, -1, GETUTCDATE()), 126)),
('PARAMETER_GT_1_DAY', CONVERT(NVARCHAR, DATEADD(DAY, -1, GETUTCDATE()), 126)),
('PARAMETER_GT_1_HOUR', CONVERT(NVARCHAR, DATEADD(HOUR, -1, GETUTCDATE()), 126)),
('PARAMETER_NOW', CONVERT(NVARCHAR, GETUTCDATE(), 126)),
('PARAMETER_LT_1_YEAR', CONVERT(NVARCHAR, DATEADD(YEAR, 1, GETUTCDATE()), 126)),
('PARAMETER_LT_1_MONTH', CONVERT(NVARCHAR, DATEADD(MONTH, 1, GETUTCDATE()), 126)),
('PARAMETER_LT_1_DAY', CONVERT(NVARCHAR, DATEADD(DAY, 1, GETUTCDATE()), 126)),
('PARAMETER_LT_1_HOUR', CONVERT(NVARCHAR, DATEADD(HOUR, 1, GETUTCDATE()), 126));

-- Original LoadClause
SELECT 
	@LoadClause = LoadClause,
	@LoadClauseReplaced = LoadClause
FROM ingest.Datasets
WHERE DatasetId = @DatasetId

-- Perform the replacements
SET @LoadClauseReplaced = @LoadClause;

DECLARE @param NVARCHAR(50), @value NVARCHAR(30);

DECLARE param_cursor CURSOR FOR 
SELECT ParamName, ParamValue FROM @params;

OPEN param_cursor;
FETCH NEXT FROM param_cursor INTO @param, @value;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @LoadClauseReplaced = REPLACE(@LoadClauseReplaced, @param, @value);
    FETCH NEXT FROM param_cursor INTO @param, @value;
END;

CLOSE param_cursor;
DEALLOCATE param_cursor;


SELECT
	c.ConnectionLocation,
	'full' AS LoadAction,
	c.ConnectionDisplayName,
	ds.DatasetDisplayName,
	'000' + cast(ds.VersionNumber as varchar(2)) AS VersionNumber,
	c.LinkedServiceName,
	ds.LoadType,
	ds.SourcePath,
	ds.SourceName,
	c.username,
	c.keyvaultsecret,
	@LoadClauseReplaced AS SourceQuery,
    --cn2.[ConnectionLocation] AS 'TargetStorageName',
    --cn2.[SourceLocation] AS 'TargetStorageContainer',
	'cfcdemodevdlsuks01' AS 'TargetStorageName',
    'raw' AS 'TargetStorageContainer'
FROM ingest.Datasets AS ds
INNER JOIN common.Connections AS c
ON ds.ConnectionFK = c.ConnectionId
--ON c.ConnectionId = 4
INNER JOIN common.ComputeConnections AS cc
ON ds.MergeComputeConnectionFK = cc.ComputeConnectionId
WHERE 1 = 1 
AND [DatasetId] = @DatasetId
AND 
    ds.[Enabled] = 1
AND 
    c.[Enabled] = 1

GO

