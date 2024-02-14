CREATE PROCEDURE [dbo].[DemoModePrecursor]
AS
BEGIN

	--quick win
	IF ([control].[GetPropertyValueInternal]('ExecutionPrecursorProc')) <> '[dbo].[DemoModePrecursor]'
	BEGIN
		EXEC [procfwkHelpers].[AddProperty]
			@PropertyName = N'ExecutionPrecursorProc',
			@PropertyValue = N'[dbo].[DemoModePrecursor]';
	END;

	--reduce wait times
	;WITH cte AS
		(
		SELECT 
			[PipelineId],
			LEFT(ABS(CAST(CAST(NEWID() AS VARBINARY(192)) AS INT)),1) AS NewValue
		FROM 
			[control].[PipelineParameters]
		)
	UPDATE
		pp
	SET
		pp.[ParameterValue] = cte.[NewValue]
	FROM
		[control].[PipelineParameters] pp
		INNER JOIN cte
			ON pp.[PipelineId] = cte.[PipelineId]
		INNER JOIN [control].[Pipelines] p
			ON pp.[PipelineId] = p.[PipelineId]
	WHERE
		pp.[ParameterName] LIKE 'Wait%'
		AND p.[Enabled] = 1;


	--for intentional error
	IF NOT EXISTS
		(
		SELECT * FROM [control].[CurrentExecution]
		)
		BEGIN
			UPDATE
				pp
			SET
				pp.[ParameterValue] = 'true'
			FROM
				[control].[PipelineParameters] pp
				INNER JOIN [control].[Pipelines] p
					ON pp.[PipelineId] = p.[PipelineId]
			WHERE
				p.[PipelineName] = 'Intentional Error'
				AND pp.[ParameterName] = 'RaiseErrors';
		END;
		ELSE
		BEGIN
			UPDATE
				pp
			SET
				pp.[ParameterValue] = 'false'
			FROM
				[control].[PipelineParameters] pp
				INNER JOIN [control].[Pipelines] p
					ON pp.[PipelineId] = p.[PipelineId]
			WHERE
				p.[PipelineName] = 'Intentional Error'
				AND pp.[ParameterName] = 'RaiseErrors';
		END;

	--dependency chain failure handling
	IF ([control].[GetPropertyValueInternal]('FailureHandling')) <> 'DependencyChain'
	BEGIN
		EXEC [procfwkHelpers].[AddProperty]
			@PropertyName = N'FailureHandling',
			@PropertyValue = N'DependencyChain';
	END;


	--short infant iterations
	IF ([control].[GetPropertyValueInternal]('PipelineStatusCheckDuration')) <> '5'
	BEGIN
		EXEC [procfwkHelpers].[AddProperty]
			@PropertyName = N'PipelineStatusCheckDuration',
			@PropertyValue = N'5';
		END;
END;