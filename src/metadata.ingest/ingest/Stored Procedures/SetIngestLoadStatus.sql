CREATE PROCEDURE [ingest].[SetIngestLoadStatus]
(
    @DatasetId INT,
    @LoadType VARCHAR(1),
    @IngestStage VARCHAR(20),
    @FileLoadDateTime DATETIME2
)
AS
BEGIN

-- Defensive checks for input parameters
DECLARE @ResultRowCount INT

SELECT 
    @ResultRowCount = COUNT(*)
FROM
[ingest].[Datasets] ds
INNER JOIN [common].[Connections] cn
    ON ds.[ConnectionFK] = cn.[ConnectionId]
WHERE
ds.[DatasetId] = @DatasetId
AND 
    ds.[Enabled] = 1
AND 
    cn.[Enabled] = 1

IF @ResultRowCount = 0
BEGIN
    RAISERROR('No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections are enabled.',16,1)
    RETURN 0;
END

IF @LoadType NOT IN ('F', 'I')
BEGIN
    RAISERROR('Load Type specified not supported. Please specify either I or F',16,1)
	RETURN 0;
END

IF @IngestStage NOT IN ('Raw','Cleansed')
BEGIN
    RAISERROR('Ingest Stage specified not supported. Please specify either Raw or Cleansed',16,1)
    RETURN 0;
END

DECLARE @LoadStatus INT

SELECT 
    @LoadStatus = LoadStatus
FROM 
    [ingest].[Datasets]
WHERE
    DatasetId = @DatasetId

IF @LoadType = 'F' AND @IngestStage = 'Raw'
BEGIN
    -- Add that a raw full load has occurred
    SET @LoadStatus = @LoadStatus | POWER(2,1) 
    
    -- Remove the raw incremental load status
    SET @LoadStatus = @LoadStatus & ~POWER(2,2) 

    UPDATE [ingest].[Datasets]
    SET LoadStatus = @LoadStatus,
        RawLastFullLoadDate = @FileLoadDateTime
    WHERE DatasetId = @DatasetId
END

IF @LoadType = 'I' AND @IngestStage = 'Raw'
BEGIN
    SET @LoadStatus = @LoadStatus | POWER(2,2) 

    UPDATE [ingest].[Datasets]
    SET LoadStatus = @LoadStatus,
        RawLastIncrementalLoadDate = @FileLoadDateTime
    WHERE DatasetId = @DatasetId
END

IF @LoadType = 'F' AND @IngestStage = 'Cleansed'
BEGIN
    -- Add that a cleansed full load has occurred
    SET @LoadStatus = @LoadStatus | POWER(2,3)  

    -- Remove the cleansed incremental load status
    SET @LoadStatus = @LoadStatus & ~POWER(2,4) 

    UPDATE [ingest].[Datasets]
    SET LoadStatus = @LoadStatus,
        CleansedLastFullLoadDate = @FileLoadDateTime
    WHERE DatasetId = @DatasetId
END

IF @LoadType = 'I' AND @IngestStage = 'Cleansed'
BEGIN
    SET @LoadStatus = @LoadStatus | POWER(2,4)  
    UPDATE [ingest].[Datasets]
    SET LoadStatus = @LoadStatus,
        CleansedLastIncrementalLoadDate = @FileLoadDateTime
    WHERE DatasetId = @DatasetId
END

END