CREATE PROCEDURE [control].[GetOrchestrationLineage] (
	-- Core
	@BatchName VARCHAR(255),

	-- Customisation
	@UseStatusColours BIT = 0,

	-- Filters
	@1_FilterFailedAndBlocked BIT = 0,

	@2_FilterDataset BIT = 0,
	@2_DatasetDetails VARCHAR(MAX) = '',
	
	@3_FilterDataSource BIT = 0,
	@3_FilterDataSourceByType BIT = 0,
	@3_DataSourceDetails VARCHAR(MAX) = '',
	
	-- Visualisation
	@SuccessColour VARCHAR(6) = '40B0A6',
	@FailedColour VARCHAR(6) = 'E66100',
	@BlockedColour VARCHAR(6) = 'DCDB88',
	@DefaultColour VARCHAR(6) = 'ECECFF'

) AS
	/* EXPERIMENTAL:
	1. Filter chain of only failed and blocked records
	2. Filter chain for specific Data Source
	3. Filter chain for specific Datasets
	*/

	SET NOCOUNT ON;

	-- Parameter Validation
	DECLARE @BatchExists BIT;

	SELECT 
		@BatchExists = CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END
	FROM [control].[Batches]
	WHERE BatchName = @BatchName;

	IF @BatchExists = 0
	BEGIN
		RAISERROR('Batch name specified does not exist within metadata.',16,1);
		RETURN;
	END

	IF (@3_FilterDataSource = 1 OR @3_FilterDataSourceByType = 1) AND @2_FilterDataset = 1
	BEGIN
		RAISERROR('Filtering Data Source and Specific Datasets is not an allowed combination currently.',16,1);
		RETURN;
	END

	IF (@3_FilterDataSource = 1 AND @3_FilterDataSourceByType = 1)
	BEGIN
		RAISERROR('Filtering Data Source and Data Sources by Type is not an allowed combination currently.',16,1);
		RETURN;
	END
	/*
	User requirements: I want to filter my results on a specific dataset.
	This includes any pipelines which interact directly with the dataset.
	This also includes any pipelines which are a dependency of pipelines interacting with the dataset.
	This also includes any pipelines which are a pre-requisite of pipelines interacting with the dataset.
	*/

	DECLARE @PipelineIds TABLE (
		PipelineId INT
	)
	
	IF @3_FilterDataSource = 1
	BEGIN
		WITH filteredConnections AS(
		SELECT c.ConnectionId
		FROM common.Connections c
		INNER JOIN OPENJSON(@3_DataSourceDetails)
		WITH (
			name VARCHAR(100) '$.name'
			) j
		ON c.ConnectionDisplayName = j.name
		)
		, filteredConnectionsJoin AS (
		SELECT p.pipelineid 
		FROM [control].[Pipelines] p
		INNER JOIN [control].[PipelineParameters] pp
			ON p.PipelineId = pp.PipelineId
		INNER JOIN [control].[Orchestrators] o
			ON p.[OrchestratorId] = o.[OrchestratorId]
		INNER JOIN [control].[Stages] s
			ON p.[StageId] = s.[StageId]
		INNER JOIN [control].[BatchStageLink] bs
			ON s.[StageId] = bs.[StageId]
		INNER JOIN [control].[Batches] b
			ON bs.[BatchId] = b.[BatchId]
		LEFT JOIN [ingest].[Datasets] id
			ON p.PipelineName like 'Ingest_PL_%'
			AND pp.ParameterValue = CAST(id.DatasetId AS CHAR(4))
		LEFT JOIN [transform].[Datasets] td
			ON p.PipelineName like 'Transform_PL_%'
			AND pp.ParameterValue = CAST(td.DatasetId AS CHAR(4)) 

		WHERE (
			id.ConnectionFK IN (SELECT ConnectionId FROM filteredConnections)
			)
		)

		INSERT INTO @PipelineIds (PipelineId)
		SELECT pd.pipelineid
		FROM filteredConnectionsJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId
		UNION
		SELECT pd.DependantPipelineId
		FROM filteredConnectionsJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId

	END
	IF @3_FilterDataSourceByType = 1
	BEGIN
		WITH filteredConnections AS(
		SELECT c.ConnectionId
		FROM common.Connections c
		INNER JOIN common.ConnectionTypes ct
		ON c.ConnectionTypeFK = ct.ConnectionTypeId
		INNER JOIN OPENJSON(@3_DataSourceDetails)
		WITH (
			name VARCHAR(100) '$.name'
			) j
		ON ct.ConnectionTypeDisplayName = j.name
		)
		, filteredConnectionsJoin AS (
		SELECT p.pipelineid 
		FROM [control].[Pipelines] p
		INNER JOIN [control].[PipelineParameters] pp
			ON p.PipelineId = pp.PipelineId
		INNER JOIN [control].[Orchestrators] o
			ON p.[OrchestratorId] = o.[OrchestratorId]
		INNER JOIN [control].[Stages] s
			ON p.[StageId] = s.[StageId]
		INNER JOIN [control].[BatchStageLink] bs
			ON s.[StageId] = bs.[StageId]
		INNER JOIN [control].[Batches] b
			ON bs.[BatchId] = b.[BatchId]
		LEFT JOIN [ingest].[Datasets] id
			ON p.PipelineName like 'Ingest_PL_%'
			AND pp.ParameterValue = CAST(id.DatasetId AS CHAR(4))
		LEFT JOIN [transform].[Datasets] td
			ON p.PipelineName like 'Transform_PL_%'
			AND pp.ParameterValue = CAST(td.DatasetId AS CHAR(4)) 

		WHERE (
			id.ConnectionFK IN (SELECT ConnectionId FROM filteredConnections)
			)
		)

		INSERT INTO @PipelineIds (PipelineId)
		SELECT pd.pipelineid
		FROM filteredConnectionsJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId
		UNION
		SELECT pd.DependantPipelineId
		FROM filteredConnectionsJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId

	END

	IF @2_FilterDataset = 1
	BEGIN

		WITH filteredDatasets AS(
		SELECT * 
		FROM OPENJSON(@2_DatasetDetails)
		WITH (name VARCHAR(100) '$.name' )
		)

		, filteredDatasetJoin AS (
		SELECT p.pipelineid 
		FROM [control].[Pipelines] p
		INNER JOIN [control].[PipelineParameters] pp
			ON p.PipelineId = pp.PipelineId
		INNER JOIN [control].[Orchestrators] o
			ON p.[OrchestratorId] = o.[OrchestratorId]
		INNER JOIN [control].[Stages] s
			ON p.[StageId] = s.[StageId]
		INNER JOIN [control].[BatchStageLink] bs
			ON s.[StageId] = bs.[StageId]
		INNER JOIN [control].[Batches] b
			ON bs.[BatchId] = b.[BatchId]
		LEFT JOIN [ingest].[Datasets] id
			ON p.PipelineName like 'Ingest_PL_%'
			AND pp.ParameterValue = CAST(id.DatasetId AS CHAR(4))
		LEFT JOIN [transform].[Datasets] td
			ON p.PipelineName like 'Transform_PL_%'
			AND pp.ParameterValue = CAST(td.DatasetId AS CHAR(4)) 

		WHERE (
			id.DatasetDisplayName IN (SELECT name FROM filteredDatasets)
			OR
			td.DatasetName IN (SELECT name FROM filteredDatasets)
			)
		)

		INSERT INTO @PipelineIds (PipelineId)
		SELECT pd.pipelineid
		FROM filteredDatasetJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId
		UNION
		SELECT pd.DependantPipelineId
		FROM filteredDatasetJoin cte
		INNER JOIN [control].PipelineDependencies pd
			ON cte.pipelineId = pd.DependantPipelineId
			OR cte.pipelineId = pd.PipelineId
	END
	ELSE
	BEGIN
		INSERT INTO @PipelineIds (PipelineId)
		SELECT PipelineId
		FROM [control].[Pipelines]
	END





	DECLARE @PageContent NVARCHAR(MAX) = '';
	DECLARE @BaseData TABLE
		(
		[OrchestratorId] INT NOT NULL,
		[OrchestratorName] NVARCHAR(200) NOT NULL,
		[StageId] INT NOT NULL,
		[StageName] VARCHAR(225) NOT NULL,
		[PipelineId] INT NOT NULL,
		[PipelineName] NVARCHAR(200) NOT NULL,
		[AdditionalPipelineInfo] NVARCHAR(500) NULL
		)
 
	-- Get LatestExecution counts 
	DECLARE @CountCurrentExecution INT;
	DECLARE @CountLatestExecution INT;

	SELECT @CountCurrentExecution = COUNT(*)
	FROM control.CurrentExecution;

	SELECT @CountLatestExecution = COUNT(*)
	FROM control.ExecutionLog; 

	--get reusable metadata

	INSERT INTO @BaseData
	SELECT
		o.[OrchestratorId],
		o.[OrchestratorName],
		s.[StageId],
		s.[StageName],
		p.[PipelineId],
		p.[PipelineName],
		CASE 
			WHEN id.DatasetId IS NOT NULL THEN CONCAT(' - ', id.DatasetDisplayName)
			WHEN td.DatasetId IS NOT NULL THEN CONCAT(' - ', td.DatasetName)
			ELSE '' 
		END
	FROM
		[control].[Pipelines] p
		INNER JOIN [control].[PipelineParameters] pp
			ON p.PipelineId = pp.PipelineId
		INNER JOIN [control].[Orchestrators] o
			ON p.[OrchestratorId] = o.[OrchestratorId]
		INNER JOIN [control].[Stages] s
			ON p.[StageId] = s.[StageId]
		INNER JOIN [control].[BatchStageLink] bs
			ON s.[StageId] = bs.[StageId]
		INNER JOIN [control].[Batches] b
			ON bs.[BatchId] = b.[BatchId]
		LEFT JOIN [ingest].[Datasets] id
			ON p.PipelineName like 'Ingest_PL_%'
			AND pp.ParameterValue = CAST(id.DatasetId AS CHAR(4))
		LEFT JOIN [transform].[Datasets] td
			ON p.PipelineName like 'Transform_PL_%'
			AND pp.ParameterValue = CAST(td.DatasetId AS CHAR(4)) 
		LEFT JOIN [control].[CurrentExecution] AS ce -- IF OR
			ON p.PipelineId = ce.PipelineId
			AND @CountCurrentExecution > 0
		LEFT JOIN [control].[ExecutionLog] AS el -- IF OR
			ON p.PipelineId = el.PipelineId
			AND @CountLatestExecution > 0 
			AND @CountCurrentExecution = 0
			AND el.LocalExecutionId = (
				SELECT TOP 1 LocalExecutionId FROM control.ExecutionLog ORDER BY LogId DESC)
			AND LogId IN (SELECT MAX(LogId) FROM control.ExecutionLog GROUP BY PipelineId)


	WHERE
		p.[Enabled] = 1
		AND b.[BatchName] = @BatchName
		AND (
			-- Filter for blocked and failed against current executions table
			(@1_FilterFailedAndBlocked = 1 AND @CountCurrentExecution > 0 AND ce.PipelineStatus IN ('Failed' , 'Blocked')) OR
			-- Filter for blocked and failed against latest executions table
			(@1_FilterFailedAndBlocked = 1 AND @CountLatestExecution > 0 AND @CountCurrentExecution = 0 AND el.PipelineStatus IN ('Failed' , 'Blocked')) OR
			-- No filter on pipeline status
			(@1_FilterFailedAndBlocked = 0))
		AND p.PipelineId IN (
			SELECT PipelineId
			FROM @PipelineIds
		);
 

	--add orchestrator(s) sub graphs
	;WITH orchestrators AS
		(
		SELECT DISTINCT
			[OrchestratorId],
			[OrchestratorName],
			'subgraph ' + [OrchestratorName] + CHAR(13) + 
			'style ' + [OrchestratorName] + ' fill:#F5F5F5,stroke:#F5F5F5' + CHAR(13) + 
			'##o' + CAST([OrchestratorId] * 10000 AS VARCHAR) + '##' + CHAR(13) + 'end' + CHAR(13)
			 AS OrchestratorSubGraphs
		FROM
			@BaseData
		)

	SELECT
		@PageContent += OrchestratorSubGraphs
	FROM
		orchestrators;


 
	--add stage sub graphs
	;WITH stages AS
		(
		SELECT DISTINCT
			[OrchestratorId],
			[StageName],
			[StageId]
		FROM
			@BaseData
		),
		stageSubs AS
		(
		SELECT
			[OrchestratorId],
			STRING_AGG('subgraph ' + [StageName] + CHAR(13) + 
				'style ' + [StageName] + ' fill:#E0E0E0,stroke:#E0E0E0' + CHAR(13) + 
				'##s' + CAST([StageId] AS VARCHAR) + '##' + CHAR(13) + 'end', CHAR(13)
				) AS 'StageSubGraphs'
		FROM
			stages
		GROUP BY
			[OrchestratorId]
		)
	SELECT     
		@PageContent = REPLACE(@PageContent,'##o' + CAST([OrchestratorId] * 10000 AS VARCHAR) + '##',[StageSubGraphs])
	FROM
		stageSubs;
 
	--add pipelines within stage

	DECLARE @LatestExecutions TABLE (
		[LocalExecutionId] [uniqueidentifier] NULL,
		[StageId] [int] NOT NULL,
		[PipelineId] [int] NOT NULL,
		[PipelineName] [nvarchar](200) NULL,
		[PipelineStatus] [nvarchar](200) NULL,
		[HexColour] [nvarchar](6) NOT NULL,
		[PipelinePrecedence] INT NULL
	)
	SELECT @CountCurrentExecution = COUNT(*)
	FROM control.CurrentExecution;

	SELECT @CountLatestExecution = COUNT(*)
	FROM control.ExecutionLog;


	IF @CountCurrentExecution > 0
	BEGIN
	--PRINT 'Current Execution'
	INSERT INTO @LatestExecutions (
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[PipelineName],
			[PipelineStatus],
			[HexColour],
			[PipelinePrecedence])
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[PipelineName],
			[PipelineStatus],
			CASE 
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Success' THEN @SuccessColour
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Failed' THEN @FailedColour
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Blocked' THEN @BlockedColour
				ELSE @DefaultColour
			END AS HexColour,		
			CASE 
				WHEN PipelineStatus = 'Success' THEN 0
				WHEN PipelineStatus = 'Failed' THEN 2
				WHEN PipelineStatus = 'Blocked' THEN 1
				ELSE 0
			END AS [PipelinePrecedence]
		FROM control.CurrentExecution
	END

	ELSE IF @CountCurrentExecution = 0 AND @CountLatestExecution > 0
	BEGIN
	--PRINT 'Latest Execution'
	INSERT INTO @LatestExecutions (
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[PipelineName],
			[PipelineStatus],
			[HexColour],
			[PipelinePrecedence])
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[PipelineName],
			[PipelineStatus],
			CASE 
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Success' THEN @SuccessColour
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Failed' THEN @FailedColour
				WHEN @UseStatusColours = 1 AND PipelineStatus = 'Blocked' THEN @BlockedColour
				ELSE @DefaultColour
			END AS HexColour,
			CASE 
				WHEN PipelineStatus = 'Success' THEN 0
				WHEN PipelineStatus = 'Failed' THEN 2
				WHEN PipelineStatus = 'Blocked' THEN 1
				ELSE 0
			END AS [PipelinePrecedence]
		FROM control.ExecutionLog
		WHERE LocalExecutionId = (
			SELECT TOP 1 LocalExecutionId FROM control.ExecutionLog ORDER BY LogId DESC)
		AND LogId IN (SELECT MAX(LogId) FROM control.ExecutionLog GROUP BY PipelineId)

	END

	ELSE IF @CountCurrentExecution = 0 AND @CountLatestExecution = 0
	BEGIN
	INSERT INTO @LatestExecutions (
			[PipelineId],
			[StageId],
			[HexColour])
		SELECT
			[PipelineId],
			[StageId],
			@DefaultColour AS HexColour
		FROM @BaseData
	END

	;WITH pipelines AS
		(
		SELECT
			BE.[StageId],
			STRING_AGG(
				CONCAT('p',CAST(BE.[PipelineId] * 10 AS VARCHAR),'(',BE.[PipelineName],BE.[AdditionalPipelineInfo],')',CHAR(13),
				'style ','p',CAST(BE.[PipelineId] * 10 AS VARCHAR),' fill:#',LE.[HexColour],',stroke:#',LE.[HexColour],''),CHAR(13)
				) AS 'PipelinesInStage'
		FROM
			@BaseData BE
		INNER JOIN 
			@LatestExecutions LE
		ON BE.PipelineId = LE.PipelineId
		--WHERE BE.StageId = 1
		GROUP BY
			BE.[StageId]
		)
	SELECT
		@PageContent = REPLACE(@PageContent,'##s' + CAST([StageId] AS VARCHAR) + '##',[PipelinesInStage])
	FROM
		pipelines


 
	--add stage nodes
	;WITH stageNodeExecutions AS (
		SELECT 
			BE.StageId,
			MAX(LE.PipelinePrecedence) AS StageStatus
		FROM 
			@BaseData BE
		LEFT JOIN 
			@LatestExecutions LE
		ON BE.PipelineId = LE.PipelineId
		GROUP BY BE.StageId
	),
	StageNodeStatuses AS (
		SELECT
			StageId
			,CASE 
				WHEN @UseStatusColours = 1 AND StageStatus = 0 THEN @SuccessColour
				WHEN @UseStatusColours = 1 AND StageStatus = 2 THEN @FailedColour
				WHEN @UseStatusColours = 1 AND StageStatus = 1 THEN @BlockedColour
				ELSE @DefaultColour
			END AS HexColour
		FROM stageNodeExecutions
	)

	,stageNodes AS
		(
		SELECT DISTINCT
			BE.[StageId],
			's' + CAST(BE.[StageId] * 100 AS VARCHAR) + '[' + BE.[StageName] + ']' + CHAR(13) +
			'style s' + CAST(BE.[StageId] * 100 AS VARCHAR) + ' fill:#' + SNS.HexColour + ',stroke:#'  + SNS.HexColour  + '''' + CHAR(13) AS StageNode
		FROM
			@BaseData BE
		LEFT JOIN 
			StageNodeStatuses SNS
		ON BE.StageId = SNS.StageId

		)
	SELECT
		@PageContent = @PageContent + [StageNode]
	FROM
		stageNodes
	ORDER BY
		[StageId];
 
	--add stage to pipeline relationships
	SELECT 
		@PageContent = @PageContent + 's' + CAST([StageId] * 100 AS VARCHAR) 
		+ ' --> ' + 'p' + CAST([PipelineId] * 10 AS VARCHAR) + CHAR(13)
	FROM
		@BaseData;
 
	--add stage to stage relationships
	;WITH maxStage AS
		(
		SELECT
			MAX([StageId]) -1 AS maxStageId
		FROM
			@BaseData
		),
		nextStage AS (
		SELECT DISTINCT
			a.[StageId],
			CASE 
				WHEN MIN(b.[StageId]) IS NULL THEN a.[StageId] + 1
				ELSE MIN(b.[StageId]) 
			END AS [NextStageId]
		FROM @BaseData a
		LEFT JOIN @BaseData b
			ON b.[StageId] > a.[StageId]

		GROUP BY a.[StageId]
		),
		stageToStage AS
		(
		SELECT DISTINCT
			's' + CAST(b.[StageId] * 100 AS VARCHAR) 
			+ ' ==> ' + 's' + CAST(n.[NextStageId] * 100 AS VARCHAR) + CHAR(13) AS Content
		FROM
			@BaseData b
		INNER JOIN nextStage n
		ON b.StageId = n.StageId
		CROSS JOIN maxStage
		WHERE
			b.[StageId] <= maxStage.[maxStageId]
		)

	SELECT
		@PageContent = @PageContent + [Content]
	FROM
		stageToStage

	--add pipeline to pipeline relationships
	;WITH pipelineRelationships AS (
		SELECT DISTINCT 'p' + CAST(pd.[PipelineId] * 10 AS VARCHAR) 
			+ ' -.- ' + 'p' + CAST(pd.[DependantPipelineId] * 10 AS VARCHAR) + CHAR(13) AS RelationshipTxt
		FROM
		[control].[PipelineDependencies] pd
		INNER JOIN @BaseData b1
			ON pd.[PipelineId] = b1.[PipelineId]
		INNER JOIN @BaseData b2
			ON pd.[DependantPipelineId] = b2.[PipelineId]
	)

	SELECT
		@PageContent = @PageContent + RelationshipTxt
	FROM
		pipelineRelationships;
	--add batch subgraph
	SELECT
		@PageContent = 'subgraph ' + [BatchName] + CHAR(13) +
		'style ' + @BatchName + ' fill:#DEEBF7,stroke:#DEEBF7' + CHAR(13) + @PageContent
	FROM
		[control].[Batches]
	WHERE
		[BatchName] = @BatchName;
 
	SET @PageContent = @PageContent + 'end';
 
	--add mermaid header
	DECLARE @PageHeader VARCHAR(1000) = '::: mermaid' + CHAR(13) + 'graph'
	IF @UseStatusColours = 1
	BEGIN
		SET @PageHeader = @PageHeader + CHAR(13) + 'subgraph Legend [Pipeline Status]' + CHAR(13) + 'style Legend fill:#FFFFFF,stroke:#FFFFFF' + CHAR(13) + 
		'success(Success)' + CHAR(13) + 'style success fill:#' + @SuccessColour +',stroke:#' + @SuccessColour + ',color:#FFFFFF' + CHAR(13) + 
		'failure(Failure)' + CHAR(13) + 'style failure fill:#' + @FailedColour + ',stroke:#' + @FailedColour + ',color:#FFFFFF' + CHAR(13) + 
		'blocked(Blocked)' + CHAR(13) + 'style blocked fill:#' + @BlockedColour + ',stroke:#' + @BlockedColour + ',color:#FFFFFF' + CHAR(13) + 
		'end'
	END
	SELECT
		@PageContent = @PageHeader + CHAR(13) + @PageContent + CHAR(13) + ':::';

	--return output
	PRINT CAST(@PageContent AS NTEXT);
