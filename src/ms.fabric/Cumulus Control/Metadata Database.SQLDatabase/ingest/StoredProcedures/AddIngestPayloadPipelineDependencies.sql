CREATE PROCEDURE [ingest].[AddIngestPayloadPipelineDependencies] (
	@DatasetDisplayName VARCHAR(50)
) AS
DECLARE @DatasetId INT

-- defensive checks only 1 dataset id returned
DECLARE @DatasetCount INT

SELECT @DatasetCount = COUNT(*)
FROM [ingest].[Datasets] AS ds
INNER JOIN [ingest].[Connections] AS cs
ON ds.ConnectionFK = cs.ConnectionId
WHERE ds.Enabled = 1
AND cs.Enabled = 1
AND ds.DatasetDisplayName = @DatasetDisplayName

IF @DatasetCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Dataset Id provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DatasetCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id, and the connection details.',16,1)
    RETURN 0;
END

SELECT 
    @DatasetId = DatasetId
FROM [ingest].[Datasets]
WHERE DatasetDisplayName = @DatasetDisplayName
AND Enabled = 1


DECLARE @Dependencies TABLE (
	PipelineId INT, -- Raw
	DependantPipelineId INT -- Cleansed
)

DECLARE @DependenciesStagingTable TABLE (
	PipelineId INT,
	StageId INT,
	ParameterValue INT
)
DECLARE @PipelineIdResult INT;
DECLARE @DependantPipelineIdResult INT;

INSERT INTO @DependenciesStagingTable (PipelineId,StageId,ParameterValue)
SELECT 
	p.PipelineId, p.StageId, CAST(pp.ParameterValue AS INT) AS ParameterValue --,*
FROM control.Pipelines AS p
INNER JOIN control.PipelineParameters AS pp
ON p.PipelineId = pp.PipelineId
WHERE p.PipelineName LIKE 'Ingest_PL_%'

SELECT @PipelineIdResult = PipelineId 
FROM @DependenciesStagingTable
INNER JOIN ingest.Datasets AS d
ON ParameterValue = d.DatasetId
WHERE ParameterValue = @DatasetId
AND StageId = 1

SELECT @DependantPipelineIdResult = PipelineId 
FROM @DependenciesStagingTable
INNER JOIN ingest.Datasets AS d
ON ParameterValue = d.DatasetId
WHERE ParameterValue = @DatasetId
AND StageId = 2

INSERT INTO @Dependencies (PipelineId,DependantPipelineId)
SELECT @PipelineIdResult, @DependantPipelineIdResult

IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
	RAISERROR('Missing Ids for this Dataset',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NOT NULL
BEGIN 
	RAISERROR('Missing PipelineId (Raw Ingest Pipeline)',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
	RAISERROR('Missing DependantPipelineId (Cleansed Merge Pipeline)',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NOT NULL
BEGIN 
	MERGE INTO control.PipelineDependencies AS target
	USING @Dependencies AS source
	ON target.PipelineId = source.PipelineId
	AND target.DependantPipelineId = source.DependantPipelineId
	WHEN NOT MATCHED THEN
		INSERT (PipelineId, DependantPipelineId) VALUES (source.PipelineId, source.DependantPipelineId);
	PRINT 'Dependencies merged into control.PipelineDependencies'
END
ELSE 
BEGIN
	RAISERROR('Unexpected Error',16,1)
    RETURN 0;
END

GO

