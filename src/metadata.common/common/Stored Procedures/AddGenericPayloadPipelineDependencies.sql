CREATE PROCEDURE [common].[AddGenericPayloadPipelineDependencies] (
 @DatasetDisplayName VARCHAR(50),
 @StageName VARCHAR(50),
 @DependantDatasetDisplayName VARCHAR(50),
 @DependantStageName VARCHAR(50)
) AS
DECLARE @DatasetId INT
DECLARE @DependantDatasetId INT


-- defensive checks only 1 dataset id returned
DECLARE @DatasetCount INT

IF @StageName in ('Raw', 'Cleansed')
BEGIN
    SELECT @DatasetCount = COUNT(*)
    FROM [ingest].[Datasets] AS ds
    INNER JOIN [common].[Connections] AS cs
    ON ds.ConnectionFK = cs.ConnectionId
    WHERE ds.Enabled = 1
    AND cs.Enabled = 1
    AND ds.DatasetDisplayName = @DatasetDisplayName

    SELECT 
        @DatasetId = DatasetId
    FROM [ingest].[Datasets]
    WHERE DatasetDisplayName = @DatasetDisplayName
    AND Enabled = 1
END

ELSE IF @StageName in ('Dimension', 'Fact')
BEGIN
    SELECT @DatasetCount = COUNT(*)
    FROM [transform].[Datasets] AS ds
    INNER JOIN [common].[ComputeConnections] AS ccs
    ON ds.ComputeConnectionFK = ccs.ComputeConnectionId
    WHERE ds.Enabled = 1
    AND ccs.Enabled = 1
    AND ds.DatasetName = @DatasetDisplayName

    SELECT 
        @DatasetId = DatasetId
    FROM [transform].[Datasets]
    WHERE DatasetName = @DatasetDisplayName
    AND Enabled = 1
END

ELSE
BEGIN
    RAISERROR('Stage name selected not valid for adding Pipeline Dependencies in this way. Please review data provided',16,1)
    RETURN 0;
END

IF @DatasetCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Raw Dataset Id provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DatasetCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id, and the connection details.',16,1)
    RETURN 0;
END

-- defensive checks only 1 dataset id returned
DECLARE @DependantDatasetCount INT

IF @DependantStageName in ('Raw', 'Cleansed')
BEGIN
    SELECT @DependantDatasetCount = COUNT(*)
    FROM [ingest].[Datasets] AS ds
    INNER JOIN [common].[Connections] AS cs
    ON ds.ConnectionFK = cs.ConnectionId
    WHERE ds.Enabled = 1
    AND cs.Enabled = 1
    AND ds.DatasetDisplayName = @DependantDatasetDisplayName

    SELECT 
        @DependantDatasetId = DatasetId
    FROM [ingest].[Datasets]
    WHERE DatasetDisplayName = @DependantDatasetDisplayName
    AND Enabled = 1
END

ELSE IF @DependantStageName in ('Dimension', 'Fact')
BEGIN
    SELECT @DependantDatasetCount = COUNT(*)
    FROM [transform].[Datasets] AS ds
    INNER JOIN [common].[ComputeConnections] AS ccs
    ON ds.ComputeConnectionFK = ccs.ComputeConnectionId
    WHERE ds.Enabled = 1
    AND ccs.Enabled = 1
    AND ds.DatasetName = @DependantDatasetDisplayName

    SELECT 
        @DependantDatasetId = DatasetId
    FROM [transform].[Datasets]
    WHERE DatasetName = @DependantDatasetDisplayName
    AND Enabled = 1

END

ELSE
BEGIN
    RAISERROR('Stage name selected not valid for adding Pipeline Dependencies in this way. Please review data provided',16,1)
    RETURN 0;
END

IF @DependantDatasetCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Dataset Name provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DependantDatasetCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id, and the connection details.',16,1)
    RETURN 0;
END


DECLARE @StageId INT
DECLARE @DependantStageId INT

-- defensive checks only 1 dataset id returned
DECLARE @StageCount INT

SELECT @StageCount = COUNT(*)
FROM [control].[Stages]
WHERE Enabled = 1
AND StageName = @StageName

IF @StageCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Stage name provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @StageCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Stage with this name.',16,1)
    RETURN 0;
END

-- defensive checks only 1 dataset id returned
DECLARE @DependantStageCount INT

SELECT @DependantStageCount = COUNT(*)
FROM [control].[Stages]
WHERE Enabled = 1
AND StageName = @DependantStageName

IF @DependantStageCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Dependant Stage name provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DependantStageCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dependant Stage with this name.',16,1)
    RETURN 0;
END

SELECT 
    @StageId = StageId
FROM [control].[Stages]
WHERE Enabled = 1
AND StageName = @StageName

SELECT 
    @DependantStageId = StageId
FROM [control].[Stages]
WHERE Enabled = 1
AND StageName = @DependantStageName

DECLARE @Dependencies TABLE (
 PipelineId INT, -- Raw
 DependantPipelineId INT -- Cleansed
)

DECLARE @DependenciesStagingTable TABLE (
 PipelineId INT,
 StageId INT,
 ParameterValue VARCHAR(250)
)
DECLARE @PipelineIdResult INT;
DECLARE @DependantPipelineIdResult INT;

INSERT INTO @DependenciesStagingTable (PipelineId, StageId, ParameterValue)
SELECT 
    p.PipelineId, p.StageId, pp.ParameterValue
FROM control.Pipelines AS p
INNER JOIN control.PipelineParameters AS pp
ON p.PipelineId = pp.PipelineId

SELECT @PipelineIdResult = PipelineId 
FROM @DependenciesStagingTable
WHERE ParameterValue = CAST(@DatasetId AS VARCHAR(250))
AND StageId = @StageId

SELECT @DependantPipelineIdResult = PipelineId 
FROM @DependenciesStagingTable
WHERE ParameterValue = CAST(@DependantDatasetId AS VARCHAR(250))
AND StageId = @DependantStageId


INSERT INTO @Dependencies (PipelineId,DependantPipelineId)
SELECT @PipelineIdResult, @DependantPipelineIdResult

IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
 RAISERROR('Missing Ids for this Dataset',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NOT NULL
BEGIN 
 RAISERROR('Missing PipelineId (Pipeline)',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
 RAISERROR('Missing DependantPipelineId (Dependant Pipeline)',16,1)
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