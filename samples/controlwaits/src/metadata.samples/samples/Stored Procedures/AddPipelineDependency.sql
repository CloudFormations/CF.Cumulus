CREATE PROCEDURE [samples].[AddPipelineDependency] (
    @PipelineName VARCHAR(200),
    @StageName VARCHAR(50),
    @ParameterName VARCHAR(128),
    @ParameterValue NVARCHAR(MAX),
    @DependantPipelineName VARCHAR(200),
    @DependantStageName VARCHAR(50),
    @DependantParameterName VARCHAR(128),
    @DependantParameterValue NVARCHAR(MAX)
) AS

DECLARE @StageId INT
DECLARE @DependantStageId INT
DECLARE @PipelineIdResult INT
DECLARE @DependantPipelineIdResult INT

-- Validate stage
DECLARE @StageCount INT

SELECT @StageCount = COUNT(*)
FROM [control].[Stages]
WHERE StageName = @StageName

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

SELECT @StageId = StageId
FROM [control].[Stages]
WHERE StageName = @StageName

-- Validate dependant stage
DECLARE @DependantStageCount INT

SELECT @DependantStageCount = COUNT(*)
FROM [control].[Stages]
WHERE StageName = @DependantStageName

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

SELECT @DependantStageId = StageId
FROM [control].[Stages]
WHERE StageName = @DependantStageName

-- Resolve pipeline
DECLARE @PipelineCount INT

SELECT @PipelineCount = COUNT(*)
FROM [control].[Pipelines] AS p
INNER JOIN [control].[PipelineParameters] AS pp ON p.PipelineId = pp.PipelineId
AND p.PipelineName = @PipelineName
AND p.StageId = @StageId
AND pp.ParameterName = @ParameterName
AND pp.ParameterValue = @ParameterValue

IF @PipelineCount = 0
BEGIN
    RAISERROR('No pipeline found matching the PipelineName, StageName, ParameterName and ParameterValue provided.',16,1)
    RETURN 0;
END
IF @PipelineCount > 1
BEGIN
    RAISERROR('More than 1 pipeline found matching the criteria provided. Please review the parameters.',16,1)
    RETURN 0;
END

SELECT @PipelineIdResult = p.PipelineId
FROM [control].[Pipelines] AS p
INNER JOIN [control].[PipelineParameters] AS pp ON p.PipelineId = pp.PipelineId
AND p.PipelineName = @PipelineName
AND p.StageId = @StageId
AND pp.ParameterName = @ParameterName
AND pp.ParameterValue = @ParameterValue

-- Resolve dependant pipeline
DECLARE @DependantPipelineCount INT

SELECT @DependantPipelineCount = COUNT(*)
FROM [control].[Pipelines] AS p
INNER JOIN [control].[PipelineParameters] AS pp ON p.PipelineId = pp.PipelineId
AND p.PipelineName = @DependantPipelineName
AND p.StageId = @DependantStageId
AND pp.ParameterName = @DependantParameterName
AND pp.ParameterValue = @DependantParameterValue

IF @DependantPipelineCount = 0
BEGIN
    RAISERROR('No dependant pipeline found matching the DependantPipelineName, DependantStageName, DependantParameterName and DependantParameterValue provided.',16,1)
    RETURN 0;
END
IF @DependantPipelineCount > 1
BEGIN
    RAISERROR('More than 1 dependant pipeline found matching the criteria provided. Please review the parameters.',16,1)
    RETURN 0;
END

SELECT @DependantPipelineIdResult = p.PipelineId
FROM [control].[Pipelines] AS p
INNER JOIN [control].[PipelineParameters] AS pp ON p.PipelineId = pp.PipelineId
AND p.PipelineName = @DependantPipelineName
AND p.StageId = @DependantStageId
AND pp.ParameterName = @DependantParameterName
AND pp.ParameterValue = @DependantParameterValue

-- Insert dependency
DECLARE @Dependencies TABLE (
    PipelineId INT,
    DependantPipelineId INT
)

INSERT INTO @Dependencies (PipelineId, DependantPipelineId)
VALUES (@PipelineIdResult, @DependantPipelineIdResult)

MERGE INTO control.PipelineDependencies AS target
USING @Dependencies AS source
ON target.PipelineId = source.PipelineId
AND target.DependantPipelineId = source.DependantPipelineId
WHEN NOT MATCHED THEN
    INSERT (PipelineId, DependantPipelineId) VALUES (source.PipelineId, source.DependantPipelineId);

PRINT 'Dependencies merged into control.PipelineDependencies'
GO
