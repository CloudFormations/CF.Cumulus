CREATE PROCEDURE [control].[GetStages]
	(
	@ExecutionId UNIQUEIDENTIFIER
	)
AS
BEGIN
	SET NOCOUNT ON;

	--defensive check
	IF NOT EXISTS 
		( 
		SELECT
			1
		FROM 
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND ISNULL([PipelineStatus],'') <> 'Success'
		)
		BEGIN
			RAISERROR('Requested execution run does not contain any enabled stages/pipelines.',16,1);
			RETURN 0;
		END;

	SELECT DISTINCT 
		ce.[StageId]
		, s.[ExecutionOrderId]
	FROM 
		[control].[CurrentExecution] ce
	INNER JOIN 
		[control].[Stages] s
	ON 
		ce.StageId = s.StageId
	WHERE
		[LocalExecutionId] = @ExecutionId
		AND ISNULL([PipelineStatus],'') <> 'Success'
	ORDER BY 
		s.[ExecutionOrderId] ASC
END;