CREATE PROCEDURE [ingest].[AddIngestPayloadPipeline] (
	@StageName VARCHAR(25),
	@PipelineName VARCHAR(50),
	@DatasetDisplayName VARCHAR(50),
	@OrchestratorName VARCHAR(50)
) AS
DECLARE @StageId INT
DECLARE @StageCount INT

-- defensive check stage exists
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

SELECT @DatasetCount = COUNT(*)
FROM [ingest].[Datasets] AS ds
WHERE ds.Enabled = 1
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

-- Store all dataset ids associated with DatasetDisplayName
DECLARE @Datasets TABLE (
	DatasetId INT, 
	Enabled BIT
)


INSERT INTO @Datasets
SELECT 
    DatasetId, Enabled
FROM [ingest].[Datasets]
WHERE DatasetDisplayName = @DatasetDisplayName

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
	SET @OrchestratorErrorMsg = 'No Orchestrator Registered to the name ' + @OrchestratorName + '. Please confirm the correct Data Factory name is provided, and exists within this environment.'
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

