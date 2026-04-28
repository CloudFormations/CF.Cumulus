--PipelineProcesses
IF EXISTS 
	(
	SELECT
		* 
	FROM
		sys.objects o
		INNER JOIN sys.schemas s
			ON o.[schema_id] = s.[schema_id]
	WHERE
		o.[name] = 'PipelineProcesses'
		AND s.[name] = 'procfwk'
		AND o.[type] = 'U' --Check for tables as created synonyms to support backwards compatability
	)
	BEGIN
		--drop just to avoid constraints
		IF OBJECT_ID(N'[control].[PipelineParameters]') IS NOT NULL DROP TABLE [control].[PipelineParameters];
		IF OBJECT_ID(N'[control].[PipelineAuthLink]') IS NOT NULL DROP TABLE [control].[PipelineAuthLink];

		SELECT * INTO [dbo].[zz_PipelineProcesses] FROM [control].[PipelineProcesses];

		DROP TABLE [control].[PipelineProcesses];
	END

--ProcessingStageDetails
IF EXISTS 
	(
	SELECT
		* 
	FROM
		sys.objects o
		INNER JOIN sys.schemas s
			ON o.[schema_id] = s.[schema_id]
	WHERE
		o.[name] = 'ProcessingStageDetails'
		AND s.[name] = 'procfwk'
		AND o.[type] = 'U' --Check for tables as created synonyms to support backwards compatability
	)
	BEGIN
		SELECT * INTO [dbo].[zz_ProcessingStageDetails] FROM [control].[ProcessingStageDetails];
		
		DROP TABLE [control].[ProcessingStageDetails];
	END;

--DataFactoryDetails
IF EXISTS 
	(
	SELECT
		* 
	FROM
		sys.objects o
		INNER JOIN sys.schemas s
			ON o.[schema_id] = s.[schema_id]
	WHERE
		o.[name] = 'DataFactoryDetails'
		AND s.[name] = 'procfwk'
		AND o.[type] = 'U' --Check for tables as created synonyms to support backwards compatability
	)
	BEGIN
		SELECT * INTO [dbo].[zz_DataFactoryDetails] FROM [control].[DataFactoryDetails];
		
		DROP TABLE [control].[DataFactoryDetails];
	END;

--DataFactorys
IF EXISTS 
	(
	SELECT
		* 
	FROM
		sys.objects o
		INNER JOIN sys.schemas s
			ON o.[schema_id] = s.[schema_id]
	WHERE
		o.[name] = 'DataFactorys'
		AND s.[name] = 'procfwk'
		AND o.[type] = 'U' --Check for tables as created synonyms to support backwards compatability
	)
	BEGIN
		SELECT * INTO [dbo].[zz_DataFactorys] FROM [control].[DataFactorys];
	END;