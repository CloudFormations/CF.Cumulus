CREATE PROCEDURE [transform].[AddTransformPayloadPipelineDependencies] (
	@StageName VARCHAR(25),
	@DatasetName VARCHAR(50), 
	@DependsOnStageName VARCHAR(25),
	@DependsOnDatasetName VARCHAR(50)
) AS


-- defensive checks stage name in ('Dimensions', 'Facts')
IF @StageName NOT IN ('Dimensions', 'Facts')
BEGIN
    RAISERROR('This Functionality may only be used for adding Dimensions or Facts from the Transform schema to the Control Pipeline. If you require different functionality to be added to control.pipelines, please proceed with a manual INSERT statement.',16,1)
	RETURN 0;
END

-- defensive checks stage name in ('Dimensions', 'Facts')
IF @DependsOnStageName NOT IN ('Cleansed','Dimensions', 'Facts')
BEGIN
    RAISERROR('This Functionality may only be used for adding Dimensions or Facts from the Transform schema to the Control Pipeline. Supported Dependencies include Cleansed, Dimensions and Facts. If you require different functionality to be added to control.pipelines, please proceed with a manual INSERT statement.',16,1)
	RETURN 0;
END

-- defensive checks only 1 dataset id returned
DECLARE @DatasetId INT
DECLARE @DatasetCount INT

SELECT @DatasetCount = COUNT(*)
FROM [transform].[Datasets] AS ds
WHERE ds.Enabled = 1
AND ds.DatasetName = @DatasetName

IF @DatasetCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Dataset Id provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DatasetCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id.',16,1)
    RETURN 0;
END

-- defensive checks only 1 dataset id returned for dependency
DECLARE @DependsOnDatasetId INT
DECLARE @DependsOnDatasetCount INT

IF @DependsOnStageName in ('Dimensions', 'Facts')
BEGIN
	SELECT @DependsOnDatasetCount = COUNT(*)
	FROM [transform].[Datasets] AS ds
	WHERE ds.Enabled = 1
	AND ds.DatasetName = @DependsOnDatasetName
END
IF @DependsOnStageName in ('Cleansed')
BEGIN
	SELECT @DependsOnDatasetCount = COUNT(*)
	FROM [ingest].[Datasets] AS ds
	WHERE ds.Enabled = 1
	AND ds.DatasetDisplayName = @DependsOnDatasetName
END

IF @DependsOnDatasetCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Dataset Id provided and confirm this is enabled.',16,1)
    RETURN 0;
END
IF @DependsOnDatasetCount > 1
BEGIN
    RAISERROR('More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id.',16,1)
    RETURN 0;
END


-- Get Dataset Id
SELECT 
    @DatasetId = DatasetId
FROM [transform].[Datasets]
WHERE DatasetName = @DatasetName
AND Enabled = 1


-- Get Depends On Dataset Id
IF @DependsOnStageName in ('Dimensions', 'Facts')
BEGIN
	SELECT @DependsOnDatasetId = DatasetId
	FROM [transform].[Datasets] AS ds
	WHERE ds.Enabled = 1
	AND ds.DatasetName = @DependsOnDatasetName
END
IF @DependsOnStageName in ('Cleansed')
BEGIN
	SELECT @DependsOnDatasetId = DatasetId
	FROM [ingest].[Datasets] AS ds
	WHERE ds.Enabled = 1
	AND ds.DatasetDisplayName = @DependsOnDatasetName
END

-- Get Stage Id
DECLARE @StageId INT
SELECT @StageId = StageId
FROM [control].[Stages]
WHERE StageName = @StageName

-- Get Depends On Stage Id
DECLARE @DependsOnStageId INT
SELECT @DependsOnStageId = StageId
FROM [control].[Stages]
WHERE StageName = @DependsOnStageName


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
--WHERE p.PipelineName LIKE 'Transform_PL_%'


SELECT @DependantPipelineIdResult = PipelineId 
FROM @DependenciesStagingTable
INNER JOIN transform.Datasets AS d
ON ParameterValue = d.DatasetId
WHERE ParameterValue = @DatasetId
AND StageId = @StageId

-- Get Dependency Dataset Id
IF @DependsOnStageName in ('Dimensions', 'Facts')
BEGIN
	SELECT @PipelineIdResult = PipelineId 
	FROM @DependenciesStagingTable
	INNER JOIN transform.Datasets AS d
	ON ParameterValue = d.DatasetId
	WHERE ParameterValue = @DependsOnDatasetId
	AND StageId = @DependsOnStageId
END
IF @DependsOnStageName in ('Cleansed')
BEGIN
	SELECT @PipelineIdResult = PipelineId 
	FROM @DependenciesStagingTable
	INNER JOIN ingest.Datasets AS d
	ON ParameterValue = d.DatasetId
	WHERE ParameterValue = @DependsOnDatasetId
	AND StageId = @DependsOnStageId
END


INSERT INTO @Dependencies (PipelineId,DependantPipelineId)
SELECT @PipelineIdResult, @DependantPipelineIdResult

IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
	RAISERROR('Missing Pipeline Ids for both Transform Dataset and the Dataset it depends on (Cleansed Merge Pipeline or Transform Dataset Pipeline)',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NOT NULL
BEGIN 
	RAISERROR('Missing PipelineId ',16,1)
    RETURN 0;
END
ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NULL
BEGIN 
	RAISERROR('Missing DependantPipelineId (Cleansed Merge Pipeline or Transform Dataset Pipeline)',16,1)
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

