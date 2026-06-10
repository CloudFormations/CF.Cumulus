CREATE PROCEDURE [samples].[AddWaitPipeline]
(
    @PipelineName NVARCHAR(200),
    @OrchestratorName NVARCHAR(200),
    @StageName NVARCHAR(200),
    @ParameterName NVARCHAR(200),
    @ParameterValue NVARCHAR(200),
    @LogicalPredecessorName NVARCHAR(200) = NULL,
    @Enabled BIT = 1
)
AS
BEGIN
	DECLARE @Pipelines TABLE
		(
		[OrchestratorId] [INT] NOT NULL,
        [OrchestratorName] NVARCHAR(200),
		[StageId] [INT] NOT NULL,
		[StageName] NVARCHAR(200) NOT NULL,
		[PipelineName] [NVARCHAR](200) NOT NULL,
        [ParameterName] NVARCHAR(200) NULL,
        [ParameterValue] NVARCHAR(200) NULL,
		[LogicalPredecessorId] [INT] NULL,
		[Enabled] [BIT] NOT NULL
		)

	INSERT @Pipelines
		(
		[OrchestratorId],
		[OrchestratorName],
		[StageId],
		[StageName],
		[PipelineName], 
        [ParameterName],
        [ParameterValue],
		[LogicalPredecessorId],
		[Enabled]
		) 
	VALUES 
		(-1, @OrchestratorName, -1, @StageName, @PipelineName, @ParameterName, @ParameterValue, @LogicalPredecessorName, @Enabled);

    UPDATE @Pipelines
    SET OrchestratorId = c.OrchestratorId
    FROM @Pipelines p
    JOIN [control].[Orchestrators] c ON c.OrchestratorName = p.OrchestratorName;

    UPDATE @Pipelines
    SET StageId = c.StageId
    FROM @Pipelines p
    JOIN [control].[Stages] c ON c.StageName = p.StageName;

    -- Store Pipeline Id corresponding to Wait
    DECLARE @Archive TABLE
    (
    PipelineId INT
    );

	MERGE INTO [control].[Pipelines] AS tgt
	USING 
		@Pipelines AS src
			ON tgt.[OrchestratorId] = src.[OrchestratorId]
				AND tgt.[PipelineName] = src.[PipelineName]
				AND tgt.[StageId] = src.[StageId]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[LogicalPredecessorId] = src.[LogicalPredecessorId],
			tgt.[Enabled] = src.[Enabled]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[OrchestratorId],
			[StageId],
			[PipelineName], 
			[LogicalPredecessorId],
			[Enabled]
			)
		VALUES
			(
			src.[OrchestratorId],
			src.[StageId],
			src.[PipelineName], 
			src.[LogicalPredecessorId],
			src.[Enabled]
            )
        OUTPUT
            inserted.PipelineId AS PipelineId
        -- ,updated.PipelineId AS PipelineId
        INTO @Archive;

    IF @ParameterName IS NOT NULL
    BEGIN
        DECLARE @PipelineIdInserted INT

        SELECT @PipelineIdInserted = PipelineId
        FROM @Archive

        -- Add Pipeline Parameters
        MERGE INTO control.PipelineParameters AS targetParams
        USING (
            SELECT 
                @PipelineIdInserted AS PipelineId,
                @ParameterName AS ParameterName,
                @ParameterValue AS ParameterValue,
                @ParameterValue AS ParameterValueLastUsed
        ) AS sourceParams
        ON targetParams.PipelineId = sourceParams.PipelineId
        WHEN NOT MATCHED THEN
            INSERT (PipelineId, ParameterName, ParameterValue, ParameterValueLastUsed)
            VALUES (sourceParams.PipelineId, sourceParams.ParameterName, sourceParams.ParameterValue, sourceParams.ParameterValueLastUsed)
        WHEN MATCHED THEN
            UPDATE SET targetParams.ParameterValue = sourceParams.ParameterValue;
    END
END;