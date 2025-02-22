CREATE PROCEDURE [samples].[SetSamplePipelines]
AS
BEGIN
	DECLARE @Pipelines TABLE
		(
		[OrchestratorId] [INT] NOT NULL,
		[StageId] [INT] NOT NULL,
		[PipelineName] [NVARCHAR](200) NOT NULL,
		[LogicalPredecessorId] [INT] NULL,
		[Enabled] [BIT] NOT NULL
		)

	INSERT @Pipelines
		(
		[OrchestratorId],
		[StageId],
		[PipelineName], 
		[LogicalPredecessorId],
		[Enabled]
		) 
	VALUES 
		(1,6	,'Wait 1'				,NULL		,1),
		(1,7	,'Wait 2'				,NULL		,1);

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
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE;	
END;