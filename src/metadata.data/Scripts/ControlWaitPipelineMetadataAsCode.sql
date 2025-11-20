-- Metadata as Code for Control Demo Wait Pipelines
MERGE INTO control.pipelines AS target
USING (
    SELECT
        o.OrchestratorId,
        s.StageId,
        p.PipelineName,
        p.Enabled
    FROM (
        VALUES
            ('$(ADFName)', 'ControlRaw', 'Wait 1', 1),
            ('$(ADFName)', 'ControlRaw', 'Wait 2', 1),
            ('$(ADFName)', 'ControlRaw', 'Wait 3', 1),
            ('$(ADFName)', 'ControlRaw', 'Intentional Error', 1),
            ('$(ADFName)', 'ControlCleansed', 'Wait 4', 1),
            ('$(ADFName)', 'ControlCleansed', 'Wait 5', 1),
            ('$(ADFName)', 'ControlCleansed', 'Wait 6', 1),
            ('$(ADFName)', 'ControlCleansed', 'Wait 7', 1),
            ('$(ADFName)', 'ControlCurated', 'Wait 8', 1),
            ('$(ADFName)', 'ControlCurated', 'Wait 9', 1),
            ('$(ADFName)', 'ControlCurated', 'Wait 10', 1)
    ) AS p(OrchestratorName, StageName, PipelineName, Enabled)
    INNER JOIN control.orchestrators o ON o.OrchestratorName = p.OrchestratorName
    INNER JOIN control.stages s ON s.StageName = p.StageName
) AS source (OrchestratorId, StageId, PipelineName, Enabled)
ON (
    target.OrchestratorId = source.OrchestratorId AND
    target.StageId = source.StageId AND
    target.PipelineName = source.PipelineName
)
WHEN MATCHED THEN
    UPDATE SET Enabled = source.Enabled
WHEN NOT MATCHED THEN
    INSERT (OrchestratorId, StageId, PipelineName, Enabled)
    VALUES (source.OrchestratorId, source.StageId, source.PipelineName, source.Enabled);


-- Metadata as Code for Control Demo Wait Pipeline Parameters
MERGE INTO control.pipelineparameters AS target
USING (
    SELECT
        p.PipelineId,
        params.ParameterName,
        params.ParameterValue
    FROM (
        VALUES
            ('Wait 1', 'WaitTime', '2'),
            ('Wait 2', 'WaitTime', '7'),
            ('Wait 3', 'WaitTime', '1'),
            ('Intentional Error', 'RaiseErrors', 'true'),
            ('Wait 4', 'WaitTime', '1'),
            ('Wait 5', 'WaitTime', '1'),
            ('Wait 6', 'WaitTime', '4'),
            ('Wait 7', 'WaitTime', '7'),
            ('Wait 8', 'WaitTime', '1'),
            ('Wait 9', 'WaitTime', '1'),
            ('Wait 10', 'WaitTime', '1')
    ) AS params(PipelineName, ParameterName, ParameterValue)
    INNER JOIN control.pipelines p
        ON p.PipelineName = params.PipelineName
) AS source (PipelineId, ParameterName, ParameterValue)
ON (
    target.PipelineId = source.PipelineId AND
    target.ParameterName = source.ParameterName
)
WHEN MATCHED THEN
    UPDATE SET ParameterValue = source.ParameterValue
WHEN NOT MATCHED THEN
    INSERT (PipelineId, ParameterName, ParameterValue)
    VALUES (source.PipelineId, source.ParameterName, source.ParameterValue);

-- Metadata as Code for Control Demo Wait Pipeline Dependencies
MERGE INTO control.PipelineDependencies AS target
USING (
    SELECT
        p.PipelineId,
        d.PipelineId AS DependantPipelineId
    FROM (
        VALUES
            ('Wait 1', 'Wait 4'),
            ('Wait 2', 'Wait 5'),
            ('Wait 3', 'Wait 6'),
            ('Intentional Error', 'Wait 7'),
            ('Wait 4', 'Wait 8'),
            ('Wait 5', 'Wait 8'),
            ('Wait 6', 'Wait 9'),
            ('Wait 7', 'Wait 10')
    ) AS deps(PipelineName, DependantPipelineName)
    INNER JOIN control.pipelines p
        ON p.PipelineName = deps.PipelineName
    INNER JOIN control.pipelines d
        ON d.PipelineName = deps.DependantPipelineName
) AS source (PipelineId, DependantPipelineId)
ON (
    target.PipelineId = source.PipelineId AND
    target.DependantPipelineId = source.DependantPipelineId
)
WHEN NOT MATCHED THEN
    INSERT (PipelineId, DependantPipelineId)
    VALUES (source.PipelineId, source.DependantPipelineId);