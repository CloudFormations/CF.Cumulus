CREATE PROCEDURE [common].[AddIngestOrTransformPayloadPipeline] (
	@ComponentName VARCHAR(25),
	@StageName VARCHAR(25),
	@PipelineName VARCHAR(50),
	@DatasetDisplayName VARCHAR(50),
	@OrchestratorName VARCHAR(50)
) AS


-- defensive check component in ('Ingest', 'Transform')
IF @ComponentName NOT IN ('Ingest', 'Transform')
BEGIN
    RAISERROR('This Functionality may only be used for adding Datasets from either Ingest or Transform schemas to the Control Pipeline. If you require different functionality to be added to control.pipelines, please proceed with a manual INSERT statement.',16,1)
	RETURN 0;
END

-- defensive check stage exists
DECLARE @StageId INT
DECLARE @StageCount INT

SELECT 
	@StageCount = COUNT(*)
FROM [control].[Stages]
WHERE StageName = @StageName

IF @StageCount = 0
BEGIN
    RAISERROR('No rows returned. Please review the Stage Details provided and confirm this is enabled.',16,1)
	RETURN 0;
END
IF @StageCount > 1
BEGIN
    RAISERROR('Multiple rows returned. Please review the Stage Details provided.',16,1)
	RETURN 0;
END


SELECT 
	@StageId = StageId
FROM [control].[stages]
WHERE StageName = @StageName

-- defensive checks only 1 dataset id returned
DECLARE @DatasetCount INT

IF @ComponentName = 'Ingest'
BEGIN
	SELECT @DatasetCount = COUNT(*)
	FROM [ingest].[Datasets] AS ids
	WHERE ids.Enabled = 1
	AND ids.DatasetDisplayName = @DatasetDisplayName
END

IF @ComponentName = 'Transform'
BEGIN
	SELECT @DatasetCount = COUNT(*)
	FROM [transform].[Datasets] AS tds
	WHERE tds.Enabled = 1
	AND tds.DatasetName = @DatasetDisplayName
END

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

-- Store all dataset ids associated with DatasetDisplayName
DECLARE @Datasets TABLE (
	DatasetId INT, 
	Enabled BIT
)


IF @ComponentName = 'Ingest'
BEGIN
	INSERT INTO @Datasets
	SELECT 
		DatasetId, Enabled
	FROM [ingest].[Datasets]
	WHERE DatasetDisplayName = @DatasetDisplayName
END

IF @ComponentName = 'Transform'
BEGIN
	INSERT INTO @Datasets
	SELECT 
		DatasetId, Enabled
	FROM [transform].[Datasets]
	WHERE DatasetName = @DatasetDisplayName
END

DECLARE @PipelineId INT

SELECT @PipelineId = p.PipelineId
FROM control.pipelines AS p
INNER JOIN control.pipelineparameters AS pp
ON p.PipelineId = pp.PipelineId
WHERE pp.parametervalue IN (SELECT CAST(datasetid AS VARCHAR(5))  FROM @Datasets)
AND pp.ParameterName = 'DatasetId'
AND p.PipelineName = @PipelineName

DECLARE @OrchestratorId INT

SELECT @OrchestratorId = OrchestratorId
FROM [control].[Orchestrators]
WHERE OrchestratorName = @OrchestratorName

IF @OrchestratorId IS NULL
BEGIN
	DECLARE @OrchestratorErrorMsg VARCHAR(150)
	SET @OrchestratorErrorMsg = 'No Orchestrator registered to the name ' + @OrchestratorName + '. Please confirm the correct Data Factory name is provided, and exists within this environment.'
	RAISERROR(@OrchestratorErrorMsg, 16,1)
	RETURN 0;
END

DECLARE @Enabled INT = 1

-- Store Pipeline Id corresponding to Dataset Id
DECLARE @Archive TABLE
(
   PipelineId INT
);

-- Update/Insert Dataset into pipelines table as required.
MERGE INTO control.pipelines AS target
USING (SELECT @PipelineId AS PipelineId) AS source
ON target.PipelineId = source.PipelineId
WHEN NOT MATCHED THEN
    INSERT (OrchestratorId, StageId, PipelineName, Enabled) VALUES (@OrchestratorId, @StageId, @PipelineName, @Enabled)
WHEN MATCHED THEN
    UPDATE SET target.PipelineName = @PipelineName
OUTPUT
   inserted.PipelineId AS PipelineId
   -- ,updated.PipelineId AS PipelineId
INTO @archive;

DECLARE @PipelineIdInserted INT

SELECT @PipelineIdInserted = PipelineId
FROM @Archive

-- Add Dataset Id as parameter of Pipeline created above
MERGE INTO control.PipelineParameters AS targetParams
USING (
    SELECT 
           @PipelineIdInserted AS PipelineId,
		   'DatasetId' AS ParameterName,
           CAST(DatasetId AS VARCHAR(5)) AS ParameterValue,
		   CAST(DatasetId AS VARCHAR(5)) AS ParameterValueLastUsed
	FROM @Datasets
	WHERE Enabled = 1
) AS sourceParams
ON targetParams.PipelineId = sourceParams.PipelineId
   AND targetParams.ParameterName = 'DatasetId'
WHEN NOT MATCHED THEN
    INSERT (PipelineId, ParameterName, ParameterValue, ParameterValueLastUsed)
    VALUES (sourceParams.PipelineId, 'DatasetId', sourceParams.ParameterValue, sourceParams.ParameterValueLastUsed)
WHEN MATCHED THEN
    UPDATE SET targetParams.ParameterValue = sourceParams.ParameterValue;




GO

