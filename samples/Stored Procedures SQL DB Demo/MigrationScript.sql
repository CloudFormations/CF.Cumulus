--USE [Metadata-db]
DECLARE @MigrateCommon BIT = 1;
DECLARE @MigrateTransform BIT = 1;
DECLARE @MigrateControl BIT = 1;
DECLARE @MigrateIngest BIT = 1;
DECLARE @MigrateRoles BIT = 1;
DECLARE @MigrateCustomerProcs BIT = 0;
DECLARE @ADFUserName VARCHAR(100) = 'FrameworkDataFactory';
DECLARE @OverrideADFUserCheck BIT = 0;
DECLARE @TotalRowCountBefore INT;
DECLARE @TotalRowCountAfter INT;

-- Get counts before
-- BEGIN
-- 	DROP TABLE IF EXISTS #countsBefore;
-- 	DROP TABLE IF EXISTS #countsAfter;
-- 	DROP TABLE IF EXISTS #countsExclusion;

-- 	CREATE TABLE #countsBefore
-- 	(
-- 		table_name varchar(255),
-- 		row_count int
-- 	);
-- 	CREATE TABLE #countsAfter
-- 	(
-- 		table_name varchar(255),
-- 		row_count int
-- 	);
-- 	CREATE TABLE #countsExclusion
-- 	(
-- 		table_name varchar(255)
-- 	);
-- 	INSERT INTO #countsExclusion (table_name)
-- 	VALUES ('[ingest].[Attributes_12112024]'),('[ingest].[Attributes_29_10_2024]'),('[ingest].[Attributes_7022025]'),('[ingest].[attributesClone]'),('[ingest].[AuditAttributes]'),
-- 		('[ingest].[Datasets_11112024]'),('[ingest].[Datasets_12112024]'),('[ingest].[Datasets_29_10_2024]'),('[ingest].[Datasets_31012025]'),
-- 		('[control].[PipelineDependencies_19112024]'),('[control].[PipelineParameters_15112024]'),('[control].[Pipelines_15112024]');

-- 	EXEC sp_MSForEachTable @command1='INSERT #countsBefore (table_name, row_count) SELECT ''?'', COUNT(*) FROM ?';
-- 	--SELECT table_name, row_count FROM #countsBefore ORDER BY table_name, row_count DESC
-- 	SELECT @TotalRowCountBefore = SUM(row_count) FROM #countsBefore 
-- 	WHERE table_name NOT IN 
-- 		(select table_name FROM #countsExclusion);
-- END

IF @OverrideADFUserCheck = 0
BEGIN
IF @@SERVERNAME LIKE '%dev%' AND @ADFUserName NOT LIKE '%dev%'
BEGIN
	RAISERROR('Deploying a dev ADF user to a non-dev SQL Server metadata database. Please verify connection is set correctly.',16,1);
END
ELSE IF (@@SERVERNAME LIKE '%test%' OR @@SERVERNAME LIKE '%tst%') AND (@ADFUserName NOT LIKE '%test%' AND @ADFUserName NOT LIKE '%tst%')
BEGIN
	RAISERROR('Deploying a test ADF user to a non-test SQL Server metadata database. Please verify connection is set correctly.',16,1);
END
ELSE IF (@@SERVERNAME LIKE '%prod%' OR @@SERVERNAME LIKE '%prd%') AND (@ADFUserName NOT LIKE '%prod%' AND @ADFUserName NOT LIKE '%prd%')
BEGIN
	RAISERROR('Deploying a prod ADF user to a non-prod SQL Server metadata database. Please verify connection is set correctly.',16,1);
END
END

BEGIN TRY

  BEGIN TRANSACTION COMMONSCHEMA


PRINT N''
IF @MigrateCommon = 1
BEGIN 
PRINT N'----------------------- Migrate [common] schema -----------------------'

/*
Migrate Schema
*/
BEGIN

	IF NOT EXISTS (
		SELECT * 
		FROM sys.schemas
		WHERE name = 'common' 
		)
	BEGIN
		PRINT N'Schema [common] does not exist. Creating...'
		EXEC ('CREATE SCHEMA [common]');
		PRINT N'Schema [common] has been created'

	END
END
/*
Migrate Tables
-- common.Connections
-- common.ComputeConnections
-- common.ConnectionTypes
*/
BEGIN

-- common.Connections
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [common].[Connections] -----';
	PRINT N'Checking for existing table [common].[Connections]...';

	-- Migration Case 1: common.Connections already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'Connections')
	
	BEGIN
		PRINT N'Table [common].[Connections] exists, creating a copy';
		EXEC sp_rename 'common.Connections', 'Connections_Migration';
		

	END

	-- Migration Case 2: historic ingest.Connections exists
	ELSE IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'Connections')
	
	BEGIN
		PRINT N'Table [ingest].[Connections] exists, creating a copy';
		ALTER SCHEMA common TRANSFER ingest.Connections;
		EXEC sp_rename 'common.Connections', 'Connections_Migration';
		ALTER TABLE common.Connections_Migration ADD ResourceName AS (AzureResourceName);  
	END

	PRINT N'Creating new table [common].[Connections]...';

	CREATE TABLE [common].[Connections] (
		[ConnectionId]          INT            IDENTITY (1, 1) NOT NULL,
		[ConnectionTypeFK]      INT            NOT NULL,
		[ConnectionDisplayName] NVARCHAR (50)  NOT NULL,
		[ConnectionLocation]    NVARCHAR (200) NULL,
		[ConnectionPort]        NVARCHAR (50)  NULL,
		[SourceLocation]        NVARCHAR (200) NOT NULL,
		[ResourceName]          NVARCHAR (100) NULL,
		[LinkedServiceName]     NVARCHAR (200) NOT NULL,
		[Username]              NVARCHAR (100) NOT NULL,
		[KeyVaultSecret]        NVARCHAR (100) NOT NULL,
		[Enabled]               BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([ConnectionId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [common].[Connections] created';
	PRINT N'Migrating data to new table [common].[Connections]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'Connections_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [common].[Connections_Migration])
		BEGIN
			SET IDENTITY_INSERT [common].[Connections] ON;
			INSERT INTO [common].[Connections] ([ConnectionId],[ConnectionTypeFK],[ConnectionDisplayName],[ConnectionLocation],[ConnectionPort],[SourceLocation],[ResourceName],[LinkedServiceName],[Username],[KeyVaultSecret],[Enabled])
			SELECT  
				[ConnectionId],
				[ConnectionTypeFK],
				[ConnectionDisplayName],
				[ConnectionLocation],
				[ConnectionPort],
				[SourceLocation],
				[ResourceName],
				[LinkedServiceName],
				[Username],
				[KeyVaultSecret],
				[Enabled]
			FROM     [common].[Connections_Migration]
			ORDER BY [ConnectionId] ASC;
			SET IDENTITY_INSERT [common].[Connections] OFF;
		END
	END

	PRINT N'Migrated data to new table [common].[Connections]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [common].[Connections_Migration];
	END

-- common.ComputeConnections
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [common].[ComputeConnections] -----';
	PRINT N'Checking for existing table [common].[ComputeConnections]...';

	-- Migration Case 1: common.ComputeConnections already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'ComputeConnections')
	
	BEGIN
		PRINT N'Table [common].[ComputeConnections] exists, creating a copy';
		EXEC sp_rename 'common.ComputeConnections', 'ComputeConnections_Migration';
		

	END

	-- Migration Case 2: historic ingest.ComputeConnections exists
	ELSE IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'ComputeConnections')
	
	BEGIN
		PRINT N'Table [ingest].[ComputeConnections] exists, creating a copy';
		ALTER SCHEMA common TRANSFER ingest.ComputeConnections;
		EXEC sp_rename 'common.ComputeConnections', 'ComputeConnections_Migration';
		ALTER TABLE common.ComputeConnections_Migration ADD ResourceName AS (AzureResourceName);  
	END

	PRINT N'Creating new table [common].[ComputeConnections]...';

	CREATE TABLE [common].[ComputeConnections](
		[ComputeConnectionId] [int] IDENTITY(1,1) NOT NULL,
		[ConnectionTypeFK] [int] NOT NULL,
		[ConnectionDisplayName] [nvarchar](50) NOT NULL,
		[ConnectionLocation] [nvarchar](200) NULL,
		[ComputeLocation] [nvarchar](200) NULL,
		[ComputeSize] [nvarchar](200) NOT NULL,
		[ComputeVersion] [nvarchar](100) NOT NULL,
		[CountNodes] int NOT NULL,
		[ResourceName] [nvarchar](100) NULL,
		[LinkedServiceName] [nvarchar](200) NOT NULL,
		[EnvironmentName] [nvarchar](10) NULL,
		[Enabled] [bit] NOT NULL
	PRIMARY KEY CLUSTERED 
	(
		[ComputeConnectionId] ASC
	)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];

	PRINT N'Table [common].[ComputeConnections] created';
	PRINT N'Migrating data to new table [common].[ComputeConnections]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'ComputeConnections_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
				FROM   [common].[ComputeConnections_Migration])
		BEGIN
			SET IDENTITY_INSERT [common].[ComputeConnections] ON;
			INSERT INTO [common].[ComputeConnections] ([ComputeConnectionId], [ConnectionTypeFK], [ConnectionDisplayName], [ConnectionLocation], [ComputeLocation], [ComputeSize], [ComputeVersion], [CountNodes], [ResourceName], [LinkedServiceName], [EnvironmentName], [Enabled])
			SELECT  
				[ComputeConnectionId],
				[ConnectionTypeFK],
				[ConnectionDisplayName],
				[ConnectionLocation],
				[ComputeLocation],
				[ComputeSize],
				[ComputeVersion],
				[CountNodes],
				[ResourceName],
				[LinkedServiceName],
				[EnvironmentName],
				[Enabled]
			FROM     [common].[ComputeConnections_Migration]
			ORDER BY [ComputeConnectionId] ASC;
			SET IDENTITY_INSERT [common].[ComputeConnections] OFF;
		END
	END

	PRINT N'Migrated data to new table [common].[ComputeConnections]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [common].[ComputeConnections_Migration];
	END

-- Common.ConnectionTypes
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [common].[ConnectionTypes] -----';
	PRINT N'Checking for existing Table [common].[ConnectionTypes]...';

	-- Migration Case 1: common.ConnectionTypes already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'ConnectionTypes')
	
	BEGIN
		PRINT N'Table [common].[ConnectionTypes] exists, creating a copy';
		EXEC sp_rename 'common.ConnectionTypes', 'ConnectionTypes_Migration';

	END

	-- Migration Case 2: historic ingest.ConnectionTypes exists
	ELSE IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'ConnectionTypes')
	
	BEGIN
		PRINT N'Table [ingest].[ConnectionTypes] exists, creating a copy';
		ALTER SCHEMA common TRANSFER ingest.ConnectionTypes;
		EXEC sp_rename 'common.ConnectionTypes', 'ConnectionTypes_Migration';
	END

	PRINT N'Creating new table [common].[ConnectionTypes]...';

	CREATE TABLE [common].[ConnectionTypes](
		[ConnectionTypeId]          INT           IDENTITY (1, 1) NOT NULL,
		[SourceLanguageType]        VARCHAR (5)   NULL,
		[ConnectionTypeDisplayName] NVARCHAR (50) NOT NULL,
		[Enabled]                   BIT           NOT NULL,
		PRIMARY KEY CLUSTERED ([ConnectionTypeId] ASC) ON [PRIMARY]
	) ON [PRIMARY];

	PRINT N'Table [common].[ConnectionTypes] created';
	PRINT N'Migrating data to new table [common].[ConnectionTypes]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'common' 
		AND  TABLE_NAME = 'ConnectionTypes_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [common].[ConnectionTypes_Migration])
		BEGIN
			SET IDENTITY_INSERT [common].[ConnectionTypes] ON;
			INSERT INTO [common].[ConnectionTypes] ([ConnectionTypeId], [SourceLanguageType], [ConnectionTypeDisplayName], [Enabled])
			SELECT  
				[ConnectionTypeId], 
				[SourceLanguageType], 
				[ConnectionTypeDisplayName], 
				[Enabled]
			FROM     [common].[ConnectionTypes_Migration]
			ORDER BY [ConnectionTypeId] ASC;
			SET IDENTITY_INSERT [common].[ConnectionTypes] OFF;
		END
    END

	PRINT N'Migrated data to new table [common].[ConnectionTypes]';
	PRINT N'Drop historic table';
	
	DROP TABLE IF EXISTS [common].[ConnectionTypes_Migration];
	END
END
/*
Migrate Table Constraints
*/	
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [common] Table Constraints -----';
	
	PRINT N'Creating Foreign Key [common].[FK__Connectio__Conne__361223C6]...';
	ALTER TABLE [common].[ComputeConnections] WITH NOCHECK
		ADD CONSTRAINT [FK__Connectio__Conne__361223C6] FOREIGN KEY ([ConnectionTypeFK]) REFERENCES [common].[ConnectionTypes] ([ConnectionTypeId]);

	PRINT N'Creating Foreign Key [common].[FK__Connectio__Conne__361203C5]...';
	ALTER TABLE [common].[Connections] WITH NOCHECK
		ADD CONSTRAINT [FK__Connectio__Conne__361203C5] FOREIGN KEY ([ConnectionTypeFK]) REFERENCES [common].[ConnectionTypes] ([ConnectionTypeId]);

	PRINT N'Creating Check Constraint [common].[chkComputeConnectionDisplayNameNoSpaces]...';
	ALTER TABLE [common].[ComputeConnections] WITH NOCHECK
		ADD CONSTRAINT [chkComputeConnectionDisplayNameNoSpaces] CHECK ((NOT [ConnectionDisplayName] like '% %'));

	PRINT N'Creating Check Constraint [common].[chkConnectionDisplayNameNoSpaces]...';
	ALTER TABLE [common].[Connections] WITH NOCHECK
		ADD CONSTRAINT [chkConnectionDisplayNameNoSpaces] CHECK ((NOT [ConnectionDisplayName] like '% %'));
END

/*
Migrate Stored Procedures
- common.AddConnectionType
*/
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [common].[AddConnectionType] Stored Procedure -----';

	PRINT N'Creating [common].[AddConnectionType] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[common].[AddConnectionType]'))
	BEGIN
		EXEC('CREATE PROCEDURE [common].[AddConnectionType] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [common].[AddConnectionType]';
	EXEC('
	ALTER PROCEDURE [common].[AddConnectionType]
		(
		@ConnectionTypeDisplayName NVARCHAR(128),
		@SourceLanguageType NVARCHAR(5),
		@Enabled BIT
		)
	AS
	BEGIN
		MERGE INTO  [common].[ConnectionTypes] AS target
			USING 
				(SELECT
					@ConnectionTypeDisplayName AS ConnectionTypeDisplayName
					, @SourceLanguageType AS SourceLanguageType
					, @Enabled AS Enabled
				) AS source (ConnectionTypeDisplayName, SourceLanguageType, Enabled)
			ON ( target.ConnectionTypeDisplayName = source.ConnectionTypeDisplayName )
			WHEN MATCHED
				THEN UPDATE
					SET 
						SourceLanguageType = source.SourceLanguageType
						, Enabled = source.Enabled
			WHEN NOT MATCHED
				THEN INSERT
					(
						SourceLanguageType
						, ConnectionTypeDisplayName
						, Enabled
					)
				VALUES
					(   
						source.SourceLanguageType
						, source.ConnectionTypeDisplayName
						, source.Enabled
					);
	END;
	');

	PRINT N'Update complete for [common].[AddConnectionType]';

	PRINT N'Drop historic [ingest].[AddConnectionType] if it exists';
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[AddConnectionType]'))
	BEGIN
		EXEC('DROP PROCEDURE [ingest].[AddConnectionType];');
	END
END
PRINT N'';
PRINT N'------------- Migration for [common] schema objects complete -------------';
END

PRINT N''
IF @MigrateTransform = 1
BEGIN
PRINT N'----------------------- Migrate [transform] schema -----------------------'

/*
Migrate Schema
*/
BEGIN

	IF NOT EXISTS (
		SELECT * 
		FROM sys.schemas
		WHERE name = 'transform' 
		)
	BEGIN
		PRINT N'Schema [transform] does not exist. Creating...'
		EXEC ('CREATE SCHEMA [transform]');
		PRINT N'Schema [transform] has been created'
	END
END
/*
Migrate Tables
       [transform].[Attributes] (Table)
       [transform].[Datasets] (Table)
       [transform].[NotebookTypes] (Table)
       [transform].[Notebooks] (Table)
*/
BEGIN
-- transform.Attributes
	PRINT N'';
	PRINT N'----- Migration for Table [transform].[Attributes] -----';
	PRINT N'Checking for existing table [transform].[Attributes]...';

	-- Migration Case: transform.Attributes already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Attributes')
	
	BEGIN
		PRINT N'Table [transform].[Attributes] exists, creating a copy';
		EXEC sp_rename 'transform.Attributes', 'Attributes_Migration';
	END


	PRINT N'Creating new table [transform].[Attributes]...';

	CREATE TABLE [transform].[Attributes] (
		[AttributeId]             INT            IDENTITY (1, 1) NOT NULL,
		[DatasetFK]               INT            NOT NULL,
		[AttributeName]           NVARCHAR (100) NOT NULL,
		[AttributeTargetDataType] NVARCHAR (50)  NULL,
		[AttributeDescription]    NVARCHAR (200) NULL,
		[BKAttribute]             BIT            NOT NULL,
		[SurrogateKeyAttribute]   BIT            NOT NULL,
		[PartitionByAttribute]    BIT            NOT NULL,
		[Enabled]                 BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([AttributeId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [transform].[Attributes] created';
	PRINT N'Migrating data to new table [transform].[Attributes]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Attributes_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [transform].[Attributes_Migration])
		BEGIN
			SET IDENTITY_INSERT [transform].[Attributes] ON;
			INSERT INTO [transform].[Attributes] ([AttributeId],[DatasetFK],[AttributeName],[AttributeTargetDataType],[AttributeDescription],[BKAttribute],[SurrogateKeyAttribute],[PartitionByAttribute],[Enabled])
			SELECT  
				[AttributeId],
				[DatasetFK],
				[AttributeName],
				[AttributeTargetDataType],
				[AttributeDescription],
				[BKAttribute],
				[SurrogateKeyAttribute],
				[PartitionByAttribute],
				[Enabled]
			FROM     [transform].[Attributes_Migration]
			ORDER BY [AttributeId] ASC;
			SET IDENTITY_INSERT [transform].[Attributes] OFF;
		END
	END
	PRINT N'Migrated data to new table [transform].[Attributes]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [transform].[Attributes_Migration];



-- transform.Datasets
	PRINT N'';
	PRINT N'----- Migration for Table [transform].[Datasets] -----';
	PRINT N'Checking for existing table [transform].[Datasets]...';

	-- Migration Case: transform.Datasets already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Datasets')
	
	BEGIN
		PRINT N'Table [transform].[Datasets] exists, creating a copy';
		EXEC sp_rename 'transform.Datasets', 'Datasets_Migration';
	END


	PRINT N'Creating new table [transform].[Datasets]...';

	CREATE TABLE [transform].[Datasets] (
		[DatasetId]               INT            IDENTITY (1, 1) NOT NULL,
		[ComputeConnectionFK]     INT            NOT NULL,
		[CreateNotebookFK]        INT            NULL,
		[BusinessLogicNotebookFK] INT            NULL,
		[SchemaName]              NVARCHAR (100) NOT NULL,
		[DatasetName]             NVARCHAR (100) NOT NULL,
		[VersionNumber]           INT            NOT NULL,
		[VersionValidFrom]        DATETIME2 (7)  NULL,
		[VersionValidTo]          DATETIME2 (7)  NULL,
		[LoadType]                CHAR (1)       NOT NULL,
		[LoadStatus]              INT            NULL,
		[LastLoadDate]            DATETIME2 (7)  NULL,
		[Enabled]                 BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([DatasetId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [transform].[Datasets] created';
	PRINT N'Migrating data to new table [transform].[Datasets]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Datasets_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [transform].[Datasets_Migration])
		BEGIN
			SET IDENTITY_INSERT [transform].[Datasets] ON;
			INSERT INTO [transform].[Datasets] ([DatasetId],[ComputeConnectionFK],[CreateNotebookFK],[BusinessLogicNotebookFK],[SchemaName],[DatasetName],[VersionNumber],[VersionValidFrom],[VersionValidTo],[LoadType],[LoadStatus],[LastLoadDate],[Enabled])
			SELECT  
				[DatasetId],
				[ComputeConnectionFK],
				[CreateNotebookFK],
				[BusinessLogicNotebookFK],
				[SchemaName],
				[DatasetName],
				[VersionNumber],
				[VersionValidFrom],
				[VersionValidTo],
				[LoadType],
				[LoadStatus],
				[LastLoadDate],
				[Enabled]
			FROM     [transform].[Datasets_Migration]
			ORDER BY [DatasetId] ASC;
			SET IDENTITY_INSERT [transform].[Datasets] OFF;
		END
	END
	PRINT N'Migrated data to new table [transform].[Datasets]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [transform].[Datasets_Migration];

-- transform.Notebooks
	PRINT N'';
	PRINT N'----- Migration for Table [transform].[Notebooks] -----';
	PRINT N'Checking for existing table [transform].[Notebooks]...';

	-- Migration Case: transform.Notebooks already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Notebooks')
	
	BEGIN
		PRINT N'Table [transform].[Notebooks] exists, creating a copy';
		EXEC sp_rename 'transform.Notebooks', 'Notebooks_Migration';
	END


	PRINT N'Creating new table [transform].[Notebooks]...';

	CREATE TABLE [transform].[Notebooks] (
		[NotebookId]     INT            IDENTITY (1, 1) NOT NULL,
		[NotebookTypeFK] INT            NOT NULL,
		[NotebookName]   NVARCHAR (100) NOT NULL,
		[NotebookPath]   NVARCHAR (500) NOT NULL,
		[Enabled]        BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([NotebookId] ASC) ON [PRIMARY]
	) ON [PRIMARY];

	PRINT N'Table [transform].[Notebooks] created';
	PRINT N'Migrating data to new table [transform].[Notebooks]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'Notebooks_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [transform].[Notebooks_Migration])
		BEGIN
			SET IDENTITY_INSERT [transform].[Notebooks] ON;
			INSERT INTO [transform].[Notebooks] ([NotebookId],[NotebookTypeFK],[NotebookName],[NotebookPath],[Enabled])
			SELECT  
				[NotebookId],
				[NotebookTypeFK],
				[NotebookName],
				[NotebookPath],
				[Enabled]
			FROM     [transform].[Notebooks_Migration]
			ORDER BY [NotebookId] ASC;
			SET IDENTITY_INSERT [transform].[Notebooks] OFF;
		END
	END
	PRINT N'Migrated data to new table [transform].[Notebooks]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [transform].[Notebooks_Migration];

-- transform.NotebookTypes
	PRINT N'';
	PRINT N'----- Migration for Table [transform].[NotebookTypes] -----';
	PRINT N'Checking for existing table [transform].[NotebookTypes]...';

	-- Migration Case: transform.NotebookTypes already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'NotebookTypes')
	
	BEGIN
		PRINT N'Table [transform].[NotebookTypes] exists, creating a copy';
		EXEC sp_rename 'transform.NotebookTypes', 'NotebookTypes_Migration';
	END


	PRINT N'Creating new table [transform].[NotebookTypes]...';

	CREATE TABLE [transform].[NotebookTypes] (
		[NotebookTypeId]   INT            IDENTITY (1, 1) NOT NULL,
		[NotebookTypeName] NVARCHAR (100) NOT NULL,
		[Enabled]          BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([NotebookTypeId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [transform].[NotebookTypes] created';
	PRINT N'Migrating data to new table [transform].[NotebookTypes]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'transform' 
		AND  TABLE_NAME = 'NotebookTypes_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [transform].[NotebookTypes_Migration])
		BEGIN
			SET IDENTITY_INSERT [transform].[NotebookTypes] ON;
			INSERT INTO [transform].[NotebookTypes] ([NotebookTypeId],[NotebookTypeName],[Enabled])
			SELECT  
				[NotebookTypeId],
				[NotebookTypeName],
				[Enabled]
			FROM     [transform].[NotebookTypes_Migration]
			ORDER BY [NotebookTypeId] ASC;
			SET IDENTITY_INSERT [transform].[NotebookTypes] OFF;
		END
	END
	PRINT N'Migrated data to new table [transform].[NotebookTypes]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [transform].[NotebookTypes_Migration];

END

/*
Migrate Table Constraints
*/
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [transform] Table Constraints -----';

	PRINT N'Creating [DatasetFK] Foreign Key on [transform].[Attributes]...';
	ALTER TABLE [transform].[Attributes] WITH NOCHECK
		ADD FOREIGN KEY ([DatasetFK]) REFERENCES [transform].[Datasets] ([DatasetId]);

	PRINT N'Creating [CreateNotebookFK] Foreign Key on [transform].[Datasets]...';
	ALTER TABLE [transform].[Datasets] WITH NOCHECK
		ADD FOREIGN KEY ([CreateNotebookFK]) REFERENCES [transform].[Notebooks] ([NotebookId]);

	PRINT N'Creating [BusinessLogicNotebookFK] Foreign Key on [transform].[Datasets]...';
	ALTER TABLE [transform].[Datasets] WITH NOCHECK
		ADD FOREIGN KEY ([BusinessLogicNotebookFK]) REFERENCES [transform].[Notebooks] ([NotebookId]);


	PRINT N'Creating [NotebookTypeFK] Foreign Key on [transform].[Notebooks]...';
	ALTER TABLE [transform].[Notebooks] WITH NOCHECK
		ADD FOREIGN KEY ([NotebookTypeFK]) REFERENCES [transform].[NotebookTypes] ([NotebookTypeId]);
END

/*
Migrate Stored Procedures
       [transform].[GetUnmanagedNotebookPayload] (Procedure)
       [transform].[SetTransformLoadStatus] (Procedure)
       [transform].[GetNotebookPayload] (Procedure)
*/
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [transform].[GetUnmanagedNotebookPayload] Stored Procedure -----';

	PRINT N'Creating [transform].[GetUnmanagedNotebookPayload] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[transform].[GetUnmanagedNotebookPayload]'))
	BEGIN
		EXEC('CREATE PROCEDURE [transform].[GetUnmanagedNotebookPayload] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [transform].[GetUnmanagedNotebookPayload]';
	EXEC('
	ALTER PROCEDURE [transform].[GetUnmanagedNotebookPayload]
		(
		@DatasetId INT
		)
	AS
	BEGIN

		-- Defensive check for results returned
		DECLARE @ResultRowCount INT

		SELECT 
			@ResultRowCount = COUNT(*)
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN
			[transform].[Notebooks] AS n
		ON 
			n.NotebookId = ds.BusinessLogicNotebookFK
		INNER JOIN 
			[transform].[NotebookTypes] AS nt
		ON 
			n.NotebookTypeFK = nt.NotebookTypeId
		INNER JOIN 
			[common].[ComputeConnections] AS ccn
		ON
			ds.ComputeConnectionFK = ccn.ComputeConnectionId
		INNER JOIN
			[common].[Connections] AS cn
		ON 
			cn.ConnectionDisplayName = ''PrimaryResourceGroup''
		INNER JOIN
			[common].[Connections] AS cn2
		ON 
			cn2.ConnectionDisplayName = ''PrimarySubscription''
		INNER JOIN
			[common].[Connections] AS cn3
		ON 
			cn3.ConnectionDisplayName = ''PrimaryDataLake'' AND cn3.SourceLocation = ''curated''
		INNER JOIN
			[common].[Connections] AS cn4
		ON 
			cn4.ConnectionDisplayName = ''PrimaryDataLake'' AND cn4.SourceLocation = ''cleansed''
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			nt.NotebookTypeName = ''Unmanaged''
		AND
			ds.Enabled = 1
		AND
			n.Enabled = 1
		AND
			nt.Enabled = 1
		AND
			ccn.Enabled = 1

		IF @ResultRowCount = 0
		BEGIN
			RAISERROR(''No results returned for the provided Dataset Id.  Confirm Dataset is enabled, and related Connections and Notebooks Parameters are enabled.'',16,1)
			RETURN 0;
		END

		IF @ResultRowCount > 1
		BEGIN
			RAISERROR(''Multiple results returned for the provided Dataset Id. Confirm that only a single active dataset is being referenced.'',16,1)
			RETURN 0;
		END

		SELECT 
			[ccn].[ConnectionLocation] AS ''ComputeWorkspaceURL'',
			[ccn].[ComputeLocation] AS ''ComputeClusterId'',
			[ccn].[ComputeSize],
			[ccn].[ComputeVersion],
			[ccn].[CountNodes],
			[ccn].[LinkedServiceName] AS ''ComputeLinkedServiceName'',
			[ccn].[ResourceName] AS ''ComputeResourceName'',
			[cn].[SourceLocation] AS ''ResourceGroupName'',
			[cn2].[SourceLocation] AS ''SubscriptionId'',
        
			-- The following may not be required, but are available should data be written with unmanaged notebooks 
			-- to delta tables, without exposing KeyVault secrets to the repository
			[cn3].[ConnectionLocation] AS ''CuratedStorageName'',
			[cn3].[SourceLocation] AS ''CuratedContainerName'',
			[cn4].[ConnectionLocation] AS ''CleansedStorageName'',
			[cn4].[SourceLocation] AS ''CleansedContainerName'',
			[cn3].[Username] AS ''CuratedStorageAccessKey'',
			[cn4].[Username] AS ''CleansedStorageAccessKey'',

			ds.DatasetName,
			ds.SchemaName,
			n.NotebookPath AS ''NotebookFullPath''
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN
			[transform].[Notebooks] AS n
		ON 
			n.NotebookId = ds.BusinessLogicNotebookFK
		INNER JOIN 
			[transform].[NotebookTypes] AS nt
		ON 
			n.NotebookTypeFK = nt.NotebookTypeId
		INNER JOIN 
			[common].[ComputeConnections] AS ccn
		ON
			ds.ComputeConnectionFK = ccn.ComputeConnectionId
		INNER JOIN
			[common].[Connections] AS cn
		ON 
			cn.ConnectionDisplayName = ''PrimaryResourceGroup''
		INNER JOIN
			[common].[Connections] AS cn2
		ON 
			cn2.ConnectionDisplayName = ''PrimarySubscription''
		INNER JOIN
			[common].[Connections] AS cn3
		ON 
			cn3.ConnectionDisplayName = ''PrimaryDataLake'' AND cn3.SourceLocation = ''curated''
		INNER JOIN
			[common].[Connections] AS cn4
		ON 
			cn4.ConnectionDisplayName = ''PrimaryDataLake'' AND cn4.SourceLocation = ''cleansed''
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			nt.NotebookTypeName = ''Unmanaged''
		AND
			ds.Enabled = 1
		AND
			n.Enabled = 1
		AND
			nt.Enabled = 1
		AND
			ccn.Enabled = 1

	END
	');

	PRINT N'Update complete for [transform].[GetUnmanagedNotebookPayload]';

	PRINT N'';
	PRINT N'----- Migration for [transform].[SetTransformLoadStatus] Stored Procedure -----';

	PRINT N'Creating [transform].[SetTransformLoadStatus] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[transform].[SetTransformLoadStatus]'))
	BEGIN
		EXEC('CREATE PROCEDURE [transform].[SetTransformLoadStatus] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [transform].[SetTransformLoadStatus]';
	EXEC('
	ALTER PROCEDURE [transform].[SetTransformLoadStatus]
	(
		@DatasetId INT,
		@FileLoadDateTime DATETIME2
	)
	AS
	BEGIN

	UPDATE [transform].[Datasets]
	SET LoadStatus = 1,
		LastLoadDate = @FileLoadDateTime
	WHERE DatasetId = @DatasetId

	END
	');

	PRINT N'Update complete for [transform].[SetTransformLoadStatus]';

	PRINT N'';
	PRINT N'----- Migration for [transform].[GetNotebookPayload] Stored Procedure -----';

	PRINT N'Creating [transform].[GetNotebookPayload] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[transform].[GetNotebookPayload]'))
	BEGIN
		EXEC('CREATE PROCEDURE [transform].[GetNotebookPayload] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [transform].[GetNotebookPayload]';
	EXEC('
	ALTER PROCEDURE [transform].[GetNotebookPayload]
		(
		@DatasetId INT
		)
	AS
	BEGIN

		-- Defensive check for results returned
		DECLARE @ResultRowCount INT

		SELECT 
			@ResultRowCount = COUNT(*)
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN
			[transform].[Notebooks] AS n1
		ON 
			n1.NotebookId = ds.CreateNotebookFK
		INNER JOIN
			[transform].[Notebooks] AS n2
		ON 
			n2.NotebookId = ds.BusinessLogicNotebookFK
		INNER JOIN 
			[common].[ComputeConnections] AS ccn
		ON
			ds.ComputeConnectionFK = ccn.ComputeConnectionId
		INNER JOIN
			[common].[Connections] AS cn
		ON 
			cn.ConnectionDisplayName = ''PrimaryResourceGroup''
		INNER JOIN
			[common].[Connections] AS cn2
		ON 
			cn2.ConnectionDisplayName = ''PrimarySubscription''
		INNER JOIN
			[common].[Connections] AS cn3
		ON 
			cn3.ConnectionDisplayName = ''PrimaryDataLake'' AND cn3.SourceLocation = ''curated''
		INNER JOIN
			[common].[Connections] AS cn4
		ON 
			cn4.ConnectionDisplayName = ''PrimaryDataLake'' AND cn4.SourceLocation = ''cleansed''
		WHERE
			ds.DatasetId = @DatasetId

		IF @ResultRowCount = 0
		BEGIN
			RAISERROR(''No results returned for the provided Dataset Id.  Confirm Dataset is enabled, and related Connections and Notebooks Parameters are enabled.'',16,1)
			RETURN 0;
		END

		IF @ResultRowCount > 1
		BEGIN
			RAISERROR(''Multiple results returned for the provided Dataset Id. Confirm that only a single active dataset is being referenced.'',16,1)
			RETURN 0;
		END


		DECLARE @CuratedColumnsList NVARCHAR(MAX)
		DECLARE @CuratedColumnsTypeList NVARCHAR(MAX)

		DECLARE @BkAttributesList NVARCHAR(MAX) = ''''
		DECLARE @PartitionByAttributesList NVARCHAR(MAX) = ''''
		DECLARE @SurrogateKeyAttribute NVARCHAR(100) = ''''

		DECLARE @DateTimeFolderHierarchy NVARCHAR(MAX)

		-- Get attribute data as comma separated string values for the dataset. This excludes the SurrogateKey.
		SELECT 
			@CuratedColumnsList = STRING_AGG(att.AttributeName,'',''),
			@CuratedColumnsTypeList = STRING_AGG(att.AttributeTargetDataType,'','')
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN 
			[transform].[Attributes] AS att
		ON 
			att.DatasetFK = ds.DatasetId
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			att.SurrogateKeyAttribute = 0
		GROUP BY ds.DatasetId

		-- Get SurrogateKey column as string value.
		SELECT 
			@SurrogateKeyAttribute = att.AttributeName
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN 
			[transform].[Attributes] AS att
		ON 
			att.DatasetFK = ds.DatasetId
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			att.SurrogateKeyAttribute = 1

		-- Defensive check: Surrogate Key exists.
		IF @SurrogateKeyAttribute = ''''
		BEGIN
			RAISERROR(''No Surrogate Key Attribute specified for this dataset. Please ensure this is added to the transform.Attributes table, and specified in your bespoke notebook logic to populate the table.'',16,1)
			RETURN 0;
		END

		-- Get Bk columns as comma separated string values for the dataset
		SELECT 
			@BkAttributesList = STRING_AGG(att.AttributeName,'','')
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN 
			[transform].[Attributes] AS att
		ON 
			att.DatasetFK = ds.DatasetId
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			att.BkAttribute = 1
		GROUP BY 
			ds.DatasetId

		-- Get partitionby  columns as comma separated string values for the dataset
		SELECT 
			@PartitionByAttributesList = STRING_AGG(att.AttributeName,'','')
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN 
			[transform].[Attributes] AS att
		ON 
			att.DatasetFK = ds.DatasetId
		WHERE
			ds.DatasetId = @DatasetId
		AND 
			att.PartitionByAttribute = 1
		GROUP BY 
			ds.DatasetId

		-- Declare Load action
		DECLARE @LoadAction CHAR(1)
		SELECT 
			@LoadAction = 
			CASE 
				WHEN LoadType = ''F'' THEN ''F''
				WHEN LoadType = ''I'' AND LoadStatus = 0 THEN ''F''
				WHEN LoadType = ''I'' AND LoadStatus <> 0 THEN ''I''
				ELSE ''X''
			END 
		FROM [transform].[Datasets]
		WHERE DatasetId = @DatasetId

		IF @LoadAction = ''X''
		BEGIN
			RAISERROR(''Unexpected Load Type specified for Curated data load.'',16,1)
			RETURN 0;
		END

		SELECT 
			[ccn].[ConnectionLocation] AS ''ComputeWorkspaceURL'',
			[ccn].[ComputeLocation] AS ''ComputeClusterId'',
			[ccn].[ComputeSize],
			[ccn].[ComputeVersion],
			[ccn].[CountNodes],
			[ccn].[LinkedServiceName] AS ''ComputeLinkedServiceName'',
			[ccn].[ResourceName] AS ''ComputeResourceName'',
			[cn].[SourceLocation] AS ''ResourceGroupName'',
			[cn2].[SourceLocation] AS ''SubscriptionId'',
			[cn3].[ConnectionLocation] AS ''CuratedStorageName'',
			[cn3].[SourceLocation] AS ''CuratedContainerName'',
			[cn4].[ConnectionLocation] AS ''CleansedStorageName'',
			[cn4].[SourceLocation] AS ''CleansedContainerName'',
			[cn3].[Username] AS ''CuratedStorageAccessKey'',
			[cn4].[Username] AS ''CleansedStorageAccessKey'',

			ds.DatasetName,
			ds.SchemaName,
			n2.NotebookPath AS ''BusinessLogicNotebookPath'',
			n1.NotebookPath AS ''ExecutionNotebookPath'',
			@CuratedColumnsList AS ''ColumnsList'',
			@CuratedColumnsTypeList AS ''ColumnTypeList'',
			@SurrogateKeyAttribute AS ''SurrogateKey'',
			@BkAttributesList AS ''BkAttributesList'',
			@PartitionByAttributesList AS ''PartitionByAttributesList'',

			@LoadAction AS ''LoadType'',
			ds.LastLoadDate
		FROM 
			[transform].[Datasets] AS ds
		INNER JOIN
			[transform].[Notebooks] AS n1
		ON 
			n1.NotebookId = ds.CreateNotebookFK
		INNER JOIN
			[transform].[Notebooks] AS n2
		ON 
			n2.NotebookId = ds.BusinessLogicNotebookFK
		INNER JOIN 
			[common].[ComputeConnections] AS ccn
		ON
			ds.ComputeConnectionFK = ccn.ComputeConnectionId
		INNER JOIN
			[common].[Connections] AS cn
		ON 
			cn.ConnectionDisplayName = ''PrimaryResourceGroup''
		INNER JOIN
			[common].[Connections] AS cn2
		ON 
			cn2.ConnectionDisplayName = ''PrimarySubscription''
		INNER JOIN
			[common].[Connections] AS cn3
		ON 
			cn3.ConnectionDisplayName = ''PrimaryDataLake'' AND cn3.SourceLocation = ''curated''
		INNER JOIN
			[common].[Connections] AS cn4
		ON 
			cn4.ConnectionDisplayName = ''PrimaryDataLake'' AND cn4.SourceLocation = ''cleansed''
		WHERE
			ds.DatasetId = @DatasetId

	END
	');

	PRINT N'Update complete for [transform].[GetNotebookPayload]';
END
PRINT N'------------- Migration for [transform] schema objects complete -------------';
END

PRINT N''
IF @MigrateControl = 1
BEGIN
PRINT N'----------------------- Migrate [control] schema -----------------------';
/*
Migrate Schema
*/
BEGIN
	IF NOT EXISTS (
		SELECT * 
		FROM sys.schemas
		WHERE name = 'control' 
		)
	BEGIN
		PRINT N'Schema [control] does not exist. Creating...'
		EXEC ('CREATE SCHEMA [control]');
		PRINT N'Schema [control] has been created'

	END
END
/*
Migrate Tables
       [control].[PipelineAuthLink] (Table)
       [control].[Properties] (Table)
       [control].[Stages] (Table)
       [control].[ExecutionLog] (Table)
       [control].[CurrentExecution] (Table)
       [control].[CurrentExecution].[IDX_GetPipelinesInStage] (Index)
       [control].[PipelineParameters] (Table)
       [control].[Pipelines] (Table)
       [control].[PipelineDependencies] (Table)
       [control].[AlertOutcomes] (Table)
       [control].[PipelineAlertLink] (Table)
       [control].[Recipients] (Table)
       [control].[ErrorLog] (Table)
       [control].[Orchestrators] (Table)
       [control].[BatchStageLink] (Table)
       [control].[BatchExecution] (Table)
       [control].[Batches] (Table)
       [control].[Subscriptions] (Table)
       [control].[Tenants] (Table)
       [dbo].[ServicePrincipals] (Table)
*/
BEGIN

-- Drop Existing Table constraints
	
-- FKs
BEGIN
    PRINT N'Dropping Foreign Key [control].[FK_PipelineAuthLink_Orchestrators]...';

    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineAuthLink_Orchestrators')
	BEGIN 
		ALTER TABLE [control].[PipelineAuthLink] DROP CONSTRAINT [FK_PipelineAuthLink_Orchestrators];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineAuthLink_Pipelines]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineAuthLink_Pipelines')
	BEGIN 
		ALTER TABLE [control].[PipelineAuthLink] DROP CONSTRAINT [FK_PipelineAuthLink_Pipelines];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineAuthLink_ServicePrincipals]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineAuthLink_ServicePrincipals')
	BEGIN 
		ALTER TABLE [control].[PipelineAuthLink] DROP CONSTRAINT [FK_PipelineAuthLink_ServicePrincipals];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineParameters_Pipelines]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineParameters_Pipelines')
	BEGIN 
		ALTER TABLE [control].[PipelineParameters] DROP CONSTRAINT [FK_PipelineParameters_Pipelines];
	END

    PRINT N'Dropping Foreign Key [control].[FK_Pipelines_Stages]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_Pipelines_Stages')
	BEGIN 
		ALTER TABLE [control].[Pipelines] DROP CONSTRAINT [FK_Pipelines_Stages];
	END

    PRINT N'Dropping Foreign Key [control].[FK_Pipelines_Orchestrators]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_Pipelines_Orchestrators')
	BEGIN 
		ALTER TABLE [control].[Pipelines] DROP CONSTRAINT [FK_Pipelines_Orchestrators];
	END

    PRINT N'Dropping Foreign Key [control].[FK_Pipelines_Pipelines]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_Pipelines_Pipelines')
	BEGIN 
		ALTER TABLE [control].[Pipelines] DROP CONSTRAINT [FK_Pipelines_Pipelines];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineDependencies_Pipelines]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineDependencies_Pipelines')
	BEGIN 
		ALTER TABLE [control].[PipelineDependencies] DROP CONSTRAINT [FK_PipelineDependencies_Pipelines];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineDependencies_Pipelines1]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineDependencies_Pipelines1')
	BEGIN 
		ALTER TABLE [control].[PipelineDependencies] DROP CONSTRAINT [FK_PipelineDependencies_Pipelines1];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineAlertLink_Pipelines]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineAlertLink_Pipelines')
	BEGIN 
		ALTER TABLE [control].[PipelineAlertLink] DROP CONSTRAINT [FK_PipelineAlertLink_Pipelines];
	END

    PRINT N'Dropping Foreign Key [control].[FK_PipelineAlertLink_Recipients]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_PipelineAlertLink_Recipients')
	BEGIN 
		ALTER TABLE [control].[PipelineAlertLink] DROP CONSTRAINT [FK_PipelineAlertLink_Recipients];
	END

    PRINT N'Dropping Foreign Key [control].[FK_Orchestrators_Subscriptions]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_Orchestrators_Subscriptions')
	BEGIN 
		ALTER TABLE [control].[Orchestrators] DROP CONSTRAINT [FK_Orchestrators_Subscriptions];
	END

    PRINT N'Dropping Foreign Key [control].[FK_BatchStageLink_Batches]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_BatchStageLink_Batches')
	BEGIN 
		ALTER TABLE [control].[BatchStageLink] DROP CONSTRAINT [FK_BatchStageLink_Batches];
	END

    PRINT N'Dropping Foreign Key [control].[FK_BatchStageLink_Stages]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_BatchStageLink_Stages')
	BEGIN 
		ALTER TABLE [control].[BatchStageLink] DROP CONSTRAINT [FK_BatchStageLink_Stages];
	END

    PRINT N'Dropping Foreign Key [control].[FK_Subscriptions_Tenants]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'FK_Subscriptions_Tenants')
	BEGIN 
		ALTER TABLE [control].[Subscriptions] DROP CONSTRAINT [FK_Subscriptions_Tenants];
	END

    PRINT N'Dropping Foreign Key [control].[EQ_PipelineIdDependantPipelineId]...';
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'F' AND name = N'EQ_PipelineIdDependantPipelineId')
	BEGIN 
		ALTER TABLE [control].[PipelineDependencies] DROP CONSTRAINT [EQ_PipelineIdDependantPipelineId];
	END


END

-- PKs
BEGIN
	PRINT N'Drop existing Primary Keys'
	PRINT N'Drop [PK_PipelineAuthLink]'
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_PipelineAuthLink')
	BEGIN 
		ALTER TABLE [control].[PipelineAuthLink] DROP CONSTRAINT [PK_PipelineAuthLink];
    END

	PRINT N'Drop [PK_Properties]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Properties')
	BEGIN 
		ALTER TABLE [control].[Properties] DROP CONSTRAINT [PK_Properties];	
    END

	PRINT N'Drop [PK_Stages]'
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Stages')
	BEGIN 
		ALTER TABLE [control].[Stages] DROP CONSTRAINT [PK_Stages];
	END

	PRINT N'Drop [PK_ExecutionLog]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_ExecutionLog')
	BEGIN 
		ALTER TABLE [control].[ExecutionLog] DROP CONSTRAINT [PK_ExecutionLog];
	END

	PRINT N'Drop [PK_CurrentExecution]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_CurrentExecution')
	BEGIN 
		ALTER TABLE [control].[CurrentExecution] DROP CONSTRAINT [PK_CurrentExecution];
	END

	PRINT N'Drop [PK_PipelineParameters]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_PipelineParameters')
	BEGIN 
		ALTER TABLE [control].[PipelineParameters] DROP CONSTRAINT [PK_PipelineParameters];
	END

	PRINT N'Drop [PK_Pipelines]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Pipelines')
	BEGIN 
		ALTER TABLE [control].[Pipelines] DROP CONSTRAINT [PK_Pipelines];
	END

	PRINT N'Drop [PK_PipelineDependencies]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_PipelineDependencies')
	BEGIN 
		ALTER TABLE [control].[PipelineDependencies] DROP CONSTRAINT [PK_PipelineDependencies];
	END

	PRINT N'Drop [PK_AlertOutcomes]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_AlertOutcomes')
	BEGIN 
		ALTER TABLE [control].[AlertOutcomes] DROP CONSTRAINT [PK_AlertOutcomes];
	END

	PRINT N'Drop [PK_PipelineAlertLink]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_PipelineAlertLink')
	BEGIN 
		ALTER TABLE [control].[PipelineAlertLink] DROP CONSTRAINT [PK_PipelineAlertLink];
	END

	PRINT N'Drop [PK_Recipients]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Recipients')
	BEGIN 
		ALTER TABLE [control].[Recipients] DROP CONSTRAINT [PK_Recipients];
	END

	PRINT N'Drop [PK_ErrorLog]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_ErrorLog')
	BEGIN 
		ALTER TABLE [control].[ErrorLog] DROP CONSTRAINT [PK_ErrorLog];
	END

	PRINT N'Drop [PK_Orchestrators]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Orchestrators')
	BEGIN 
		ALTER TABLE [control].[Orchestrators] DROP CONSTRAINT [PK_Orchestrators];
	END

	PRINT N'Drop [PK_BatchStageLink]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_BatchStageLink')
	BEGIN 
		ALTER TABLE [control].[BatchStageLink] DROP CONSTRAINT [PK_BatchStageLink];
	END

	PRINT N'Drop [PK_BatchExecution]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_BatchExecution')
	BEGIN 
		ALTER TABLE [control].[BatchExecution] DROP CONSTRAINT [PK_BatchExecution];
	END

	PRINT N'Drop [PK_Batches]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Batches')
	BEGIN 
		ALTER TABLE [control].[Batches] DROP CONSTRAINT [PK_Batches];
	END

	PRINT N'Drop [PK_Subscriptions]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Subscriptions')
	BEGIN 
		ALTER TABLE [control].[Subscriptions] DROP CONSTRAINT [PK_Subscriptions];
	END

	PRINT N'Drop [PK_Tenants]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_Tenants')
	BEGIN 
		ALTER TABLE [control].[Tenants] DROP CONSTRAINT [PK_Tenants];
	END

	PRINT N'Drop [PK_ServicePrincipals]'
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'PK' AND name = N'PK_ServicePrincipals')
	BEGIN 
		ALTER TABLE [dbo].[ServicePrincipals] DROP CONSTRAINT [PK_ServicePrincipals];
	END

END

-- Unique Constraints
BEGIN
	PRINT N'Drop existing Unique Constraints'
	PRINT N'Drop [UK_PipelinesToDependantPipelines]'
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'UQ' AND name = N'UK_PipelinesToDependantPipelines')
	BEGIN 
		ALTER TABLE [control].[PipelineDependencies] DROP CONSTRAINT [UK_PipelinesToDependantPipelines];
    END

	PRINT N'Drop [UK_PipelineOutcomeStatus]'
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'UQ' AND name = N'UK_PipelineOutcomeStatus')
	BEGIN 
		ALTER TABLE [control].[AlertOutcomes] DROP CONSTRAINT [UK_PipelineOutcomeStatus];
    END

	PRINT N'Drop [UK_EmailAddressMessagePreference]'
    IF EXISTS (SELECT * FROM sys.objects WHERE type = 'UQ' AND name = N'UK_EmailAddressMessagePreference')
	BEGIN 
		ALTER TABLE [control].[Recipients] DROP CONSTRAINT [UK_EmailAddressMessagePreference];
    END

END

-- Tables
BEGIN
-- [control].[PipelineAuthLink]
BEGIN
	PRINT N'Creating Table [control].[PipelineAuthLink]...';
	PRINT N'';
	PRINT N'----- Migration for Table [control].[PipelineAuthLink] -----';
	PRINT N'Checking for existing table [control].[PipelineAuthLink]...';

	-- Migration Case: control.PipelineAuthLink already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineAuthLink')
	
	BEGIN
		PRINT N'Table [control].[PipelineAuthLink] exists, creating a copy';
		EXEC sp_rename 'control.PipelineAuthLink', 'PipelineAuthLink_Migration';
	END


	PRINT N'Creating new table [control].[PipelineAuthLink]...';

	CREATE TABLE [control].[PipelineAuthLink] (
		[AuthId]         INT IDENTITY (1, 1) NOT NULL,
		[PipelineId]     INT NOT NULL,
		[OrchestratorId] INT NOT NULL,
		[CredentialId]   INT NOT NULL,
		CONSTRAINT [PK_PipelineAuthLink] PRIMARY KEY CLUSTERED ([AuthId] ASC)
	);

	PRINT N'Table [control].[PipelineAuthLink] created';
	PRINT N'Migrating data to new table [control].[PipelineAuthLink]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineAuthLink_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[PipelineAuthLink_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[PipelineAuthLink] ON;
			INSERT INTO [control].[PipelineAuthLink] ([AuthId],[PipelineId],[OrchestratorId],[CredentialId])
			SELECT  
				[AuthId],
				[PipelineId],
				[OrchestratorId],
				[CredentialId]
			FROM     [control].[PipelineAuthLink_Migration]
			ORDER BY [AuthId] ASC;
			SET IDENTITY_INSERT [control].[PipelineAuthLink] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[PipelineAuthLink]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[PipelineAuthLink_Migration];
END

-- [control].[Properties]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Properties] -----';
	PRINT N'Checking for existing table [control].[Properties]...';

	-- Migration Case: control.Properties already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Properties')
	
	BEGIN
		PRINT N'Table [control].[Properties] exists, creating a copy';
		EXEC sp_rename 'control.Properties', 'Properties_Migration';

	END


	PRINT N'Creating new table [control].[Properties]...';

	CREATE TABLE [control].[Properties] (
		[PropertyId]    INT            IDENTITY (1, 1) NOT NULL,
		[PropertyName]  VARCHAR (128)  NOT NULL,
		[PropertyValue] NVARCHAR (MAX) NOT NULL,
		[Description]   NVARCHAR (MAX) NULL,
		[ValidFrom]     DATETIME       NOT NULL,
		[ValidTo]       DATETIME       NULL,
		CONSTRAINT [PK_Properties] PRIMARY KEY CLUSTERED ([PropertyId] ASC, [PropertyName] ASC)
	);

	PRINT N'Table [control].[Properties] created';
	PRINT N'Migrating data to new table [control].[Properties]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Properties_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Properties_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[Properties] ON;
			INSERT INTO [control].[Properties] ([PropertyId],[PropertyName],[PropertyValue],[Description],[ValidFrom],[ValidTo])
			SELECT  
				[PropertyId],
				[PropertyName],
				[PropertyValue],
				[Description],
				[ValidFrom],
				[ValidTo]
			FROM     [control].[Properties_Migration]
			ORDER BY [PropertyId] ASC;
			SET IDENTITY_INSERT [control].[Properties] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[Properties]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Properties_Migration];
END

-- [control].[Stages]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Stages] -----';
	PRINT N'Checking for existing table [control].[Stages]...';

	-- Migration Case: control.Stages already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Stages')
	BEGIN
		PRINT N'Table [control].[Stages] exists, creating a copy';
		EXEC sp_rename 'control.Stages', 'Stages_Migration';		
	END


	PRINT N'Creating new table [control].[Stages]...';

	CREATE TABLE [control].[Stages] (
		[StageId]          INT            IDENTITY (1, 1) NOT NULL,
		[StageName]        VARCHAR (225)  NOT NULL,
		[StageDescription] VARCHAR (4000) NULL,
		[Enabled]          BIT            NOT NULL,
		CONSTRAINT [PK_Stages] PRIMARY KEY CLUSTERED ([StageId] ASC)
	);

	PRINT N'Table [control].[Stages] created';
	PRINT N'Migrating data to new table [control].[Stages]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Stages_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Stages_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[Stages] ON;
			INSERT INTO [control].[Stages] ([StageId],[StageName],[StageDescription],[Enabled])
			SELECT  
				[StageId],
				[StageName],
				[StageDescription],
				[Enabled]
			FROM     [control].[Stages_Migration]
			ORDER BY [StageId] ASC;
			SET IDENTITY_INSERT [control].[Stages] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[Stages]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Stages_Migration];
END

-- [control].[ExecutionLog]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[ExecutionLog] -----';
	PRINT N'Checking for existing table [control].[ExecutionLog]...';

	-- Migration Case: control.ExecutionLog already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'ExecutionLog')
	
	BEGIN
		PRINT N'Table [control].[ExecutionLog] exists, creating a copy';
		EXEC sp_rename 'control.ExecutionLog', 'ExecutionLog_Migration';
	END


	PRINT N'Creating new table [control].[ExecutionLog]...';

	CREATE TABLE [control].[ExecutionLog] (
		[LogId]                   INT              IDENTITY (1, 1) NOT NULL,
		[LocalExecutionId]        UNIQUEIDENTIFIER NOT NULL,
		[StageId]                 INT              NOT NULL,
		[PipelineId]              INT              NOT NULL,
		[CallingOrchestratorName] NVARCHAR (200)   NOT NULL,
		[ResourceGroupName]       NVARCHAR (200)   NOT NULL,
		[OrchestratorType]        CHAR (3)         NOT NULL,
		[OrchestratorName]        NVARCHAR (200)   NOT NULL,
		[PipelineName]            NVARCHAR (200)   NOT NULL,
		[StartDateTime]           DATETIME         NULL,
		[PipelineStatus]          NVARCHAR (200)   NULL,
		[EndDateTime]             DATETIME         NULL,
		[PipelineRunId]           UNIQUEIDENTIFIER NULL,
		[PipelineParamsUsed]      NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_ExecutionLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
	);

	PRINT N'Table [control].[ExecutionLog] created';
	PRINT N'Migrating data to new table [control].[ExecutionLog]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'ExecutionLog_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[ExecutionLog_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[ExecutionLog] ON;
			INSERT INTO [control].[ExecutionLog] ([LogId],[LocalExecutionId],[StageId],[PipelineId],[CallingOrchestratorName],[ResourceGroupName],[OrchestratorType],[OrchestratorName],[PipelineName],[StartDateTime],[PipelineStatus],[EndDateTime],[PipelineRunId],[PipelineParamsUsed])
			SELECT  
				[LogId],
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				[PipelineStatus],
				[EndDateTime],
				[PipelineRunId],
				[PipelineParamsUsed]
			FROM     [control].[ExecutionLog_Migration]
			ORDER BY [LogId] ASC;
			SET IDENTITY_INSERT [control].[ExecutionLog] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[ExecutionLog]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[ExecutionLog_Migration];
END

-- [control].[CurrentExecution]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[CurrentExecution] -----';
	PRINT N'Checking for existing table [control].[CurrentExecution]...';

	-- Migration Case: control.CurrentExecution already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'CurrentExecution')
	
	BEGIN
		PRINT N'Table [control].[CurrentExecution] exists, creating a copy';
		EXEC sp_rename 'control.CurrentExecution', 'CurrentExecution_Migration';
	END


	PRINT N'Creating new table [control].[CurrentExecution]...';

	CREATE TABLE [control].[CurrentExecution] (
		[LocalExecutionId]        UNIQUEIDENTIFIER NOT NULL,
		[StageId]                 INT              NOT NULL,
		[PipelineId]              INT              NOT NULL,
		[CallingOrchestratorName] NVARCHAR (200)   NOT NULL,
		[ResourceGroupName]       NVARCHAR (200)   NOT NULL,
		[OrchestratorType]        CHAR (3)         NOT NULL,
		[OrchestratorName]        NVARCHAR (200)   NOT NULL,
		[PipelineName]            NVARCHAR (200)   NOT NULL,
		[StartDateTime]           DATETIME         NULL,
		[PipelineStatus]          NVARCHAR (200)   NULL,
		[LastStatusCheckDateTime] DATETIME         NULL,
		[EndDateTime]             DATETIME         NULL,
		[IsBlocked]               BIT              NOT NULL,
		[PipelineRunId]           UNIQUEIDENTIFIER NULL,
		[PipelineParamsUsed]      NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_CurrentExecution] PRIMARY KEY CLUSTERED ([LocalExecutionId] ASC, [StageId] ASC, [PipelineId] ASC)
	);

	PRINT N'Table [control].[CurrentExecution] created';
	PRINT N'Migrating data to new table [control].[CurrentExecution]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'CurrentExecution_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[CurrentExecution_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[CurrentExecution] ON;
			INSERT INTO [control].[CurrentExecution] ([LocalExecutionId],[StageId],[PipelineId],[CallingOrchestratorName],[ResourceGroupName],[OrchestratorType],[OrchestratorName],[PipelineName],[StartDateTime],[PipelineStatus],[LastStatusCheckDateTime],[EndDateTime],[IsBlocked],[PipelineRunId],[PipelineParamsUsed])
			SELECT  
				[LocalExecutionId],       
				[StageId],                
				[PipelineId],             
				[CallingOrchestratorName],
				[ResourceGroupName],      
				[OrchestratorType],       
				[OrchestratorName],       
				[PipelineName],           
				[StartDateTime],          
				[PipelineStatus],         
				[LastStatusCheckDateTime],
				[EndDateTime],            
				[IsBlocked],              
				[PipelineRunId],          
				[PipelineParamsUsed]
			FROM     [control].[CurrentExecution_Migration]
			ORDER BY [LocalExecutionId] ASC;
			SET IDENTITY_INSERT [control].[CurrentExecution] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[CurrentExecution]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[CurrentExecution_Migration];
END

-- [control].[PipelineParameters]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[PipelineParameters] -----';
	PRINT N'Checking for existing table [control].[PipelineParameters]...';

	-- Migration Case: control.PipelineParameters already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineParameters')
	
	BEGIN
		PRINT N'Table [control].[PipelineParameters] exists, creating a copy';
		EXEC sp_rename 'control.PipelineParameters', 'PipelineParameters_Migration';
	END


	PRINT N'Creating new table [control].[PipelineParameters]...';

	CREATE TABLE [control].[PipelineParameters] (
		[ParameterId]            INT            IDENTITY (1, 1) NOT NULL,
		[PipelineId]             INT            NOT NULL,
		[ParameterName]          VARCHAR (128)  NOT NULL,
		[ParameterValue]         NVARCHAR (MAX) NULL,
		[ParameterValueLastUsed] NVARCHAR (MAX) NULL,
		CONSTRAINT [PK_PipelineParameters] PRIMARY KEY CLUSTERED ([ParameterId] ASC)
	);

	PRINT N'Table [control].[PipelineParameters] created';
	PRINT N'Migrating data to new table [control].[PipelineParameters]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineParameters_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[PipelineParameters_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[PipelineParameters] ON;
			INSERT INTO [control].[PipelineParameters] ([ParameterId],[PipelineId],[ParameterName],[ParameterValue],[ParameterValueLastUsed])
			SELECT  
				[ParameterId],
				[PipelineId],
				[ParameterName],
				[ParameterValue],
				[ParameterValueLastUsed]
			FROM     [control].[PipelineParameters_Migration]
			ORDER BY [ParameterId] ASC;
			SET IDENTITY_INSERT [control].[PipelineParameters] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[PipelineParameters]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[PipelineParameters_Migration];
END
	
-- [control].[Pipelines]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Pipelines] -----';
	PRINT N'Checking for existing table [control].[Pipelines]...';

	-- Migration Case: control.Pipelines already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Pipelines')
	
	BEGIN
		PRINT N'Table [control].[Pipelines] exists, creating a copy';
		EXEC sp_rename 'control.Pipelines', 'Pipelines_Migration';
	END


	PRINT N'Creating new table [control].[Pipelines]...';

	CREATE TABLE [control].[Pipelines] (
		[PipelineId]           INT            IDENTITY (1, 1) NOT NULL,
		[OrchestratorId]       INT            NOT NULL,
		[StageId]              INT            NOT NULL,
		[PipelineName]         NVARCHAR (200) NOT NULL,
		[LogicalPredecessorId] INT            NULL,
		[Enabled]              BIT            NOT NULL,
		CONSTRAINT [PK_Pipelines] PRIMARY KEY CLUSTERED ([PipelineId] ASC)
	);

	PRINT N'Table [control].[Pipelines] created';
	PRINT N'Migrating data to new table [control].[Pipelines]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Pipelines_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Pipelines_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[Pipelines] ON;
			INSERT INTO [control].[Pipelines] ([PipelineId],[OrchestratorId],[StageId],[PipelineName],[LogicalPredecessorId],[Enabled])
			SELECT  
				[PipelineId],
				[OrchestratorId],
				[StageId],
				[PipelineName],
				[LogicalPredecessorId],
				[Enabled]
			FROM     [control].[Pipelines_Migration]
			ORDER BY [PipelineId] ASC;
			SET IDENTITY_INSERT [control].[Pipelines] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[Pipelines]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Pipelines_Migration];
END

-- [control].[PipelineDependencies]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[PipelineDependencies] -----';
	PRINT N'Checking for existing table [control].[PipelineDependencies]...';

	-- Migration Case: control.PipelineDependencies already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineDependencies')
	
	BEGIN
		PRINT N'Table [control].[PipelineDependencies] exists, creating a copy';
		EXEC sp_rename 'control.PipelineDependencies', 'PipelineDependencies_Migration';
	END


	PRINT N'Creating new table [control].[PipelineDependencies]...';

		CREATE TABLE [control].[PipelineDependencies] (
			[DependencyId]        INT IDENTITY (1, 1) NOT NULL,
			[PipelineId]          INT NOT NULL,
			[DependantPipelineId] INT NOT NULL,
			CONSTRAINT [PK_PipelineDependencies] PRIMARY KEY CLUSTERED ([DependencyId] ASC),
			CONSTRAINT [UK_PipelinesToDependantPipelines] UNIQUE NONCLUSTERED ([PipelineId] ASC, [DependantPipelineId] ASC)
		);

	PRINT N'Table [control].[PipelineDependencies] created';
	PRINT N'Migrating data to new table [control].[PipelineDependencies]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineDependencies') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[PipelineDependencies_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[PipelineDependencies] ON;
			INSERT INTO [control].[PipelineDependencies] ([DependencyId],[PipelineId],[DependantPipelineId])
			SELECT  
				[DependencyId],
				[PipelineId],
				[DependantPipelineId]
			FROM     [control].[PipelineDependencies_Migration]
			ORDER BY [DependencyId] ASC;
			SET IDENTITY_INSERT [control].[PipelineDependencies] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[PipelineDependencies]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[PipelineDependencies_Migration];
END

-- [control].[AlertOutcomes]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[AlertOutcomes] -----';
	PRINT N'Checking for existing table [control].[AlertOutcomes]...';

	-- Migration Case: control.AlertOutcomes already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'AlertOutcomes')
	
	BEGIN
		PRINT N'Table [control].[AlertOutcomes] exists, creating a copy';
		EXEC sp_rename 'control.AlertOutcomes', 'AlertOutcomes_Migration';
	END


	PRINT N'Creating new table [control].[AlertOutcomes]...';

	CREATE TABLE [control].[AlertOutcomes] (
		[OutcomeBitPosition]    INT            IDENTITY (0, 1) NOT NULL,
		[PipelineOutcomeStatus] NVARCHAR (200) NOT NULL,
		[BitValue]              AS             (POWER((2), [OutcomeBitPosition])),
		CONSTRAINT [PK_AlertOutcomes] PRIMARY KEY CLUSTERED ([OutcomeBitPosition] ASC),
		CONSTRAINT [UK_PipelineOutcomeStatus] UNIQUE NONCLUSTERED ([PipelineOutcomeStatus] ASC)
	);

	PRINT N'Table [control].[AlertOutcomes] created';
	PRINT N'Migrating data to new table [control].[AlertOutcomes]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'AlertOutcomes_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[AlertOutcomes_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[AlertOutcomes] ON;
			INSERT INTO [control].[AlertOutcomes] ([OutcomeBitPosition],[PipelineOutcomeStatus],[BitValue])
			SELECT  
				[OutcomeBitPosition],
				[PipelineOutcomeStatus],
				[BitValue]
			FROM     [control].[AlertOutcomes_Migration]
			ORDER BY [OutcomeBitPosition] ASC;
			SET IDENTITY_INSERT [control].[AlertOutcomes] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[AlertOutcomes]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[AlertOutcomes_Migration];
END

-- [control].[PipelineAlertLink]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[PipelineAlertLink] -----';
	PRINT N'Checking for existing table [control].[PipelineAlertLink]...';

	-- Migration Case: control.PipelineAlertLink already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineAlertLink')
	
	BEGIN
		PRINT N'Table [control].[PipelineAlertLink] exists, creating a copy';
		EXEC sp_rename 'control.PipelineAlertLink', 'PipelineAlertLink_Migration';
	END


	PRINT N'Creating new table [control].[PipelineAlertLink]...';

	CREATE TABLE [control].[PipelineAlertLink] (
		[AlertId]          INT IDENTITY (1, 1) NOT NULL,
		[PipelineId]       INT NOT NULL,
		[RecipientId]      INT NOT NULL,
		[OutcomesBitValue] INT NOT NULL,
		[Enabled]          BIT NOT NULL,
		CONSTRAINT [PK_PipelineAlertLink] PRIMARY KEY CLUSTERED ([AlertId] ASC)
	);

	PRINT N'Table [control].[PipelineAlertLink] created';
	PRINT N'Migrating data to new table [control].[PipelineAlertLink]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'PipelineAlertLink_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[PipelineAlertLink_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[PipelineAlertLink] ON;
			INSERT INTO [control].[PipelineAlertLink] ([AlertId],[PipelineId],[RecipientId],[OutcomesBitValue],[Enabled])
			SELECT  
				[AlertId],
				[PipelineId],
				[RecipientId],
				[OutcomesBitValue],
				[Enabled]
			FROM     [control].[PipelineAlertLink_Migration]
			ORDER BY [AlertId] ASC;
			SET IDENTITY_INSERT [control].[PipelineAlertLink] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[PipelineAlertLink]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[PipelineAlertLink_Migration];
END

-- [control].[Recipients]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Recipients] -----';
	PRINT N'Checking for existing table [control].[Recipients]...';

	-- Migration Case: control.Recipients already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Recipients')
	
	BEGIN
		PRINT N'Table [control].[Recipients] exists, creating a copy';
		EXEC sp_rename 'control.Recipients', 'Recipients_Migration';
	END


	PRINT N'Creating new table [control].[Recipients]...';

	CREATE TABLE [control].[Recipients] (
		[RecipientId]       INT            IDENTITY (1, 1) NOT NULL,
		[Name]              VARCHAR (255)  NULL,
		[EmailAddress]      NVARCHAR (500) NOT NULL,
		[MessagePreference] CHAR (3)       NOT NULL,
		[Enabled]           BIT            NOT NULL,
		CONSTRAINT [PK_Recipients] PRIMARY KEY CLUSTERED ([RecipientId] ASC),
		CONSTRAINT [UK_EmailAddressMessagePreference] UNIQUE NONCLUSTERED ([EmailAddress] ASC, [MessagePreference] ASC)
	);

	PRINT N'Table [control].[Recipients] created';
	PRINT N'Migrating data to new table [control].[Recipients]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Recipients_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Recipients_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[Recipients] ON;
			INSERT INTO [control].[Recipients] ([RecipientId],[Name],[EmailAddress],[MessagePreference],[Enabled])
			SELECT  
				[RecipientId],
				[Name],
				[EmailAddress],
				[MessagePreference],
				[Enabled]
			FROM     [control].[Recipients_Migration]
			ORDER BY [RecipientId] ASC;
			SET IDENTITY_INSERT [control].[Recipients] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[Recipients]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Recipients_Migration];
END

-- [control].[ErrorLog]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[ErrorLog] -----';
	PRINT N'Checking for existing table [control].[ErrorLog]...';

	-- Migration Case: control.ErrorLog already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'ErrorLog')
	
	BEGIN
		PRINT N'Table [control].[ErrorLog] exists, creating a copy';
		EXEC sp_rename 'control.ErrorLog', 'ErrorLog_Migration';
	END


	PRINT N'Creating new table [control].[ErrorLog]...';

	CREATE TABLE [control].[ErrorLog] (
		[LogId]            INT              IDENTITY (1, 1) NOT NULL,
		[LocalExecutionId] UNIQUEIDENTIFIER NOT NULL,
		[PipelineRunId]    UNIQUEIDENTIFIER NOT NULL,
		[ActivityRunId]    UNIQUEIDENTIFIER NOT NULL,
		[ActivityName]     VARCHAR (100)    NOT NULL,
		[ActivityType]     VARCHAR (100)    NOT NULL,
		[ErrorCode]        VARCHAR (100)    NOT NULL,
		[ErrorType]        VARCHAR (100)    NOT NULL,
		[ErrorMessage]     NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
	);

	PRINT N'Table [control].[ErrorLog] created';
	PRINT N'Migrating data to new table [control].[ErrorLog]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'ErrorLog_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[ErrorLog_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[ErrorLog] ON;
			INSERT INTO [control].[ErrorLog] ([LogId],[LocalExecutionId],[PipelineRunId],[ActivityRunId],[ActivityName],[ActivityType],[ErrorCode],[ErrorType],[ErrorMessage])
			SELECT  
				[LogId],
				[LocalExecutionId],
				[PipelineRunId],
				[ActivityRunId],
				[ActivityName],
				[ActivityType],
				[ErrorCode],
				[ErrorType],
				[ErrorMessage]
			FROM     [control].[ErrorLog_Migration]
			ORDER BY [LogId] ASC;
			SET IDENTITY_INSERT [control].[ErrorLog] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[ErrorLog]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[ErrorLog_Migration];
END

-- [control].[Orchestrators]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Orchestrators] -----';
	PRINT N'Checking for existing table [control].[Orchestrators]...';

	-- Migration Case: control.Orchestrators already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Orchestrators')
	
	BEGIN
		PRINT N'Table [control].[Orchestrators] exists, creating a copy';
		EXEC sp_rename 'control.Orchestrators', 'Orchestrators_Migration';
	END


	PRINT N'Creating new table [control].[Orchestrators]...';

	CREATE TABLE [control].[Orchestrators] (
		[OrchestratorId]          INT              IDENTITY (1, 1) NOT NULL,
		[OrchestratorName]        NVARCHAR (200)   NOT NULL,
		[OrchestratorType]        CHAR (3)         NOT NULL,
		[IsFrameworkOrchestrator] BIT              NOT NULL,
		[ResourceGroupName]       NVARCHAR (200)   NOT NULL,
		[SubscriptionId]          UNIQUEIDENTIFIER NOT NULL,
		[Description]             NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_Orchestrators] PRIMARY KEY CLUSTERED ([OrchestratorId] ASC)
	);

	PRINT N'Table [control].[Orchestrators] created';
	PRINT N'Migrating data to new table [control].[Orchestrators]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Orchestrators_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Orchestrators_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[Orchestrators] ON;
			INSERT INTO [control].[Orchestrators] ([OrchestratorId],[OrchestratorName],[OrchestratorType],[IsFrameworkOrchestrator],[ResourceGroupName],[SubscriptionId],[Description])
			SELECT  
				[OrchestratorId],
				[OrchestratorName],
				[OrchestratorType],
				[IsFrameworkOrchestrator],
				[ResourceGroupName],
				[SubscriptionId],
				[Description]
			FROM     [control].[Orchestrators_Migration]
			ORDER BY [OrchestratorId] ASC;
			SET IDENTITY_INSERT [control].[Orchestrators] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[Orchestrators]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Orchestrators_Migration];
END

-- [control].[BatchStageLink]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[BatchStageLink] -----';
	PRINT N'Checking for existing table [control].[BatchStageLink]...';

	-- Migration Case: control.BatchStageLink already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'BatchStageLink')
	
	BEGIN
		PRINT N'Table [control].[BatchStageLink] exists, creating a copy';
		EXEC sp_rename 'control.BatchStageLink', 'BatchStageLink_Migration';
	END


	PRINT N'Creating new table [control].[BatchStageLink]...';

	CREATE TABLE [control].[BatchStageLink] (
		[BatchId] UNIQUEIDENTIFIER NOT NULL,
		[StageId] INT              NOT NULL,
		CONSTRAINT [PK_BatchStageLink] PRIMARY KEY CLUSTERED ([BatchId] ASC, [StageId] ASC)
	);

	PRINT N'Table [control].[BatchStageLink] created';
	PRINT N'Migrating data to new table [control].[BatchStageLink]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'BatchStageLink_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[BatchStageLink_Migration])
		BEGIN
			INSERT INTO [control].[BatchStageLink] ([BatchId],[StageId])
			SELECT  
				[BatchId],
				[StageId]
			FROM     [control].[BatchStageLink_Migration]
			ORDER BY [BatchId] ASC;
		END
	END
	PRINT N'Migrated data to new table [control].[BatchStageLink]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[BatchStageLink_Migration];
END

-- [control].[BatchExecution]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[BatchExecution] -----';
	PRINT N'Checking for existing table [control].[BatchExecution]...';

	-- Migration Case: control.BatchExecution already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'BatchExecution')
	
	BEGIN
		PRINT N'Table [control].[BatchExecution] exists, creating a copy';
		EXEC sp_rename 'control.BatchExecution', 'BatchExecution_Migration';
	END


	PRINT N'Creating new table [control].[BatchExecution]...';

	CREATE TABLE [control].[BatchExecution] (
		[BatchId]       UNIQUEIDENTIFIER NOT NULL,
		[ExecutionId]   UNIQUEIDENTIFIER NOT NULL,
		[BatchName]     VARCHAR (255)    NOT NULL,
		[BatchStatus]   NVARCHAR (200)   NOT NULL,
		[StartDateTime] DATETIME         NOT NULL,
		[EndDateTime]   DATETIME         NULL,
		CONSTRAINT [PK_BatchExecution] PRIMARY KEY CLUSTERED ([BatchId] ASC, [ExecutionId] ASC)
	);

	PRINT N'Table [control].[BatchExecution] created';
	PRINT N'Migrating data to new table [control].[BatchExecution]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'BatchExecution_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[BatchExecution_Migration])
		BEGIN
			SET IDENTITY_INSERT [control].[BatchExecution] ON;
			INSERT INTO [control].[BatchExecution] ([BatchId],[ExecutionId],[BatchName],[BatchStatus],[StartDateTime],[EndDateTime])
			SELECT  
				[BatchId],
				[ExecutionId],
				[BatchName],
				[BatchStatus],
				[StartDateTime],
				[EndDateTime]
			FROM     [control].[BatchExecution_Migration]
			ORDER BY [BatchId] ASC;
			SET IDENTITY_INSERT [control].[BatchExecution] OFF;
		END
	END
	PRINT N'Migrated data to new table [control].[BatchExecution]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[BatchExecution_Migration];
END

-- [control].[Batches]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Batches] -----';
	PRINT N'Checking for existing table [control].[Batches]...';

	-- Migration Case: control.Batches already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Batches')
	
	BEGIN
		PRINT N'Table [control].[Batches] exists, creating a copy';
		EXEC sp_rename 'control.Batches', 'Batches_Migration';
	END


	PRINT N'Creating new table [control].[Batches]...';

	CREATE TABLE [control].[Batches] (
		[BatchId]          UNIQUEIDENTIFIER NOT NULL,
		[BatchName]        VARCHAR (255)    NOT NULL,
		[BatchDescription] VARCHAR (4000)   NULL,
		[Enabled]          BIT              NOT NULL,
		CONSTRAINT [PK_Batches] PRIMARY KEY CLUSTERED ([BatchId] ASC)
	);

	PRINT N'Table [control].[Batches] created';
	PRINT N'Migrating data to new table [control].[Batches]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Batches_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Batches_Migration])
		BEGIN
			INSERT INTO [control].[Batches] ([BatchId],[BatchName],[BatchDescription],[Enabled])
			SELECT  
				[BatchId],
				[BatchName],
				[BatchDescription],
				[Enabled]
			FROM     [control].[Batches_Migration]
			ORDER BY [BatchId] ASC;
		END
	END
	PRINT N'Migrated data to new table [control].[Batches]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Batches_Migration];
END

-- [control].[Subscriptions]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Subscriptions] -----';
	PRINT N'Checking for existing table [control].[Subscriptions]...';

	-- Migration Case: control.Subscriptions already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Subscriptions')
	
	BEGIN
		PRINT N'Table [control].[Subscriptions] exists, creating a copy';
		EXEC sp_rename 'control.Subscriptions', 'Subscriptions_Migration';
	END


	PRINT N'Creating new table [control].[Subscriptions]...';

	CREATE TABLE [control].[Subscriptions] (
		[SubscriptionId] UNIQUEIDENTIFIER NOT NULL,
		[Name]           NVARCHAR (200)   NOT NULL,
		[Description]    NVARCHAR (MAX)   NULL,
		[TenantId]       UNIQUEIDENTIFIER NOT NULL,
		CONSTRAINT [PK_Subscriptions] PRIMARY KEY CLUSTERED ([SubscriptionId] ASC)
	);

	PRINT N'Table [control].[Subscriptions] created';
	PRINT N'Migrating data to new table [control].[Subscriptions]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Subscriptions_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Subscriptions_Migration])
		BEGIN
			INSERT INTO [control].[Subscriptions] ([SubscriptionId],[Name],[Description],[TenantId])
			SELECT  
				[SubscriptionId],
				[Name],
				[Description],
				[TenantId]
			FROM     [control].[Subscriptions_Migration]
			ORDER BY [SubscriptionId] ASC;
		END
	END
	PRINT N'Migrated data to new table [control].[Subscriptions]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Subscriptions_Migration];
END

-- [control].[Tenants]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [control].[Tenants] -----';
	PRINT N'Checking for existing table [control].[Tenants]...';

	-- Migration Case: control.Tenants already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Tenants')
	
	BEGIN
		PRINT N'Table [control].[Tenants] exists, creating a copy';
		EXEC sp_rename 'control.Tenants', 'Tenants_Migration';
	END


	PRINT N'Creating new table [control].[Tenants]...';

	CREATE TABLE [control].[Tenants] (
		[TenantId]    UNIQUEIDENTIFIER NOT NULL,
		[Name]        NVARCHAR (200)   NOT NULL,
		[Description] NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED ([TenantId] ASC)
	);

	PRINT N'Table [control].[Tenants] created';
	PRINT N'Migrating data to new table [control].[Tenants]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'control' 
		AND  TABLE_NAME = 'Tenants_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [control].[Tenants_Migration])
		BEGIN
			INSERT INTO [control].[Tenants] ([TenantId],[Name],[Description])
			SELECT  
				[TenantId],
				[Name],
				[Description]
			FROM     [control].[Tenants_Migration]
			ORDER BY [TenantId] ASC;
		END
	END
	PRINT N'Migrated data to new table [control].[Tenants]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [control].[Tenants_Migration];
END

-- [dbo].[ServicePrincipals]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [dbo].[ServicePrincipals] -----';
	PRINT N'Checking for existing table [dbo].[ServicePrincipals]...';

	-- Migration Case: control.Tenants already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'dbo' 
		AND  TABLE_NAME = 'ServicePrincipals')
	
	BEGIN
		PRINT N'Table [dbo].[ServicePrincipals] exists, creating a copy';
		EXEC sp_rename 'dbo.ServicePrincipals', 'ServicePrincipals_Migration';
	END


	PRINT N'Creating new table [dbo].[ServicePrincipals]...';

	CREATE TABLE [dbo].[ServicePrincipals] (
		[CredentialId]       INT              IDENTITY (1, 1) NOT NULL,
		[PrincipalName]      NVARCHAR (256)   NULL,
		[PrincipalId]        UNIQUEIDENTIFIER NULL,
		[PrincipalSecret]    VARBINARY (256)  NULL,
		[PrincipalIdUrl]     NVARCHAR (MAX)   NULL,
		[PrincipalSecretUrl] NVARCHAR (MAX)   NULL,
		CONSTRAINT [PK_ServicePrincipals] PRIMARY KEY CLUSTERED ([CredentialId] ASC)
	);

	PRINT N'Table [dbo].[ServicePrincipals] created';
	PRINT N'Migrating data to new table [dbo].[ServicePrincipals]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'dbo' 
		AND  TABLE_NAME = 'ServicePrincipals_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [dbo].[ServicePrincipals_Migration])
		BEGIN
			SET IDENTITY_INSERT [dbo].[ServicePrincipals] ON;
			INSERT INTO [dbo].[ServicePrincipals] ([CredentialId],[PrincipalName],[PrincipalId],[PrincipalSecret],[PrincipalIdUrl],[PrincipalSecretUrl])
			SELECT  
				[CredentialId],
				[PrincipalName],
				[PrincipalId],
				[PrincipalSecret],
				[PrincipalIdUrl],
				[PrincipalSecretUrl]
			FROM     [dbo].[ServicePrincipals_Migration]
			ORDER BY [CredentialId] ASC;
			SET IDENTITY_INSERT [dbo].[ServicePrincipals] OFF;
		END
	END
	PRINT N'Migrated data to new table [dbo].[ServicePrincipals]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [dbo].[ServicePrincipals_Migration];
END

END

END
/*
Migrate Table Constraints
*/
BEGIN
-- Non Clustered Indexes
BEGIN
	CREATE NONCLUSTERED INDEX [IDX_GetPipelinesInStage]
		ON [control].[CurrentExecution]([LocalExecutionId] ASC, [StageId] ASC, [PipelineStatus] ASC)
		INCLUDE([PipelineId], [PipelineName], [OrchestratorType], [OrchestratorName], [ResourceGroupName]);
END

-- Default Constraints
BEGIN
	PRINT N'Creating Default Constraint [control].[DF_Properties_ValidFrom]...';
	ALTER TABLE [control].[Properties]
		ADD CONSTRAINT [DF_Properties_ValidFrom] DEFAULT (GETDATE()) FOR [ValidFrom];

	PRINT N'Creating Default Constraint [control].[DF_Stages_Enabled]...';
	ALTER TABLE [control].[Stages]
		ADD CONSTRAINT [DF_Stages_Enabled] DEFAULT ((1)) FOR [Enabled];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[ExecutionLog]...';
	ALTER TABLE [control].[ExecutionLog]
		ADD DEFAULT ('Unknown') FOR [CallingOrchestratorName];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[ExecutionLog]...';
	ALTER TABLE [control].[ExecutionLog]
		ADD DEFAULT ('Unknown') FOR [ResourceGroupName];
	
	PRINT N'Creating Default Constraint unnamed constraint on [control].[ExecutionLog]...';
	ALTER TABLE [control].[ExecutionLog]
		ADD DEFAULT ('N/A') FOR [OrchestratorType];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[ExecutionLog]...';
	ALTER TABLE [control].[ExecutionLog]
		ADD DEFAULT ('Unknown') FOR [OrchestratorName];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[ExecutionLog]...';
	ALTER TABLE [control].[ExecutionLog]
		ADD DEFAULT ('None') FOR [PipelineParamsUsed];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[CurrentExecution]...';
	ALTER TABLE [control].[CurrentExecution]
		ADD DEFAULT 0 FOR [IsBlocked];

	PRINT N'Creating Default Constraint [control].[DF_Pipelines_Enabled]...';
	ALTER TABLE [control].[Pipelines]
		ADD CONSTRAINT [DF_Pipelines_Enabled] DEFAULT ((1)) FOR [Enabled];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[PipelineAlertLink]...';
	ALTER TABLE [control].[PipelineAlertLink]
		ADD DEFAULT 1 FOR [Enabled];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[Recipients]...';
	ALTER TABLE [control].[Recipients]
		ADD DEFAULT ('TO') FOR [MessagePreference];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[Recipients]...';
	ALTER TABLE [control].[Recipients]
		ADD DEFAULT 1 FOR [Enabled];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[Orchestrators]...';
	ALTER TABLE [control].[Orchestrators]
		ADD DEFAULT (0) FOR [IsFrameworkOrchestrator];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[Batches]...';
	ALTER TABLE [control].[Batches]
		ADD DEFAULT (NEWID()) FOR [BatchId];

	PRINT N'Creating Default Constraint unnamed constraint on [control].[Batches]...';
	ALTER TABLE [control].[Batches]
		ADD DEFAULT (0) FOR [Enabled];
END

-- Foreign Keys
BEGIN
	PRINT N'Creating Foreign Key [control].[FK_PipelineAuthLink_Orchestrators]...';
	ALTER TABLE [control].[PipelineAuthLink] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineAuthLink_Orchestrators] FOREIGN KEY ([OrchestratorId]) REFERENCES [control].[Orchestrators] ([OrchestratorId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineAuthLink_Pipelines]...';
	ALTER TABLE [control].[PipelineAuthLink] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineAuthLink_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineAuthLink_ServicePrincipals]...';
	ALTER TABLE [control].[PipelineAuthLink] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineAuthLink_ServicePrincipals] FOREIGN KEY ([CredentialId]) REFERENCES [dbo].[ServicePrincipals] ([CredentialId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineParameters_Pipelines]...';
	ALTER TABLE [control].[PipelineParameters] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineParameters_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_Pipelines_Stages]...';
	ALTER TABLE [control].[Pipelines] WITH NOCHECK
		ADD CONSTRAINT [FK_Pipelines_Stages] FOREIGN KEY ([StageId]) REFERENCES [control].[Stages] ([StageId]);
	
	PRINT N'Creating Foreign Key [control].[FK_Pipelines_Orchestrators]...';
	ALTER TABLE [control].[Pipelines] WITH NOCHECK
		ADD CONSTRAINT [FK_Pipelines_Orchestrators] FOREIGN KEY ([OrchestratorId]) REFERENCES [control].[Orchestrators] ([OrchestratorId]);
	
	PRINT N'Creating Foreign Key [control].[FK_Pipelines_Pipelines]...';
	ALTER TABLE [control].[Pipelines] WITH NOCHECK
		ADD CONSTRAINT [FK_Pipelines_Pipelines] FOREIGN KEY ([LogicalPredecessorId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineDependencies_Pipelines]...';
	ALTER TABLE [control].[PipelineDependencies] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineDependencies_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineDependencies_Pipelines1]...';
	ALTER TABLE [control].[PipelineDependencies] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineDependencies_Pipelines1] FOREIGN KEY ([DependantPipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineAlertLink_Pipelines]...';
	ALTER TABLE [control].[PipelineAlertLink] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineAlertLink_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [control].[Pipelines] ([PipelineId]);
	
	PRINT N'Creating Foreign Key [control].[FK_PipelineAlertLink_Recipients]...';
	ALTER TABLE [control].[PipelineAlertLink] WITH NOCHECK
		ADD CONSTRAINT [FK_PipelineAlertLink_Recipients] FOREIGN KEY ([RecipientId]) REFERENCES [control].[Recipients] ([RecipientId]);
	
	PRINT N'Creating Foreign Key [control].[FK_Orchestrators_Subscriptions]...';
	ALTER TABLE [control].[Orchestrators] WITH NOCHECK
		ADD CONSTRAINT [FK_Orchestrators_Subscriptions] FOREIGN KEY ([SubscriptionId]) REFERENCES [control].[Subscriptions] ([SubscriptionId]);
	
	PRINT N'Creating Foreign Key [control].[FK_BatchStageLink_Batches]...';
	ALTER TABLE [control].[BatchStageLink] WITH NOCHECK
		ADD CONSTRAINT [FK_BatchStageLink_Batches] FOREIGN KEY ([BatchId]) REFERENCES [control].[Batches] ([BatchId]);
	
	PRINT N'Creating Foreign Key [control].[FK_BatchStageLink_Stages]...';
	ALTER TABLE [control].[BatchStageLink] WITH NOCHECK
		ADD CONSTRAINT [FK_BatchStageLink_Stages] FOREIGN KEY ([StageId]) REFERENCES [control].[Stages] ([StageId]);
	
	PRINT N'Creating Foreign Key [control].[FK_Subscriptions_Tenants]...';
	ALTER TABLE [control].[Subscriptions] WITH NOCHECK
		ADD CONSTRAINT [FK_Subscriptions_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [control].[Tenants] ([TenantId]);
END

-- Check Constraints
BEGIN
	PRINT N'Creating Check Constraint [control].[EQ_PipelineIdDependantPipelineId]...';
	ALTER TABLE [control].[PipelineDependencies] WITH NOCHECK
		ADD CONSTRAINT [EQ_PipelineIdDependantPipelineId] CHECK ([PipelineId] <> [DependantPipelineId]);

	PRINT N'Creating Check Constraint [control].[MessagePreferenceValue]...';
	ALTER TABLE [control].[Recipients] WITH NOCHECK
		ADD CONSTRAINT [MessagePreferenceValue] CHECK ([MessagePreference] IN ('TO','CC','BCC'));
		
	PRINT N'Creating Check Constraint [control].[OrchestratorType]...';
	ALTER TABLE [control].[Orchestrators] WITH NOCHECK
		ADD CONSTRAINT [OrchestratorType] CHECK ([OrchestratorType] IN ('ADF','SYN'));
END

END
/*
Migrate Views
       [control].[CurrentProperties] (View)
       [control].[PipelineParameterDataSizes] (View)
*/
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control] Views -----';

-- [control].[CurrentProperties]
	BEGIN
	PRINT N'----- Creating View [control].[CurrentProperties] -----';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND OBJECT_ID = OBJECT_ID('[control].[CurrentProperties]'))
	BEGIN
		EXEC ('CREATE VIEW [control].[CurrentProperties] AS SELECT 1 AS Col;')
	END

	EXEC ('
	ALTER VIEW [control].[CurrentProperties]
	AS
	SELECT
		[PropertyName],
		[PropertyValue]
	FROM
		[control].[Properties]
	WHERE
		[ValidTo] IS NULL;');

	EXEC sp_refreshview N'control.CurrentProperties';
	END

-- [control].[PipelineParameterDataSizes]
	BEGIN
	PRINT N'----- Creating View [control].[PipelineParameterDataSizes] -----';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND OBJECT_ID = OBJECT_ID('[control].[PipelineParameterDataSizes]'))
	BEGIN
		EXEC ('CREATE VIEW [control].[PipelineParameterDataSizes] AS SELECT 1 AS Col;')
	END

	EXEC ('
	ALTER VIEW [control].[PipelineParameterDataSizes]
	AS

	SELECT 
		[PipelineId],
		SUM(
			(CAST(
				DATALENGTH(
					STRING_ESCAPE([ParameterName] + [ParameterValue],''json'')) AS DECIMAL)
				/1024) --KB
				/1024 --MB
			) AS Size
	FROM 
		[control].[PipelineParameters]
	GROUP BY
		[PipelineId];');

	EXEC sp_refreshview N'control.PipelineParameterDataSizes';
	END
END

/*
Migrate Functions
		[control].[GetPropertyValueInternal] (Function)
*/
BEGIN
	--[control].[GetPropertyValueInternal]
	BEGIN
	PRINT N'----- Creating Function [control].[GetPropertyValueInternal] -----';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND OBJECT_ID = OBJECT_ID('[control].[GetPropertyValueInternal]'))
	BEGIN
		EXEC ('CREATE FUNCTION [control].[GetPropertyValueInternal] (@ExampleParameter INT) 
		RETURNS INT 
		AS 
		BEGIN 
			RETURN 1;
		END;')
	END

	EXEC ('
	ALTER FUNCTION [control].[GetPropertyValueInternal]
		(
		@PropertyName VARCHAR(128)
		)
	RETURNS NVARCHAR(MAX)
	AS
	BEGIN
		DECLARE @PropertyValue NVARCHAR(MAX)

		SELECT
			@PropertyValue = ISNULL([PropertyValue],'''')
		FROM
			[control].[CurrentProperties]
		WHERE
			[PropertyName] = @PropertyName

		RETURN @PropertyValue
	END;');

	EXEC sys.sp_refreshsqlmodule  N'control.GetPropertyValueInternal';
	END

END

/*
Migrate Stored Procedures
       [control].[ResetExecution] (Procedure)
       [control].[GetPropertyValue] (Procedure)
       [control].[UpdateExecutionLog] (Procedure)
       [control].[SetLogPipelineSuccess] (Procedure)
       [control].[SetLogPipelineRunning] (Procedure)
       [control].[SetLogStagePreparing] (Procedure)
       [control].[CreateNewExecution] (Procedure)
       [control].[GetPipelineParameters] (Procedure)
       [control].[GetPipelinesInStage] (Procedure)
       [control].[GetStages] (Procedure)
       [control].[GetWorkerPipelineDetails] (Procedure)
       [control].[GetWorkerAuthDetails] (Procedure)
       [control].[ExecutePrecursorProcedure] (Procedure)
       [control].[SetExecutionBlockDependants] (Procedure)
       [control].[SetLogPipelineChecking] (Procedure)
       [control].[GetEmailAlertParts] (Procedure)
       [control].[CheckForEmailAlerts] (Procedure)
       [control].[SetErrorLogDetails] (Procedure)
       [control].[SetLogPipelineRunId] (Procedure)
       [control].[SetLogPipelineLastStatusCheck] (Procedure)
       [control].[CheckMetadataIntegrity] (Procedure)
       [control].[SetLogActivityFailed] (Procedure)
       [control].[SetLogPipelineUnknown] (Procedure)
       [control].[GetWorkerPipelineDetailsv2] (Procedure)
       [control].[AddProperty] (Procedure)
       [control].[GetFrameworkOrchestratorDetails] (Procedure)
       [control].[GetWorkerDetailsWrapper] (Procedure)
       [control].[SetLogPipelineValidating] (Procedure)
       [control].[CheckPreviousExeuction] (Procedure)
       [control].[BatchWrapper] (Procedure)
       [control].[ExecutionWrapper] (Procedure)
       [control].[SetLogPipelineFailed] (Procedure)
       [control].[SetLogPipelineCancelled] (Procedure)
       [control].[CheckForBlockedPipelines] (Procedure)
*/
BEGIN

--[control].[ResetExecution] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[ResetExecution] Stored Procedure -----';

	PRINT N'Creating [control].[ResetExecution] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[ResetExecution]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[ResetExecution] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[ResetExecution]';
	EXEC('
	ALTER PROCEDURE [control].[ResetExecution]
		(
	@LocalExecutionId UNIQUEIDENTIFIER = NULL
	)
	AS
	BEGIN 
	SET NOCOUNT	ON;

	IF([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''0''
		BEGIN
			--capture any pipelines that might be in an unexpected state
			INSERT INTO [control].[ExecutionLog]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				[PipelineStatus],
				[EndDateTime]
				)
			SELECT
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				''Unknown'',
				[EndDateTime]
			FROM
				[control].[CurrentExecution]
			WHERE
				--these are predicted states
				[PipelineStatus] NOT IN
					(
					''Success'',
					''Failed'',
					''Blocked'',
					''Cancelled''
					);
		
			--reset status ready for next attempt
			UPDATE
				[control].[CurrentExecution]
			SET
				[StartDateTime] = NULL,
				[EndDateTime] = NULL,
				[PipelineStatus] = NULL,
				[LastStatusCheckDateTime] = NULL,
				[PipelineRunId] = NULL,
				[PipelineParamsUsed] = NULL,
				[IsBlocked] = 0
			WHERE
				ISNULL([PipelineStatus],'''') <> ''Success''
				OR [IsBlocked] = 1;

			--return current execution id
			SELECT DISTINCT
				[LocalExecutionId] AS ExecutionId
			FROM
				[control].[CurrentExecution];
		END
	ELSE IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
		BEGIN
			--capture any pipelines that might be in an unexpected state
			INSERT INTO [control].[ExecutionLog]
				(
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				[PipelineStatus],
				[EndDateTime]
				)
			SELECT
				[LocalExecutionId],
				[StageId],
				[PipelineId],
				[CallingOrchestratorName],
				[ResourceGroupName],
				[OrchestratorType],
				[OrchestratorName],
				[PipelineName],
				[StartDateTime],
				''Unknown'',
				[EndDateTime]
			FROM
				[control].[CurrentExecution]
			WHERE
				[LocalExecutionId] = @LocalExecutionId
				--these are predicted states
				AND [PipelineStatus] NOT IN
					(
					''Success'',
					''Failed'',
					''Blocked'',
					''Cancelled''
					);
		
			--reset status ready for next attempt
			UPDATE
				[control].[CurrentExecution]
			SET
				[StartDateTime] = NULL,
				[EndDateTime] = NULL,
				[PipelineStatus] = NULL,
				[LastStatusCheckDateTime] = NULL,
				[PipelineRunId] = NULL,
				[PipelineParamsUsed] = NULL,
				[IsBlocked] = 0
			WHERE
				[LocalExecutionId] = @LocalExecutionId
				AND ISNULL([PipelineStatus],'''') <> ''Success''
				OR [IsBlocked] = 1;
				
			UPDATE
				[control].[BatchExecution]
			SET
				[EndDateTime] = NULL,
				[BatchStatus] = ''Running''
			WHERE
				[ExecutionId] = @LocalExecutionId;

			SELECT 
				@LocalExecutionId AS ExecutionId
		END;
	END;
	');

	PRINT N'Update complete for [common].[ResetExecution]';
END

--[control].[GetPropertyValue] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetPropertyValue] Stored Procedure -----';

	PRINT N'Creating [control].[GetPropertyValue] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetPropertyValue]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetPropertyValue] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetPropertyValue]';
	EXEC('
	ALTER PROCEDURE [control].[GetPropertyValue]
		(
		@PropertyName VARCHAR(128)
		)
	AS
	BEGIN	
		DECLARE @ErrorDetail NVARCHAR(4000) = ''''

		--defensive checks
		IF NOT EXISTS
			(
			SELECT * FROM [control].[Properties] WHERE [PropertyName] = @PropertyName
			)
			BEGIN
				SET @ErrorDetail = ''Invalid property name provided. Property does not exist.''
				RAISERROR(@ErrorDetail, 16, 1);
				RETURN 0;
			END
		ELSE IF NOT EXISTS
			(
			SELECT * FROM [control].[Properties] WHERE [PropertyName] = @PropertyName AND [ValidTo] IS NULL
			)
			BEGIN
				SET @ErrorDetail = ''Property name provided does not have a current valid version of the required value.''
				RAISERROR(@ErrorDetail, 16, 1);
				RETURN 0;
			END
		--get valid property value
		ELSE
			BEGIN
				SELECT
					[PropertyValue]
				FROM
					[control].[CurrentProperties]
				WHERE
					[PropertyName] = @PropertyName
			END
	END;');

	PRINT N'Update complete for [common].[GetPropertyValue]';
END

--[control].[UpdateExecutionLog] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[UpdateExecutionLog] Stored Procedure -----';

	PRINT N'Creating [control].[UpdateExecutionLog] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[UpdateExecutionLog]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[UpdateExecutionLog] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[UpdateExecutionLog]';
	EXEC('
	ALTER PROCEDURE [control].[UpdateExecutionLog]
		(
		@PerformErrorCheck BIT = 1,
		@ExecutionId UNIQUEIDENTIFIER = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;
			
		DECLARE @AllCount INT
		DECLARE @SuccessCount INT

		IF([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''0''
			BEGIN
				IF @PerformErrorCheck = 1
				BEGIN
					--Check current execution
					SELECT @AllCount = COUNT(0) FROM [control].[CurrentExecution]
					SELECT @SuccessCount = COUNT(0) FROM [control].[CurrentExecution] WHERE [PipelineStatus] = ''Success''

					IF @AllCount <> @SuccessCount
						BEGIN
							RAISERROR(''Framework execution complete but not all Worker pipelines succeeded. See the [control].[CurrentExecution] table for details'',16,1);
							RETURN 0;
						END;
				END;

				--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
				INSERT INTO [control].[ExecutionLog]
					(
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName],
					[StartDateTime],
					[PipelineStatus],
					[EndDateTime],
					[PipelineRunId],
					[PipelineParamsUsed]
					)
				SELECT
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName],
					[StartDateTime],
					[PipelineStatus],
					[EndDateTime],
					[PipelineRunId],
					[PipelineParamsUsed]
				FROM
					[control].[CurrentExecution];

				TRUNCATE TABLE [control].[CurrentExecution];
			END
		ELSE IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
			BEGIN
				IF @PerformErrorCheck = 1
				BEGIN
					--Check current execution
					SELECT 
						@AllCount = COUNT(0) 
					FROM 
						[control].[CurrentExecution] 
					WHERE 
						[LocalExecutionId] = @ExecutionId;
					
					SELECT 
						@SuccessCount = COUNT(0) 
					FROM 
						[control].[CurrentExecution] 
					WHERE 
						[LocalExecutionId] = @ExecutionId 
						AND [PipelineStatus] = ''Success'';

					IF @AllCount <> @SuccessCount
						BEGIN
							UPDATE
								[control].[BatchExecution]
							SET
								[BatchStatus] = ''Stopped'',
								[EndDateTime] = GETUTCDATE()
							WHERE
								[ExecutionId] = @ExecutionId;
							
							RAISERROR(''Framework execution complete for batch but not all Worker pipelines succeeded. See the [control].[CurrentExecution] table for details'',16,1);
							RETURN 0;
						END;
					ELSE
						BEGIN
							UPDATE
								[control].[BatchExecution]
							SET
								[BatchStatus] = ''Success'',
								[EndDateTime] = GETUTCDATE()
							WHERE
								[ExecutionId] = @ExecutionId;
						END;
				END; --end check

				--Do this if no error raised and when called by the execution wrapper (OverideRestart = 1).
				INSERT INTO [control].[ExecutionLog]
					(
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName],
					[StartDateTime],
					[PipelineStatus],
					[EndDateTime],
					[PipelineRunId],
					[PipelineParamsUsed]
					)
				SELECT
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName],
					[StartDateTime],
					[PipelineStatus],
					[EndDateTime],
					[PipelineRunId],
					[PipelineParamsUsed]
				FROM
					[control].[CurrentExecution]
				WHERE 
					[LocalExecutionId] = @ExecutionId;

				DELETE FROM
					[control].[CurrentExecution]
				WHERE
					[LocalExecutionId] = @ExecutionId;
			END;
	END;
	');

	PRINT N'Update complete for [common].[UpdateExecutionLog]';
END

--[control].[SetLogPipelineSuccess] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineSuccess] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineSuccess] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineSuccess]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineSuccess] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineSuccess]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineSuccess]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			--case for clean up runs
			[EndDateTime] = CASE WHEN [EndDateTime] IS NULL THEN GETUTCDATE() ELSE [EndDateTime] END,
			[PipelineStatus] = ''Success''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineSuccess]';
END

--[control].[SetLogPipelineRunning] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineRunning] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineRunning] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineRunning]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineRunning] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineRunning]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineRunning]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			--case for clean up runs
			[StartDateTime] = CASE WHEN [StartDateTime] IS NULL THEN GETUTCDATE() ELSE [StartDateTime] END,
			[PipelineStatus] = ''Running''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineRunning]';
END

--[control].[SetLogStagePreparing] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogStagePreparing] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogStagePreparing] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogStagePreparing]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogStagePreparing] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogStagePreparing]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogStagePreparing]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;
		
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Preparing''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [StartDateTime] IS NULL
			AND [IsBlocked] <> 1;
	END;
	');

	PRINT N'Update complete for [common].[SetLogStagePreparing]';
END

--[control].[CreateNewExecution] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[CreateNewExecution] Stored Procedure -----';

	PRINT N'Creating [control].[CreateNewExecution] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[CreateNewExecution]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[CreateNewExecution] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[CreateNewExecution]';
	EXEC('
	ALTER PROCEDURE [control].[CreateNewExecution]
		(
		@CallingOrchestratorName NVARCHAR(200),
		@LocalExecutionId UNIQUEIDENTIFIER = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @BatchId UNIQUEIDENTIFIER;

		IF([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''0''
			BEGIN
				SET @LocalExecutionId = NEWID();

				TRUNCATE TABLE [control].[CurrentExecution];

				--defensive check
				IF NOT EXISTS
					(
					SELECT
						1
					FROM
						[control].[Pipelines] p
						INNER JOIN [control].[Stages] s
							ON p.[StageId] = s.[StageId]
						INNER JOIN [control].[Orchestrators] d
							ON p.[OrchestratorId] = d.[OrchestratorId]
					WHERE
						p.[Enabled] = 1
						AND s.[Enabled] = 1
					)
					BEGIN
						RAISERROR(''Requested execution run does not contain any enabled stages/pipelines.'',16,1);
						RETURN 0;
					END;

				INSERT INTO [control].[CurrentExecution]
					(
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName]
					)
				SELECT
					@LocalExecutionId,
					p.[StageId],
					p.[PipelineId],
					@CallingOrchestratorName,
					d.[ResourceGroupName],
					d.[OrchestratorType],
					d.[OrchestratorName],
					p.[PipelineName]
				FROM
					[control].[Pipelines] p
					INNER JOIN [control].[Stages] s
						ON p.[StageId] = s.[StageId]
					INNER JOIN [control].[Orchestrators] d
						ON p.[OrchestratorId] = d.[OrchestratorId]
				WHERE
					p.[Enabled] = 1
					AND s.[Enabled] = 1;

				SELECT
					@LocalExecutionId AS ExecutionId;
			END
		ELSE IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
			BEGIN
				DELETE FROM 
					[control].[CurrentExecution]
				WHERE
					[LocalExecutionId] = @LocalExecutionId;

				SELECT
					@BatchId = [BatchId]
				FROM
					[control].[BatchExecution]
				WHERE
					[ExecutionId] = @LocalExecutionId;
				
				--defensive check
				IF NOT EXISTS
					(
					SELECT
						1
					FROM
						[control].[Pipelines] p
						INNER JOIN [control].[Stages] s
							ON p.[StageId] = s.[StageId]
						INNER JOIN [control].[Orchestrators] d
							ON p.[OrchestratorId] = d.[OrchestratorId]
						INNER JOIN [control].[BatchStageLink] b
							ON b.[StageId] = s.[StageId]
					WHERE
						b.[BatchId] = @BatchId
						AND p.[Enabled] = 1
						AND s.[Enabled] = 1
					)
					BEGIN
						RAISERROR(''Requested execution run does not contain any enabled stages/pipelines.'',16,1);
						RETURN 0;
					END;

				INSERT INTO [control].[CurrentExecution]
					(
					[LocalExecutionId],
					[StageId],
					[PipelineId],
					[CallingOrchestratorName],
					[ResourceGroupName],
					[OrchestratorType],
					[OrchestratorName],
					[PipelineName]
					)
				SELECT
					@LocalExecutionId,
					p.[StageId],
					p.[PipelineId],
					@CallingOrchestratorName,
					d.[ResourceGroupName],
					d.[OrchestratorType],
					d.[OrchestratorName],
					p.[PipelineName]
				FROM
					[control].[Pipelines] p
					INNER JOIN [control].[Stages] s
						ON p.[StageId] = s.[StageId]
					INNER JOIN [control].[Orchestrators] d
						ON p.[OrchestratorId] = d.[OrchestratorId]
					INNER JOIN [control].[BatchStageLink] b
						ON b.[StageId] = s.[StageId]
				WHERE
					b.[BatchId] = @BatchId
					AND p.[Enabled] = 1
					AND s.[Enabled] = 1;
					
				SELECT
					@LocalExecutionId AS ExecutionId;
			END;

		ALTER INDEX [IDX_GetPipelinesInStage] ON [control].[CurrentExecution]
		REBUILD;
	END;
	');

	PRINT N'Update complete for [common].[CreateNewExecution]';
END

--[control].[GetPipelineParameters] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetPipelineParameters] Stored Procedure -----';

	PRINT N'Creating [control].[GetPipelineParameters] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetPipelineParameters]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetPipelineParameters] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetPipelineParameters]';
	EXEC('
	ALTER PROCEDURE [control].[GetPipelineParameters]
		(
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @Json VARCHAR(MAX) = ''''

		--get parameters if required for worker pipeline
		IF NOT EXISTS
			(
			SELECT 
				[ParameterId] 
			FROM 
				[control].[PipelineParameters] 
			WHERE 
				[PipelineId] = @PipelineId
			)
			BEGIN
				SET @Json = '''' --Can''t return NULL. Would break ADF expression.
			END
		ELSE
			BEGIN
				SELECT
					@Json += 
							CASE
								WHEN [ParameterValue] IS NULL THEN '''' --don''t add pair so ADF uses default
								ELSE ''"'' + [ParameterName] + ''": "'' + STRING_ESCAPE([ParameterValue],''json'') + ''",''
							END
				FROM
					[control].[PipelineParameters]
				WHERE
					[PipelineId] = @PipelineId;
				
				--handle parameter(s) with a NULL values
				IF LEN(@Json) > 0
				BEGIN
					--JSON snippet gets injected into Azure Function body request via Orchestrator expressions.
					--Comma used to support Orchestrator expression.
					SET @Json = '',"pipelineParameters": {'' + LEFT(@Json,LEN(@Json)-1) + ''}''

					--update current execution log if this is a runtime request
					UPDATE
						[control].[CurrentExecution]
					SET
						--add extra braces to make JSON string valid in logs
						[PipelineParamsUsed] = ''{ '' + RIGHT(@Json,LEN(@Json)-1) + '' }''
					WHERE
						[PipelineId] = @PipelineId;

					--set last values values
					UPDATE
						[control].[PipelineParameters]
					SET
						[ParameterValueLastUsed] = [ParameterValue]
					WHERE
						[PipelineId] = @PipelineId;
				END;
			END;

		--return JSON snippet
		SELECT @Json AS Params
	END;
	');

	PRINT N'Update complete for [common].[GetPipelineParameters]';
END

--[control].[GetPipelinesInStage] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetPipelinesInStage] Stored Procedure -----';

	PRINT N'Creating [control].[GetPipelinesInStage] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetPipelinesInStage]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetPipelinesInStage] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetPipelinesInStage]';
	EXEC('
	ALTER PROCEDURE [control].[GetPipelinesInStage]
			(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		SELECT 
			[PipelineId]
		FROM 
			[control].[CurrentExecution]
		WHERE 
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND ISNULL([PipelineStatus],'''') <> ''Success''
			AND [IsBlocked] <> 1
		ORDER BY
			[PipelineId] ASC;
	END;
	');

	PRINT N'Update complete for [common].[GetPipelinesInStage]';
END

--[control].[GetStages] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetStages] Stored Procedure -----';

	PRINT N'Creating [control].[GetStages] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetStages]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetStages] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetStages]';
	EXEC('
	ALTER PROCEDURE [control].[GetStages]
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
				AND ISNULL([PipelineStatus],'''') <> ''Success''
			)
			BEGIN
				RAISERROR(''Requested execution run does not contain any enabled stages/pipelines.'',16,1);
				RETURN 0;
			END;

		SELECT DISTINCT 
			[StageId] 
		FROM 
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND ISNULL([PipelineStatus],'''') <> ''Success''
		ORDER BY 
			[StageId] ASC
	END;
	');

	PRINT N'Update complete for [common].[GetStages]';
END

--[control].[GetWorkerPipelineDetails] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetWorkerPipelineDetails] Stored Procedure -----';

	PRINT N'Creating [control].[GetWorkerPipelineDetails] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetWorkerPipelineDetails]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetWorkerPipelineDetails] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetWorkerPipelineDetails]';
	EXEC('
	ALTER PROCEDURE [control].[GetWorkerPipelineDetails]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		SELECT 
			[PipelineName],
			[OrchestratorName],
			[OrchestratorType],
			[ResourceGroupName]
		FROM 
			[control].[CurrentExecution]
		WHERE 
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;
	END;
	');

	PRINT N'Update complete for [common].[GetWorkerPipelineDetails]';
END

--[control].[GetWorkerAuthDetails] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetWorkerAuthDetails] Stored Procedure -----';

	PRINT N'Creating [control].[GetWorkerAuthDetails] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetWorkerAuthDetails]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetWorkerAuthDetails] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetWorkerAuthDetails]';
	EXEC('
	ALTER PROCEDURE [control].[GetWorkerAuthDetails]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @TenId NVARCHAR(MAX)
		DECLARE @SubId NVARCHAR(MAX)
		DECLARE @AppId NVARCHAR(MAX)
		DECLARE @AppSecret NVARCHAR(MAX)

		DECLARE @OrchestratorName NVARCHAR(200)
		DECLARE @OrchestratorType CHAR(3)
		DECLARE @PipelineName NVARCHAR(200)

		SELECT 
			@PipelineName = [PipelineName],
			@OrchestratorName = [OrchestratorName],
			@OrchestratorType = [OrchestratorType]
		FROM 
			[control].[CurrentExecution]
		WHERE 
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;
			

		IF ([control].[GetPropertyValueInternal](''SPNHandlingMethod'')) = ''StoreInDatabase''
			BEGIN
				--get auth details regardless of being pipeline specific and regardless of a pipeline param being passed
				;WITH cte AS
					(
					SELECT DISTINCT
						Sub.[TenantId],
						Sub.[SubscriptionId],
						S.[PrincipalId] AS AppId,
						CAST(DECRYPTBYPASSPHRASE(CONCAT(@OrchestratorName, @OrchestratorType, @PipelineName), S.[PrincipalSecret]) AS NVARCHAR(MAX)) AS AppSecret
					FROM
						[dbo].[ServicePrincipals] S
						INNER JOIN  [control].[PipelineAuthLink] L
							ON S.[CredentialId] = L.[CredentialId]
						INNER JOIN [control].[Pipelines] P
							ON L.[PipelineId] = P.[PipelineId]
						INNER JOIN [control].[Orchestrators] D
							ON P.[OrchestratorId] = D.[OrchestratorId]
								AND L.[OrchestratorId] = D.[OrchestratorId]
						INNER JOIN [control].[Subscriptions] Sub
							ON D.[SubscriptionId] = Sub.[SubscriptionId]
					WHERE
						P.[PipelineName] = @PipelineName
						AND D.[OrchestratorName] = @OrchestratorName
						AND D.[OrchestratorType] = @OrchestratorType
				
					UNION

					SELECT DISTINCT
						Sub.[TenantId],
						Sub.[SubscriptionId],					
						S.[PrincipalId] AS AppId,
						CAST(DECRYPTBYPASSPHRASE(CONCAT(@OrchestratorName, @OrchestratorType), S.[PrincipalSecret]) AS NVARCHAR(MAX)) AS AppSecret
					FROM
						[dbo].[ServicePrincipals] S
						INNER JOIN  [control].[PipelineAuthLink] L
							ON S.[CredentialId] = L.[CredentialId]
						INNER JOIN [control].[Orchestrators] D
							ON L.[OrchestratorId] = D.[OrchestratorId]
						INNER JOIN [control].[Subscriptions] Sub
							ON D.[SubscriptionId] = Sub.[SubscriptionId]
					WHERE
						D.[OrchestratorName] = @OrchestratorName
						AND D.[OrchestratorType] = @OrchestratorType
					)
				SELECT TOP 1
					@TenId = [TenantId],
					@SubId = [SubscriptionId],
					@AppId = [AppId],
					@AppSecret = [AppSecret]
				FROM
					cte
				WHERE
					[AppSecret] IS NOT NULL
			END
		ELSE IF ([control].[GetPropertyValueInternal](''SPNHandlingMethod'')) = ''StoreInKeyVault''
			BEGIN
				
				--get auth details regardless of being pipeline specific and regardless of a pipeline param being passed
				;WITH cte AS
					(
					SELECT DISTINCT
						Sub.[TenantId],
						Sub.[SubscriptionId],						
						S.[PrincipalIdUrl] AS AppId,
						S.[PrincipalSecretUrl] AS AppSecret
					FROM
						[dbo].[ServicePrincipals] S
						INNER JOIN  [control].[PipelineAuthLink] L
							ON S.[CredentialId] = L.[CredentialId]
						INNER JOIN [control].[Pipelines] P
							ON L.[PipelineId] = P.[PipelineId]
						INNER JOIN [control].[Orchestrators] D
							ON P.[OrchestratorId] = D.[OrchestratorId]
								AND L.[OrchestratorId] = D.[OrchestratorId]
						INNER JOIN [control].[Subscriptions] Sub
							ON D.[SubscriptionId] = Sub.[SubscriptionId]
					WHERE
						P.[PipelineName] = @PipelineName
						AND D.[OrchestratorName] = @OrchestratorName
						AND D.[OrchestratorType] = @OrchestratorType
				
					UNION

					SELECT DISTINCT
						Sub.[TenantId],
						Sub.[SubscriptionId],					
						S.[PrincipalIdUrl] AS AppId,
						S.[PrincipalSecretUrl] AS AppSecret
					FROM
						[dbo].[ServicePrincipals] S
						INNER JOIN  [control].[PipelineAuthLink] L
							ON S.[CredentialId] = L.[CredentialId]
						INNER JOIN [control].[Orchestrators] D
							ON L.[OrchestratorId] = D.[OrchestratorId]
						INNER JOIN [control].[Subscriptions] Sub
							ON D.[SubscriptionId] = Sub.[SubscriptionId]
					WHERE
						D.[OrchestratorName] = @OrchestratorName
						AND D.[OrchestratorType] = @OrchestratorType
					)
				SELECT TOP 1
					@TenId = [TenantId],
					@SubId = [SubscriptionId],
					@AppId = [AppId],
					@AppSecret = [AppSecret]
				FROM
					cte
				WHERE
					[AppSecret] IS NOT NULL
			END
		ELSE
			BEGIN
				RAISERROR(''Unknown SPN retrieval method.'',16,1);
				RETURN 0;
			END

		--return usable values
		SELECT
			@TenId AS TenantId,
			@SubId AS SubscriptionId,
			@AppId AS AppId,
			@AppSecret AS AppSecret
	END;
	');

	PRINT N'Update complete for [common].[GetWorkerAuthDetails]';
END

--[control].[ExecutePrecursorProcedure] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[ExecutePrecursorProcedure] Stored Procedure -----';

	PRINT N'Creating [control].[ExecutePrecursorProcedure] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[ExecutePrecursorProcedure]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[ExecutePrecursorProcedure] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[ExecutePrecursorProcedure]';
	EXEC('
	ALTER PROCEDURE [control].[ExecutePrecursorProcedure]
	AS
	BEGIN
		DECLARE @SQL VARCHAR(MAX) 
		DECLARE @ErrorDetail NVARCHAR(MAX)

		IF OBJECT_ID([control].[GetPropertyValueInternal](''ExecutionPrecursorProc'')) IS NOT NULL
			BEGIN
				BEGIN TRY
					SET @SQL = [control].[GetPropertyValueInternal](''ExecutionPrecursorProc'');
					EXEC(@SQL);
				END TRY
				BEGIN CATCH
					SELECT
						@ErrorDetail = ''Precursor procedure failed with error: '' + ERROR_MESSAGE();

					RAISERROR(@ErrorDetail,16,1);
				END CATCH
			END;
		ELSE
			BEGIN
				PRINT ''Precursor object not found in database.'';
			END;
	END;
	');

	PRINT N'Update complete for [common].[ExecutePrecursorProcedure]';
END

--[control].[SetExecutionBlockDependants] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetExecutionBlockDependants] Stored Procedure -----';

	PRINT N'Creating [control].[SetExecutionBlockDependants] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetExecutionBlockDependants]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetExecutionBlockDependants] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetExecutionBlockDependants]';
	EXEC('
	ALTER PROCEDURE [control].[SetExecutionBlockDependants]
		(
		@ExecutionId UNIQUEIDENTIFIER = NULL,
		@PipelineId INT
		)
	AS
	BEGIN
		--update dependents status
		UPDATE
			ce
		SET
			ce.[PipelineStatus] = ''Blocked'',
			ce.[IsBlocked] = 1
		FROM
			[control].[PipelineDependencies] pe
			INNER JOIN [control].[CurrentExecution] ce
				ON pe.[DependantPipelineId] = ce.[PipelineId]
		WHERE
			ce.[LocalExecutionId] = @ExecutionId
			AND pe.[PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetExecutionBlockDependants]';
END

--[control].[SetLogPipelineChecking] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineChecking] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineChecking] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineChecking]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineChecking] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineChecking]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineChecking]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Checking''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineChecking]';
END

--[control].[GetEmailAlertParts] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetEmailAlertParts] Stored Procedure -----';

	PRINT N'Creating [control].[GetEmailAlertParts] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetEmailAlertParts]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetEmailAlertParts] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetEmailAlertParts]';
	EXEC('
	ALTER PROCEDURE [control].[GetEmailAlertParts]
		(
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ToRecipients NVARCHAR(MAX) = ''''
		DECLARE @CcRecipients NVARCHAR(MAX) = ''''
		DECLARE @BccRecipients NVARCHAR(MAX) = ''''
		DECLARE @EmailSubject NVARCHAR(500)
		DECLARE	@EmailBody NVARCHAR(MAX)
		DECLARE @EmailImportance VARCHAR(5)
		DECLARE @OutcomeBitValue INT

		--map pipeline status to alert outcome bit value
		SELECT
			@OutcomeBitValue = ao.[BitValue]
		FROM
			[control].[CurrentExecution] ce
			INNER JOIN [control].[AlertOutcomes] ao
				ON ce.[PipelineStatus] = ao.[PipelineOutcomeStatus]
		WHERE
			ce.[PipelineId] = @PipelineId;

		--get to recipients
		SELECT
			@ToRecipients += r.[EmailAddress] + '',''
		FROM
			[control].[PipelineAlertLink] al
			INNER JOIN [control].[Recipients] r
				ON al.[RecipientId] = r.[RecipientId]
		WHERE
			al.[PipelineId] = @PipelineId
			AND al.[Enabled] = 1
			AND r.[Enabled] = 1
			AND UPPER(r.[MessagePreference]) = ''TO''
			AND (
				al.[OutcomesBitValue] & @OutcomeBitValue <> 0
				OR al.[OutcomesBitValue] & 1 <> 0 --all
				);

		IF (@ToRecipients <> '''') SET @ToRecipients = LEFT(@ToRecipients,LEN(@ToRecipients)-1);

		--get cc recipients
		SELECT
			@CcRecipients += r.[EmailAddress] + '',''
		FROM
			[control].[PipelineAlertLink] al
			INNER JOIN [control].[Recipients] r
				ON al.[RecipientId] = r.[RecipientId]
		WHERE
			al.[PipelineId] = @PipelineId
			AND al.[Enabled] = 1
			AND r.[Enabled] = 1
			AND UPPER(r.[MessagePreference]) = ''CC''
			AND (
				al.[OutcomesBitValue] & @OutcomeBitValue <> 0
				OR al.[OutcomesBitValue] & 1 <> 0 --all
				);
		
		IF (@CcRecipients <> '''') SET @CcRecipients = LEFT(@CcRecipients,LEN(@CcRecipients)-1);

		--get bcc recipients
		SELECT
			@BccRecipients += r.[EmailAddress] + '',''
		FROM
			[control].[PipelineAlertLink] al
			INNER JOIN [control].[Recipients] r
				ON al.[RecipientId] = r.[RecipientId]
		WHERE
			al.[PipelineId] = @PipelineId
			AND al.[Enabled] = 1
			AND r.[Enabled] = 1
			AND UPPER(r.[MessagePreference]) = ''BCC''
			AND (
				al.[OutcomesBitValue] & @OutcomeBitValue <> 0
				OR al.[OutcomesBitValue] & 1 <> 0 --all
				);

		IF (@BccRecipients <> '''') SET @BccRecipients = LEFT(@BccRecipients,LEN(@BccRecipients)-1);
		
		--get email template
		SELECT
			@EmailBody = [PropertyValue]
		FROM
			[control].[CurrentProperties]
		WHERE
			[PropertyName] = ''EmailAlertBodyTemplate'';

		--set subject, body and importance
		SELECT TOP (1)
			--subject
			@EmailSubject = ''ProcFwk Alert: '' + [PipelineName] + '' - '' + [PipelineStatus],
		
			--body
			@EmailBody = REPLACE(@EmailBody,''##PipelineName###'',[PipelineName]),
			@EmailBody = REPLACE(@EmailBody,''##Status###'',[PipelineStatus]),
			@EmailBody = REPLACE(@EmailBody,''##ExecId###'',CAST([LocalExecutionId] AS VARCHAR(36))),
			@EmailBody = REPLACE(@EmailBody,''##RunId###'',CAST([PipelineRunId] AS VARCHAR(36))),
			@EmailBody = REPLACE(@EmailBody,''##StartDateTime###'',CONVERT(VARCHAR(30), [StartDateTime], 120)),
			@EmailBody = CASE
							WHEN [EndDateTime] IS NULL THEN REPLACE(@EmailBody,''##EndDateTime###'',''N/A'')
							ELSE REPLACE(@EmailBody,''##EndDateTime###'',CONVERT(VARCHAR(30), [EndDateTime], 120))
						END,
			@EmailBody = CASE
							WHEN [EndDateTime] IS NULL THEN REPLACE(@EmailBody,''##Duration###'',''N/A'')
							ELSE REPLACE(@EmailBody,''##Duration###'',CAST(DATEDIFF(MINUTE, [StartDateTime], [EndDateTime]) AS VARCHAR(30)))
						END,
			@EmailBody = REPLACE(@EmailBody,''##CalledByOrc###'',[CallingOrchestratorName]),
			@EmailBody = REPLACE(@EmailBody,''##ExecutedByOrcType###'',[OrchestratorType]),
			@EmailBody = REPLACE(@EmailBody,''##ExecutedByOrc###'',[OrchestratorName]),

			--importance
			@EmailImportance = 
				CASE [PipelineStatus] 
					WHEN ''Success'' THEN ''Low''
					WHEN ''Failed'' THEN ''High''
					ELSE ''Normal''
				END
		FROM
			[control].[CurrentExecution]
		WHERE
			[PipelineId] = @PipelineId
		ORDER BY
			[StartDateTime] DESC;
		
		--precaution
		IF @EmailBody IS NULL
			SET @EmailBody = ''Internal error. Failed to create profwk email alert body. Execute procedure [control].[GetEmailAlertParts] with pipeline Id: '' + CAST(@PipelineId AS VARCHAR(30)) + '' to debug.'';

		--return email parts
		SELECT
			@ToRecipients AS emailRecipients,
			@CcRecipients AS emailCcRecipients,
			@BccRecipients AS emailBccRecipients,
			@EmailSubject AS emailSubject,
			@EmailBody AS emailBody,
			@EmailImportance AS emailImportance;
	END;
	');

	PRINT N'Update complete for [common].[GetEmailAlertParts]';
END

--[control].[CheckForEmailAlerts] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[CheckForEmailAlerts] Stored Procedure -----';

	PRINT N'Creating [control].[CheckForEmailAlerts] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[CheckForEmailAlerts]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[CheckForEmailAlerts] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[CheckForEmailAlerts]';
	EXEC('
	ALTER PROCEDURE [control].[CheckForEmailAlerts]
		(
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @SendAlerts BIT
		DECLARE @AlertingEnabled BIT

		--get property
		SELECT
			@AlertingEnabled = [control].[GetPropertyValueInternal](''UseFrameworkEmailAlerting'');

		--based on global property
		IF (@AlertingEnabled = 1)
			BEGIN
				--based on piplines to recipients link
				IF EXISTS
					(
					SELECT 
						pal.AlertId
					FROM 
						[control].CurrentExecution AS ce
						INNER JOIN [control].AlertOutcomes AS ao
							ON ao.PipelineOutcomeStatus = ce.PipelineStatus
						INNER JOIN [control].PipelineAlertLink AS pal
							ON pal.PipelineId = ce.PipelineId
						INNER JOIN [control].Recipients AS r
							ON r.RecipientId = pal.RecipientId
					WHERE 
						ce.PipelineId = @PipelineId
						AND (
							ao.BitValue & pal.OutcomesBitValue <> 0
							OR pal.OutcomesBitValue & 1 <> 0 --all
							)
						AND pal.[Enabled] = 1
						AND r.[Enabled] = 1
					)
					BEGIN
						SET @SendAlerts = 1;
					END;
				ELSE
					BEGIN
						SET @SendAlerts = 0;
					END;
			END
		ELSE
			BEGIN
				SET @SendAlerts = 0;
			END;

		SELECT @SendAlerts AS SendAlerts
	END;
	');

	PRINT N'Update complete for [common].[CheckForEmailAlerts]';
END

--[control].[SetErrorLogDetails] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetErrorLogDetails] Stored Procedure -----';

	PRINT N'Creating [control].[SetErrorLogDetails] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetErrorLogDetails]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetErrorLogDetails] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetErrorLogDetails]';
	EXEC('
	ALTER PROCEDURE [control].[SetErrorLogDetails]
		(
		@LocalExecutionId UNIQUEIDENTIFIER,
		@JsonErrorDetails VARCHAR(MAX)
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		INSERT INTO [control].[ErrorLog]
			(
			[LocalExecutionId],
			[PipelineRunId],
			[ActivityRunId],
			[ActivityName],
			[ActivityType],
			[ErrorCode],
			[ErrorType],
			[ErrorMessage]
			)
		SELECT
			@LocalExecutionId,
			Base.[RunId],
			ErrorDetail.[ActivityRunId],
			ErrorDetail.[ActivityName],
			ErrorDetail.[ActivityType],
			ErrorDetail.[ErrorCode],
			ErrorDetail.[ErrorType],
			ErrorDetail.[ErrorMessage]
		FROM 
			OPENJSON(@JsonErrorDetails) WITH
				( 
				[RunId] UNIQUEIDENTIFIER,
				[Errors] NVARCHAR(MAX) AS JSON
				) AS Base
			CROSS APPLY OPENJSON (Base.[Errors]) WITH
				(
				[ActivityRunId] UNIQUEIDENTIFIER,
				[ActivityName] VARCHAR(100),
				[ActivityType] VARCHAR(100),
				[ErrorCode] VARCHAR(100),
				[ErrorType] VARCHAR(100),
				[ErrorMessage] VARCHAR(MAX)
				) AS ErrorDetail
	END;
	');

	PRINT N'Update complete for [common].[SetErrorLogDetails]';
END

--[control].[SetLogPipelineRunId] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineRunId] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineRunId] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineRunId]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineRunId] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineRunId]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineRunId]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@RunId UNIQUEIDENTIFIER = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineRunId] = LOWER(@RunId)
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineRunId]';
END

--[control].[SetLogPipelineLastStatusCheck] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineLastStatusCheck] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineLastStatusCheck] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineLastStatusCheck]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineLastStatusCheck] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineLastStatusCheck]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineLastStatusCheck]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			[LastStatusCheckDateTime] = GETUTCDATE()
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineLastStatusCheck]';
END

--[control].[CheckMetadataIntegrity] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[CheckMetadataIntegrity] Stored Procedure -----';

	PRINT N'Creating [control].[CheckMetadataIntegrity] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[CheckMetadataIntegrity]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[CheckMetadataIntegrity] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[CheckMetadataIntegrity]';
	EXEC('
	ALTER PROCEDURE [control].[CheckMetadataIntegrity]
		(
		@DebugMode BIT = 0,
		@BatchName VARCHAR(255) = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;
		
		/*
		Check 1 - Are there execution stages enabled in the metadata?
		Check 2 - Are there pipelines enabled in the metadata?
		Check 3 - Are there any service principals available to run the processing pipelines?
		Check 4 - Is there at least one TenantId available?
		Check 5 - Is there at least one SubscriptionId available?
		Check 6 - Is there a current OverideRestart property available?
		Check 7 - Are there any enabled pipelines configured without a service principal?
		Check 8 - Are any Orchestrators set to use the default subscription value?
		Check 9 - Are any Subscription set to use the default tenant value?
		Check 10 - Is there a current PipelineStatusCheckDuration property available?
		Check 11 - Is there a current UseFrameworkEmailAlerting property available?
		Check 12 - Is there a current EmailAlertBodyTemplate property available?
		Check 13 - Does the total size of the request body for the pipeline parameters added exceed the Azure Functions size limit when the Worker execute pipeline body is created?
		Check 14 - Is there a current FailureHandling property available?
		Check 15 - Does the FailureHandling property have a valid value?
		Check 16 - When using DependencyChain failure handling, are there any dependants in the same execution stage of the predecessor?
		Check 17 - Does the SPNHandlingMethod property have a valid value?
		Check 18 - Does the Service Principal table contain both types of SPN handling for a single credential?
		Check 19 - Is there a current UseExecutionBatches property available?
		Check 20 - Is there a current FrameworkFactoryResourceGroup property available?
		Check 21 - Is there a current PreviousPipelineRunsQueryRange property available?
		
		--Batch execution checks:
		Check 22 - If using batch executions, is the requested batch name enabled?
		Check 23 - If using batch executions, does the requested batch have links to execution stages?
		Check 24 - Have batch executions been enabled after a none batch execution run?

		Check 25 - Has the execution failed due to an invalid pipeline name? If so, attend to update this before the next run.
		Check 26 - Is there more than one framework orchestrator set?
		Check 27 - Has a framework orchestrator been set for any orchestrators?
		*/

		DECLARE @BatchId UNIQUEIDENTIFIER
		DECLARE @ErrorDetails VARCHAR(500)
		DECLARE @MetadataIntegrityIssues TABLE
			(
			[CheckNumber] INT NOT NULL,
			[IssuesFound] VARCHAR(MAX) NOT NULL
			)

		/*
		Checks:
		*/

		--Check 1:
		IF NOT EXISTS
			(
			SELECT 1 FROM [control].[Stages] WHERE [Enabled] = 1
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					1,
					''No execution stages are enabled within the metadatabase. Orchestrator has nothing to run.''
					)
			END;

		--Check 2:
		IF NOT EXISTS
			(
			SELECT 1 FROM [control].[Pipelines] WHERE [Enabled] = 1
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					2,
					''No execution pipelines are enabled within the metadatabase. Orchestrator has nothing to run.''
					)
			END;

		--Check 3:
		/*
		IF NOT EXISTS 
			(
			SELECT 1 FROM [dbo].[ServicePrincipals]
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					3,
					''No service principal details have been added to the metadata. Orchestrator cannot authorise pipeline executions.''
					)		
			END;
		*/

		--Check 4:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[Tenants]
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					4,
					''TenantId value is missing from the [control].[Tenants] table.''
					)		
			END;

		--Check 5:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[Subscriptions]
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					5,
					''SubscriptionId value is missing from the [control].[Subscriptions] table.''
					)		
			END;

		--Check 6:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''OverideRestart''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					6,
					''A current OverideRestart value is missing from the properties table.''
					)		
			END;

		--Check 7:
		/*
		IF EXISTS
			( 
			SELECT 
				* 
			FROM 
				[control].[Pipelines] p 
				LEFT OUTER JOIN [control].[PipelineAuthLink] al 
					ON p.[PipelineId] = al.[PipelineId]
			WHERE
				p.[Enabled] = 1
				AND al.[PipelineId] IS NULL
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					7,
					''Enabled pipelines are missing a valid Service Principal link.''
					)		
			END;
		*/

		--Check 8:
		IF EXISTS
			(
			SELECT * FROM [control].[Orchestrators] WHERE [SubscriptionId] = ''12345678-1234-1234-1234-012345678910''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					8,
					''Orchestrator still set to use the default subscription value of 12345678-1234-1234-1234-012345678910.''
					)		
			END;

		--Check 9:
		IF EXISTS
			(
			SELECT * FROM [control].[Subscriptions] WHERE [TenantId] = ''12345678-1234-1234-1234-012345678910'' AND [SubscriptionId] <> ''12345678-1234-1234-1234-012345678910''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					9,
					''None default subscription still set to use the default tenant value of 12345678-1234-1234-1234-012345678910.''
					)		
			END;

		--Check 10:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''PipelineStatusCheckDuration''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					10,
					''A current PipelineStatusCheckDuration value is missing from the properties table.''
					)		
			END;

		--Check 11:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''UseFrameworkEmailAlerting''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					11,
					''A current UseFrameworkEmailAlerting value is missing from the properties table.''
					)		
			END;

		--Check 12:
		IF (
			SELECT
				[PropertyValue]
			FROM
				[control].[CurrentProperties]
			WHERE
				[PropertyName] = ''UseFrameworkEmailAlerting''
			) = 1
			BEGIN
				IF NOT EXISTS
					(
					SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''EmailAlertBodyTemplate''
					)
					BEGIN
						INSERT INTO @MetadataIntegrityIssues
						VALUES
							( 
							12,
							''A current EmailAlertBodyTemplate value is missing from the properties table.''
							)		
					END;
			END;

		--Check 13:
		IF EXISTS
			(
			SELECT * FROM [control].[PipelineParameterDataSizes] WHERE [Size] > 9
			/*
			Azure Function request limit is 10MB.
			https://docs.microsoft.com/en-us/azure/azure-functions/functions-scale
			9MB to allow for other content in execute pipeline body request.
			*/
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					13,
					''The pipeline parameters entered exceed the Azure Function request body maximum of 10MB. Query view [control].[PipelineParameterDataSizes] for details.''
					)	
			END;

		--Check 14:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''FailureHandling''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					14,
					''A current FailureHandling value is missing from the properties table.''
					)		
			END;

		--Check 15:
		IF NOT EXISTS
			(
			SELECT 
				*
			FROM
				[control].[CurrentProperties] 
			WHERE 
				[PropertyName] = ''FailureHandling'' 
				AND [PropertyValue] IN (''None'',''Simple'',''DependencyChain'')
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					15,
					''The property FailureHandling does not have a supported value.''
					)	
			END;

		--Check 16:
		IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
		BEGIN
			IF EXISTS
			(
			SELECT 
				pd.[DependencyId]
			FROM 
				[control].[PipelineDependencies] pd
				INNER JOIN [control].[Pipelines] pp
					ON pd.[PipelineId] = pp.[PipelineId]
				INNER JOIN [control].[Pipelines] dp
					ON pd.[DependantPipelineId] = dp.[PipelineId]
			WHERE
				pp.[StageId] = dp.[StageId]
			)	
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					16,
					''A dependant pipeline and its upstream predecessor exist in the same execution stage. Fix this dependency chain to allow correct failure handling.''
					)	
			END;
		END;

		--Check 17:
		IF NOT EXISTS
			(
			SELECT 
				*
			FROM
				[control].[CurrentProperties] 
			WHERE 
				[PropertyName] = ''PipelineAuthenticationMethod'' 
				AND [PropertyValue] IN (''ManagedIdentity'',''ServicePrincipal'')
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					17,
					''The property SPNHandlingMethod does not have a supported value.''
					)	
			END;

		--Check 18:
		IF EXISTS
			(
			SELECT
				*
			FROM
				[dbo].[ServicePrincipals]
			WHERE
				(
				[PrincipalId] IS NOT NULL
				OR [PrincipalSecret] IS NOT NULL
				)
				AND 
				(
				[PrincipalIdUrl] IS NOT NULL
				OR [PrincipalSecretUrl] IS NOT NULL
				)
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					18,
					''The table [dbo].[ServicePrincipals] can only have one method of SPN details sorted per credential ID.''
					)	
			END;
		
		--Check 19:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''UseExecutionBatches''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					19,
					''A current UseExecutionBatches value is missing from the properties table.''
					)		
			END;

		--Check 20:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''FrameworkFactoryResourceGroup''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					20,
					''A current FrameworkFactoryResourceGroup value is missing from the properties table.''
					)		
			END;

		--Check 21:
		IF NOT EXISTS
			(
			SELECT * FROM [control].[CurrentProperties] WHERE [PropertyName] = ''PreviousPipelineRunsQueryRange''
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					21,
					''A current PreviousPipelineRunsQueryRange value is missing from the properties table.''
					)		
			END;

		--batch execution checks
		IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
			BEGIN			
				IF @BatchName IS NULL
					BEGIN
						RAISERROR(''A NULL batch name cannot be passed when the UseExecutionBatches property is set to 1 (true).'',16,1);
						RETURN 0;
					END

				SELECT 
					@BatchId = [BatchId]
				FROM
					[control].[Batches]
				WHERE
					[BatchName] = @BatchName;

				--Check 22:
				IF EXISTS
					(
					SELECT 1 FROM [control].[Batches] WHERE [BatchId] = @BatchId AND [Enabled] = 0
					)
					BEGIN
						INSERT INTO @MetadataIntegrityIssues
						VALUES
							( 
							22,
							''The requested execution batch is currently disabled. Enable the batch before proceeding.''
							)
					END;

				--Check 23:
				IF NOT EXISTS
					(
					SELECT 1 FROM [control].[BatchStageLink] WHERE [BatchId] = @BatchId
					)
					BEGIN
						INSERT INTO @MetadataIntegrityIssues
						VALUES
							( 
							23,
							''The requested execution batch does not have any linked execution stages. See table [control].[BatchStageLink] for details.''
							)
					END;

				--Check 24:
				IF EXISTS
					(
					SELECT
						*
					FROM
						[control].[CurrentExecution] c
						LEFT OUTER JOIN [control].[BatchExecution] b
							ON c.[LocalExecutionId] = b.[ExecutionId]
					WHERE
						b.[ExecutionId] IS NULL
					)
					BEGIN
						INSERT INTO @MetadataIntegrityIssues
						VALUES
							( 
							24,
							''Execution records exist in the [control].[CurrentExecution] table that do not have a record in [control].[BatchExecution] table. Has batch excutions been enabed after an incomplete none batch run?''
							)
					END;			
			END; --end batch checks
		
		--Check 25: 
		IF EXISTS
			(
			SELECT 1 FROM [control].[CurrentExecution] WHERE [PipelineStatus] = ''InvalidPipelineNameError''
			)
			BEGIN
				UPDATE
					ce
				SET
					ce.[PipelineName] = p.[PipelineName]
				FROM
					[control].[CurrentExecution] ce
					INNER JOIN [control].[Pipelines] p
						ON ce.[PipelineId] = p.[PipelineId]
							AND ce.[StageId] = p.[StageId]
				WHERE
					ce.[PipelineStatus] = ''InvalidPipelineNameError''
			END;
		
		--Check 26:
		IF (SELECT COUNT(0) FROM [control].[Orchestrators] WHERE [IsFrameworkOrchestrator] = 1) > 1
		BEGIN
			INSERT INTO @MetadataIntegrityIssues
			VALUES
				( 
				26,
				''There is more than one FrameworkOrchestrator set in the table [control].[Orchestrators]. Only one is supported.''
				)		
		END

		--Check 27:
		IF NOT EXISTS
			(
			SELECT 1 FROM [control].[Orchestrators] WHERE [IsFrameworkOrchestrator] = 1
			)
			BEGIN
				INSERT INTO @MetadataIntegrityIssues
				VALUES
					( 
					27,
					''A FrameworkOrchestrator has not been set in the table [control].[Orchestrators]. Only one is supported.''
					)		
			END

		/*
		Integrity Checks Outcome:
		*/
		
		--throw runtime error if checks fail
		IF EXISTS
			(
			SELECT * FROM @MetadataIntegrityIssues
			)
			AND @DebugMode = 0
			BEGIN
				SET @ErrorDetails = ''Metadata integrity checks failed. Run EXEC [control].[CheckMetadataIntegrity] @DebugMode = 1; for details.''

				RAISERROR(@ErrorDetails, 16, 1);
				RETURN 0;
			END;

		--report issues when in debug mode
		IF @DebugMode = 1
		BEGIN
			IF NOT EXISTS
				(
				SELECT * FROM @MetadataIntegrityIssues
				)
				BEGIN
					PRINT ''No data integrity issues found in metadata.''
					RETURN 0;
				END
			ELSE		
				BEGIN
					SELECT * FROM @MetadataIntegrityIssues;
				END;
		END;
	END;
	');

	PRINT N'Update complete for [common].[CheckMetadataIntegrity]';
END

--[control].[SetLogActivityFailed] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogActivityFailed] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogActivityFailed] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogActivityFailed]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogActivityFailed] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogActivityFailed]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogActivityFailed]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@CallingActivity VARCHAR(255)
		)
	AS

	BEGIN
		SET NOCOUNT ON;
		
		--mark specific failure pipeline
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = @CallingActivity + ''Error''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId

		--persist failed pipeline records to long term log
		INSERT INTO [control].[ExecutionLog]
			(
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
			)
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
		FROM
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [PipelineStatus] = @CallingActivity + ''Error''
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
		
		--decide how to proceed with error/failure depending on framework property configuration
		IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''None''
			BEGIN
				--do nothing allow processing to carry on regardless
				RETURN 0;
			END;
			
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''Simple''
			BEGIN
				--flag all downstream stages as blocked
				UPDATE
					[control].[CurrentExecution]
				SET
					[PipelineStatus] = ''Blocked'',
					[IsBlocked] = 1
				WHERE
					[LocalExecutionId] = @ExecutionId
					AND [StageId] > @StageId;

				--update batch if applicable
				IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
					BEGIN
						UPDATE
							[control].[BatchExecution]
						SET
							[BatchStatus] = ''Stopping'' --special case when its an activity failure to call stop ready for restart
						WHERE
							[ExecutionId] = @ExecutionId
							AND [BatchStatus] = ''Running'';
					END;			
			END;
		
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
			BEGIN
				EXEC [control].[SetExecutionBlockDependants]
					@ExecutionId = @ExecutionId,
					@PipelineId = @PipelineId
			END;
		ELSE
			BEGIN
				RAISERROR(''Unknown failure handling state.'',16,1);
				RETURN 0;
			END;
	END;
	');

	PRINT N'Update complete for [common].[SetLogActivityFailed]';
END

--[control].[SetLogPipelineUnknown] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineUnknown] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineUnknown] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineUnknown]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineUnknown] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineUnknown]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineUnknown]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@CleanUpRun BIT = 0
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorDetail VARCHAR(500);

		--mark specific failure pipeline
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Unknown''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId

		--no need to block and log if done during a clean up cycle
		IF @CleanUpRun = 1 RETURN 0;

		--persist unknown pipeline records to long term log
		INSERT INTO [control].[ExecutionLog]
			(
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
			)
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
		FROM
			[control].[CurrentExecution]
		WHERE
			[PipelineStatus] = ''Unknown''
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;

		--block down stream stages?
		IF ([control].[GetPropertyValueInternal](''UnknownWorkerResultBlocks'')) = 1
		BEGIN	
			--decide how to proceed with error/failure depending on framework property configuration
			IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''None''
				BEGIN
					--do nothing allow processing to carry on regardless
					RETURN 0;
				END;
			
			ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''Simple''
				BEGIN
					--flag all downstream stages as blocked
					UPDATE
						[control].[CurrentExecution]
					SET
						[PipelineStatus] = ''Blocked'',
						[IsBlocked] = 1
					WHERE
						[LocalExecutionId] = @ExecutionId
						AND [StageId] > @StageId

					UPDATE
						[control].[BatchExecution]
					SET
						[BatchStatus] = ''Stopping''
					WHERE
						[ExecutionId] = @ExecutionId
						AND [BatchStatus] = ''Running'';

					SET @ErrorDetail = ''Pipeline execution has an unknown status. Blocking downstream stages as a precaution.''

					RAISERROR(@ErrorDetail,16,1);
					RETURN 0;
				END;
			ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
				BEGIN
					EXEC [control].[SetExecutionBlockDependants]
						@ExecutionId = @ExecutionId,
						@PipelineId = @PipelineId
				END;
			ELSE
				BEGIN
					RAISERROR(''Unknown failure handling state.'',16,1);
					RETURN 0;
				END;
		END;
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineUnknown]';
END

--[control].[GetWorkerPipelineDetailsv2] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetWorkerPipelineDetailsv2] Stored Procedure -----';

	PRINT N'Creating [control].[GetWorkerPipelineDetailsv2] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetWorkerPipelineDetailsv2]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetWorkerPipelineDetailsv2] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetWorkerPipelineDetailsv2]';
	EXEC('
	ALTER PROCEDURE [control].[GetWorkerPipelineDetailsv2]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		SELECT
			orch.[SubscriptionId],
			ce.[PipelineName],
			ce.[OrchestratorName],
			ce.[OrchestratorType],
			ce.[ResourceGroupName]
		FROM 
			[control].[CurrentExecution] ce
			INNER JOIN [control].[Pipelines] p
				ON p.[PipelineId] = ce.[PipelineId]
			INNER JOIN [control].[Orchestrators] orch
				ON orch.[OrchestratorId] = p.[OrchestratorId]
		WHERE 
			ce.[LocalExecutionId] = @ExecutionId
			AND ce.[StageId] = @StageId
			AND ce.[PipelineId] = @PipelineId;
	END;
	');

	PRINT N'Update complete for [common].[GetWorkerPipelineDetailsv2]';
END

--[control].[AddProperty] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[AddProperty] Stored Procedure -----';

	PRINT N'Creating [control].[AddProperty] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[AddProperty]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[AddProperty] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[AddProperty]';
	EXEC('
	ALTER PROCEDURE [control].[AddProperty]
		(
		@PropertyName VARCHAR(128),
		@PropertyValue NVARCHAR(MAX),
		@Description NVARCHAR(MAX) = NULL
		)
	AS
	BEGIN
		
		SET NOCOUNT ON;

		--defensive check
		IF EXISTS
			(
			SELECT * FROM [control].[Properties] WHERE [PropertyName] = @PropertyName AND [ValidTo] IS NOT NULL
			)
			AND NOT EXISTS
			(
			SELECT * FROM [control].[Properties] WHERE [PropertyName] = @PropertyName AND [ValidTo] IS NULL
			)
			BEGIN
				WITH lastValue AS
					(
					SELECT
						[PropertyId],
						ROW_NUMBER() OVER (PARTITION BY [PropertyName] ORDER BY [ValidTo] ASC) AS Rn
					FROM
						[control].[Properties]
					WHERE
						[PropertyName] = @PropertyName
					)
				--reset property if valid to date has been incorrectly set
				UPDATE
					prop
				SET
					[ValidTo] = NULL
				FROM
					[control].[Properties] prop
					INNER JOIN lastValue
						ON prop.[PropertyId] = lastValue.[PropertyId]
				WHERE
					lastValue.[Rn] = 1
			END
		

		--upsert property
		;WITH sourceTable AS
			(
			SELECT
				@PropertyName AS PropertyName,
				@PropertyValue AS PropertyValue,
				@Description AS [Description],
				GETUTCDATE() AS StartEndDate
			)
		--insert new version of existing property from MERGE OUTPUT
		INSERT INTO [control].[Properties]
			(
			[PropertyName],
			[PropertyValue],
			[Description],
			[ValidFrom]
			)
		SELECT
			[PropertyName],
			[PropertyValue],
			[Description],
			GETUTCDATE()
		FROM
			(
			MERGE INTO
				[control].[Properties] targetTable
			USING
				sourceTable
					ON sourceTable.[PropertyName] = targetTable.[PropertyName]	
			--set valid to date on existing property
			WHEN MATCHED AND [ValidTo] IS NULL THEN 
				UPDATE
				SET
					targetTable.[ValidTo] = sourceTable.[StartEndDate]
			--add new property
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
					(
					[PropertyName],
					[PropertyValue],
					[Description],
					[ValidFrom]
					)
				VALUES
					(
					sourceTable.[PropertyName],
					sourceTable.[PropertyValue],
					sourceTable.[Description],
					sourceTable.[StartEndDate]
					)
				--for new entry of existing record
				OUTPUT
					$action AS [Action],
					sourceTable.*
				) AS MergeOutput
			WHERE
				MergeOutput.[Action] = ''UPDATE'';
	END;
	');

	PRINT N'Update complete for [common].[AddProperty]';
END

--[control].[GetFrameworkOrchestratorDetails] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetFrameworkOrchestratorDetails] Stored Procedure -----';

	PRINT N'Creating [control].[GetFrameworkOrchestratorDetails] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetFrameworkOrchestratorDetails]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetFrameworkOrchestratorDetails] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetFrameworkOrchestratorDetails]';
	EXEC('
	ALTER PROCEDURE [control].[GetFrameworkOrchestratorDetails]
		(
		@CallingOrchestratorName NVARCHAR(200)
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @FrameworkOrchestrator NVARCHAR(200)

		--defensive check
		SELECT
			@FrameworkOrchestrator = UPPER([OrchestratorName]),
			@CallingOrchestratorName = UPPER(@CallingOrchestratorName)
		FROM
			[control].[Orchestrators]
		WHERE
			[IsFrameworkOrchestrator] = 1;

		IF(@FrameworkOrchestrator <> @CallingOrchestratorName)
		BEGIN
			RAISERROR(''Orchestrator mismatch. Calling orchestrator does not match expected IsFrameworkOrchestrator name.'',16,1);
			RETURN 0;
		END

		--orchestrator detials
		SELECT
			[SubscriptionId],
			[ResourceGroupName],
			[OrchestratorName],
			[OrchestratorType]
		FROM
			[control].[Orchestrators]
		WHERE
			[IsFrameworkOrchestrator] = 1;
	END;
	');

	PRINT N'Update complete for [common].[GetFrameworkOrchestratorDetails]';
END

--[control].[GetWorkerDetailsWrapper] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[GetWorkerDetailsWrapper] Stored Procedure -----';

	PRINT N'Creating [control].[GetWorkerDetailsWrapper] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[GetWorkerDetailsWrapper]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[GetWorkerDetailsWrapper] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[GetWorkerDetailsWrapper]';
	EXEC('
	ALTER PROCEDURE [control].[GetWorkerDetailsWrapper]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		/*
		Created this proc just to reduce and refactor the number of pipeline activity 
		calls needed due to the Microsoft enforced limit of 40 activities per pipeline.
		*/
		SET NOCOUNT ON;

		DECLARE @WorkerAuthDetails TABLE
			(
			[tenantId] UNIQUEIDENTIFIER NULL,
			[applicationId] NVARCHAR(MAX) NULL,
			[authenticationKey] NVARCHAR(MAX) NULL,
			[subscriptionId] UNIQUEIDENTIFIER NULL
			)

		DECLARE @WorkerDetails TABLE
			(
			[resourceGroupName] NVARCHAR(200) NULL,
			[orchestratorName] NVARCHAR(200) NULL,
			[orchestratorType] CHAR(3) NULL,
			[pipelineName] NVARCHAR(200) NULL
			)

		--get work auth details
		INSERT INTO @WorkerAuthDetails
			(
			[tenantId],
			[subscriptionId],
			[applicationId],
			[authenticationKey]
			)
		EXEC [control].[GetWorkerAuthDetails]
			@ExecutionId = @ExecutionId,
			@StageId = @StageId,
			@PipelineId = @PipelineId;
		
		--get main worker details
		INSERT INTO @WorkerDetails
			(
			[pipelineName],
			[orchestratorName],
			[orchestratorType],
			[resourceGroupName]
			)
		EXEC [control].[GetWorkerPipelineDetails]
			@ExecutionId = @ExecutionId,
			@StageId = @StageId,
			@PipelineId = @PipelineId;		
		
		--return all details
		SELECT  
			ad.[tenantId],
			ad.[applicationId],
			ad.[authenticationKey],		
			ad.[subscriptionId],
			d.[resourceGroupName],
			d.[orchestratorName],
			d.[orchestratorType],
			d.[pipelineName]
		FROM 
			@WorkerDetails d 
			CROSS JOIN @WorkerAuthDetails ad;
	END;
	');

	PRINT N'Update complete for [common].[GetWorkerDetailsWrapper]';
END

--[control].[SetLogPipelineValidating] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineValidating] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineValidating] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineValidating]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineValidating] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineValidating]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineValidating]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Validating''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineValidating]';
END

--[control].[CheckPreviousExeuction] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[CheckPreviousExeuction] Stored Procedure -----';

	PRINT N'Creating [control].[CheckPreviousExeuction] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[CheckPreviousExeuction]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[CheckPreviousExeuction] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[CheckPreviousExeuction]';
	EXEC('
	ALTER PROCEDURE [control].[CheckPreviousExeuction]
		(
		@BatchName VARCHAR(255) = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;
		/*
		Check A: - Are there any Running pipelines that need to be cleaned up?
		*/

		DECLARE @BatchId UNIQUEIDENTIFIER
		DECLARE @LocalExecutionId UNIQUEIDENTIFIER

		--Check A:
		IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''0''
			BEGIN
				IF EXISTS
					(
					SELECT 
						1 
					FROM 
						[control].[CurrentExecution] 
					WHERE 
						[PipelineStatus] NOT IN (''Success'',''Failed'',''Blocked'', ''Cancelled'') 
						AND [PipelineRunId] IS NOT NULL
					)
					BEGIN
						--return pipelines details that require a clean up
						SELECT 
							[ResourceGroupName],
							[OrchestratorType],
							[OrchestratorName],
							[PipelineName],
							[PipelineRunId],
							[LocalExecutionId],
							[StageId],
							[PipelineId]
						FROM 
							[control].[CurrentExecution]
						WHERE 
							[PipelineStatus] NOT IN (''Success'',''Failed'',''Blocked'',''Cancelled'') 
							AND [PipelineRunId] IS NOT NULL
					END;
				ELSE
					GOTO LookUpReturnEmptyResult;
			END
		ELSE IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
			BEGIN
				IF @BatchName IS NULL
					BEGIN
						RAISERROR(''A NULL batch name cannot be passed when the UseExecutionBatches property is set to 1 (true).'',16,1);
						RETURN 0;
					END
				
				IF EXISTS
					(
					SELECT 
						1 
					FROM 
						[control].[CurrentExecution] ce
						INNER JOIN [control].[BatchExecution] be
							ON ce.[LocalExecutionId] = be.[ExecutionId]
						INNER JOIN [control].[Batches] b
							ON be.[BatchId] = b.[BatchId]
					WHERE 
						b.[BatchName] = @BatchName
						AND ce.[PipelineStatus] NOT IN (''Success'',''Failed'',''Blocked'',''Cancelled'') 
						AND ce.[PipelineRunId] IS NOT NULL
					)
					BEGIN
						--return pipelines details that require a clean up
						SELECT 
							ce.[ResourceGroupName],
							ce.[OrchestratorType],
							ce.[OrchestratorName],
							ce.[PipelineName],
							ce.[PipelineRunId],
							ce.[LocalExecutionId],
							ce.[StageId],
							ce.[PipelineId]
						FROM 
							[control].[CurrentExecution] ce
							INNER JOIN [control].[BatchExecution] be
								ON ce.[LocalExecutionId] = be.[ExecutionId]
							INNER JOIN [control].[Batches] b
								ON be.[BatchId] = b.[BatchId]
						WHERE 
							b.[BatchName] = @BatchName
							AND ce.[PipelineStatus] NOT IN (''Success'',''Failed'',''Blocked'',''Cancelled'') 
							AND ce.[PipelineRunId] IS NOT NULL
					END;
				ELSE
					GOTO LookUpReturnEmptyResult;
			END
		
		LookUpReturnEmptyResult:
		--lookup activity must return something, even if just an empty dataset
		SELECT 
			NULL AS ResourceGroupName,
			NULL AS OrchestratorType,
			NULL AS OrchestratorName,
			NULL AS PipelineName,
			NULL AS PipelineRunId,
			NULL AS LocalExecutionId,
			NULL AS StageId,
			NULL AS PipelineId
		FROM
			[control].[CurrentExecution]
		WHERE
			1 = 2; --ensure no results
	END;
	');

	PRINT N'Update complete for [common].[CheckPreviousExeuction]';
END

--[control].[BatchWrapper] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[BatchWrapper] Stored Procedure -----';

	PRINT N'Creating [control].[BatchWrapper] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[BatchWrapper]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[BatchWrapper] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[BatchWrapper]';
	EXEC('
	ALTER PROCEDURE [control].[BatchWrapper]
		(
		@BatchId UNIQUEIDENTIFIER,
		@LocalExecutionId UNIQUEIDENTIFIER OUTPUT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @RestartStatus BIT

		--get restart overide property	
		SELECT @RestartStatus = [control].[GetPropertyValueInternal](''OverideRestart'')

		--check for running batch execution
		IF EXISTS
			(
			SELECT 1 FROM [control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'''') = ''Running''
			)
			BEGIN
				SELECT
					@LocalExecutionId = [ExecutionId]
				FROM
					[control].[BatchExecution]
				WHERE
					[BatchId] = @BatchId;
				
				--should never actually be called as handled within Orchestrator pipelines using the Pipeline Run Check utility
				RAISERROR(''There is already an batch execution run in progress. Stop the related parent pipeline via the Orchestrator first.'',16,1);
				RETURN 0;
			END
		ELSE IF EXISTS
			(
			SELECT 1 FROM [control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'''') = ''Stopped''
			)
			AND @RestartStatus = 0
			BEGIN
				SELECT
					@LocalExecutionId = [ExecutionId]
				FROM
					[control].[BatchExecution]
				WHERE
					[BatchId] = @BatchId
					AND ISNULL([BatchStatus],'''') = ''Stopped'';

				RETURN 0;
			END
		ELSE IF EXISTS
			(
			SELECT 1 FROM [control].[BatchExecution] WHERE [BatchId] = @BatchId AND ISNULL([BatchStatus],'''') = ''Stopped''
			)
			AND @RestartStatus = 1
			BEGIN
				--clean up current execution table and abandon batch
				SELECT
					@LocalExecutionId = [ExecutionId]
				FROM
					[control].[BatchExecution]
				WHERE
					[BatchId] = @BatchId
					AND ISNULL([BatchStatus],'''') = ''Stopped'';
				
				EXEC [control].[UpdateExecutionLog]
					@PerformErrorCheck = 0, --Special case when OverideRestart = 1;
					@ExecutionId = @LocalExecutionId;
				
				--abandon previous batch execution
				UPDATE
					[control].[BatchExecution]
				SET
					[BatchStatus] = ''Abandoned''
				WHERE
					[BatchId] = @BatchId 
					AND ISNULL([BatchStatus],'''') = ''Stopped'';
		
				SET @LocalExecutionId = NEWID();

				--create new batch run record
				INSERT INTO [control].[BatchExecution]
					(
					[BatchId],
					[ExecutionId],
					[BatchName],
					[BatchStatus],
					[StartDateTime]
					)
				SELECT
					[BatchId],
					@LocalExecutionId,
					[BatchName],
					''Running'',
					GETUTCDATE()
				FROM
					[control].[Batches]
				WHERE
					[BatchId] = @BatchId;			
			END
		ELSE
			BEGIN
				SET @LocalExecutionId = NEWID();

				--create new batch run record
				INSERT INTO [control].[BatchExecution]
					(
					[BatchId],
					[ExecutionId],
					[BatchName],
					[BatchStatus],
					[StartDateTime]
					)
				SELECT
					[BatchId],
					@LocalExecutionId,
					[BatchName],
					''Running'',
					GETUTCDATE()
				FROM
					[control].[Batches]
				WHERE
					[BatchId] = @BatchId;
			END;
	END;
	');

	PRINT N'Update complete for [common].[BatchWrapper]';
END

--[control].[ExecutionWrapper] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[ExecutionWrapper] Stored Procedure -----';

	PRINT N'Creating [control].[ExecutionWrapper] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[ExecutionWrapper]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[ExecutionWrapper] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[ExecutionWrapper]';
	EXEC('
	ALTER PROCEDURE [control].[ExecutionWrapper]
		(
		@CallingOrchestratorName NVARCHAR(200) = NULL,
		@BatchName VARCHAR(255) = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @RestartStatus BIT
		DECLARE @BatchId UNIQUEIDENTIFIER
		DECLARE @BLocalExecutionId UNIQUEIDENTIFIER --declared here for batches

		IF @CallingOrchestratorName IS NULL
			SET @CallingOrchestratorName = ''Unknown'';

		--get restart overide property	
		SELECT @RestartStatus = [control].[GetPropertyValueInternal](''OverideRestart'')

		IF([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''0''
			BEGIN
				SET @BatchId = NULL;

				--check for running execution
				IF EXISTS
					(
					SELECT * FROM [control].[CurrentExecution] WHERE ISNULL([PipelineStatus],'''') = ''Running''
					)
					BEGIN
						RAISERROR(''There is already an execution run in progress. Stop this via the Orchestrator before restarting.'',16,1);
						RETURN 0;
					END;	

				--reset and restart execution
				IF EXISTS
					(
					SELECT 1 FROM [control].[CurrentExecution] WHERE ISNULL([PipelineStatus],'''') <> ''Success''
					) 
					AND @RestartStatus = 0
					BEGIN
						EXEC [control].[ResetExecution]
					END
				--capture failed execution and run new anyway
				ELSE IF EXISTS
					(
					SELECT 1 FROM [control].[CurrentExecution]
					)
					AND @RestartStatus = 1
					BEGIN
						EXEC [control].[UpdateExecutionLog]
							@PerformErrorCheck = 0; --Special case when OverideRestart = 1;

						EXEC [control].[CreateNewExecution] 
							@CallingOrchestratorName = @CallingOrchestratorName
					END
				--no restart considerations, just create new execution
				ELSE
					BEGIN
						EXEC [control].[CreateNewExecution] 
							@CallingOrchestratorName = @CallingOrchestratorName
					END
			END
		ELSE IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
			BEGIN						
				IF @BatchName IS NULL
					BEGIN
						RAISERROR(''A NULL batch name cannot be passed when the UseExecutionBatches property is set to 1 (true).'',16,1);
						RETURN 0;
					END;
				
				SELECT 
					@BatchId = [BatchId]
				FROM
					[control].[Batches]
				WHERE
					[BatchName] = @BatchName;
				
				--create local execution id now for the batch
				EXEC [control].[BatchWrapper]
					@BatchId = @BatchId,
					@LocalExecutionId = @BLocalExecutionId OUTPUT;
					
				--reset and restart execution
				IF EXISTS
					(
					SELECT 1 
					FROM 
						[control].[CurrentExecution] 
					WHERE 
						[LocalExecutionId] = @BLocalExecutionId 
						AND ISNULL([PipelineStatus],'''') <> ''Success''
					) 
					AND @RestartStatus = 0
					BEGIN
						EXEC [control].[ResetExecution]
							@LocalExecutionId = @BLocalExecutionId;
					END
				--capture failed execution and run new anyway
				ELSE IF EXISTS
					(
					SELECT 1 
					FROM 
						[control].[CurrentExecution]
					WHERE
						[LocalExecutionId] = @BLocalExecutionId 
					)
					AND @RestartStatus = 1
					BEGIN
						EXEC [control].[UpdateExecutionLog]
							@PerformErrorCheck = 0, --Special case when OverideRestart = 1;
							@ExecutionId = @BLocalExecutionId;

						EXEC [control].[CreateNewExecution]
							@CallingOrchestratorName = @CallingOrchestratorName,
							@LocalExecutionId = @BLocalExecutionId;
					END
				--no restart considerations, just create new execution
				ELSE
					BEGIN
						EXEC [control].[CreateNewExecution] 
							@CallingOrchestratorName = @CallingOrchestratorName,
							@LocalExecutionId = @BLocalExecutionId;
					END
				
			END
		ELSE
			BEGIN
				--metadata integrity checks should mean this condition is never hit
				RAISERROR(''Unknown batch handling configuration. Update properties with UseExecutionBatches value and try again.'',16,1);
				RETURN 0;
			END
	END;
	');

	PRINT N'Update complete for [common].[ExecutionWrapper]';
END

--[control].[SetLogPipelineFailed] 
BEGIN

	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineFailed] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineFailed] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineFailed]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineFailed] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineFailed]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineFailed]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@RunId UNIQUEIDENTIFIER = NULL
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorDetail VARCHAR(500)

		--mark specific failure pipeline
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Failed''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId

		--persist failed pipeline records to long term log
		INSERT INTO [control].[ExecutionLog]
			(
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
			)
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
		FROM
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [PipelineStatus] = ''Failed''
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;
		
		IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''None''
			BEGIN
				--do nothing allow processing to carry on regardless
				RETURN 0;
			END;
			
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''Simple''
			BEGIN
				--flag all downstream stages as blocked
				UPDATE
					[control].[CurrentExecution]
				SET
					[PipelineStatus] = ''Blocked'',
					[IsBlocked] = 1
				WHERE
					[LocalExecutionId] = @ExecutionId
					AND [StageId] > @StageId
				
				--raise error to stop processing
				IF @RunId IS NOT NULL
					BEGIN
						SET @ErrorDetail = ''Pipeline execution failed. Check Run ID: '' + CAST(@RunId AS CHAR(36)) + '' in ADF monitoring for details.''
					END;
				ELSE
					BEGIN
						SET @ErrorDetail = ''Pipeline execution failed. See ADF monitoring for details.''
					END;

				--update batch if applicable
				IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
					BEGIN
						UPDATE
							[control].[BatchExecution]
						SET
							[BatchStatus] = ''Stopping''
						WHERE
							[ExecutionId] = @ExecutionId
							AND [BatchStatus] = ''Running'';
					END;

				RAISERROR(@ErrorDetail,16,1);
				RETURN 0;
			END;
		
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
			BEGIN
				EXEC [control].[SetExecutionBlockDependants]
					@ExecutionId = @ExecutionId,
					@PipelineId = @PipelineId
			END;
		ELSE
			BEGIN
				RAISERROR(''Unknown failure handling state.'',16,1);
				RETURN 0;
			END;
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineFailed]';
END

--[control].[SetLogPipelineCancelled] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[SetLogPipelineCancelled] Stored Procedure -----';

	PRINT N'Creating [control].[SetLogPipelineCancelled] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[SetLogPipelineCancelled]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[SetLogPipelineCancelled] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[SetLogPipelineCancelled]';
	EXEC('
	ALTER PROCEDURE [control].[SetLogPipelineCancelled]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT,
		@PipelineId INT,
		@CleanUpRun BIT = 0
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorDetail VARCHAR(500);

		--mark specific failure pipeline
		UPDATE
			[control].[CurrentExecution]
		SET
			[PipelineStatus] = ''Cancelled''
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId
		
		--no need to block and log if done during a clean up cycle
		IF @CleanUpRun = 1 RETURN 0;

		--persist cancelled pipeline records to long term log
		INSERT INTO [control].[ExecutionLog]
			(
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
			)
		SELECT
			[LocalExecutionId],
			[StageId],
			[PipelineId],
			[CallingOrchestratorName],
			[ResourceGroupName],
			[OrchestratorType],
			[OrchestratorName],
			[PipelineName],
			[StartDateTime],
			[PipelineStatus],
			[EndDateTime],
			[PipelineRunId],
			[PipelineParamsUsed]
		FROM
			[control].[CurrentExecution]
		WHERE
			[LocalExecutionId] = @ExecutionId
			AND [PipelineStatus] = ''Cancelled''
			AND [StageId] = @StageId
			AND [PipelineId] = @PipelineId;

		--block down stream stages?
		IF ([control].[GetPropertyValueInternal](''CancelledWorkerResultBlocks'')) = 1
		BEGIN	
			--decide how to proceed with error/failure depending on framework property configuration
			IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''None''
				BEGIN
					--do nothing allow processing to carry on regardless
					RETURN 0;
				END;

			ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''Simple''
				BEGIN
					--flag all downstream stages as blocked
					UPDATE
						[control].[CurrentExecution]
					SET
						[PipelineStatus] = ''Blocked'',
						[IsBlocked] = 1
					WHERE
						[LocalExecutionId] = @ExecutionId
						AND [StageId] > @StageId
					
					--update batch if applicable
					IF ([control].[GetPropertyValueInternal](''UseExecutionBatches'')) = ''1''
						BEGIN
							UPDATE
								[control].[BatchExecution]
							SET
								[BatchStatus] = ''Stopping''
							WHERE
								[ExecutionId] = @ExecutionId
								AND [BatchStatus] = ''Running'';
						END;

					SET @ErrorDetail = ''Pipeline execution has a cancelled status. Blocking downstream stages as a precaution.''

					RAISERROR(@ErrorDetail,16,1);
					RETURN 0;
				END;
			ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
				BEGIN
					EXEC [control].[SetExecutionBlockDependants]
						@ExecutionId = @ExecutionId,
						@PipelineId = @PipelineId
				END;
			ELSE
				BEGIN
					RAISERROR(''Cancelled execution failure handling state.'',16,1);
					RETURN 0;
				END;
		END;
	END;
	');

	PRINT N'Update complete for [common].[SetLogPipelineCancelled]';
END

--[control].[CheckForBlockedPipelines] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [control].[CheckForBlockedPipelines] Stored Procedure -----';

	PRINT N'Creating [control].[CheckForBlockedPipelines] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[control].[CheckForBlockedPipelines]'))
	BEGIN
		EXEC('CREATE PROCEDURE [control].[CheckForBlockedPipelines] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [control].[CheckForBlockedPipelines]';
	EXEC('
	ALTER PROCEDURE [control].[CheckForBlockedPipelines]
		(
		@ExecutionId UNIQUEIDENTIFIER,
		@StageId INT
		)
	AS
	BEGIN
		SET NOCOUNT ON;

		-- If any pipelines still have a status of running, mark as failed to block downstream processing, and add an error log
		IF EXISTS
			(
			SELECT 
				*
			FROM 
				[control].[CurrentExecution]
			WHERE 
				[LocalExecutionId] = @ExecutionId
				AND [StageId] < @StageId
				AND [PipelineStatus] = ''Running''
			)
			BEGIN		
				DECLARE @RunningPipelineId INT;
				DECLARE @RunningPipelineStageId INT;
				DECLARE @RunId UNIQUEIDENTIFIER;
				DECLARE @ErrorJson NVARCHAR(MAX);
				DECLARE @RunningCursor CURSOR ;

				SET @RunningCursor = CURSOR FOR 
												SELECT 
													[PipelineId],
													[StageId],
													[PipelineRunId]
												FROM 
													[control].[CurrentExecution] 
												WHERE 
													[LocalExecutionId] = @ExecutionId
													AND [StageId] < @StageId
													AND [PipelineStatus] = ''Running''

				OPEN @RunningCursor
				FETCH NEXT FROM @RunningCursor INTO @RunningPipelineId, @RunningPipelineStageId, @RunId
						
				WHILE @@FETCH_STATUS = 0
				BEGIN 
					EXEC [control].SetLogPipelineFailed 
						@ExecutionId = @ExecutionId,
						@StageId = @RunningPipelineStageId,
						@PipelineId = @RunningPipelineId,
						@RunId = @RunId;

					SET @ErrorJson = ''{ "RunId": "'' + Cast(@RunId AS CHAR(36)) + ''", "Errors": [ { "ActivityRunId": "00000000-0000-0000-0000-000000000000", "ActivityName": "Set Pipeline Result", "ActivityType": "Switch", "ErrorCode": "Unknown", "ErrorType": "Framework Error", "ErrorMessage": "Framework pipeline ''''04-Infant'''' failed to set the pipeline result, most likely due to a timeout or azure connectivity issue. Check the framework Data Factory monitor for more information." } ] }''
					EXEC [control].[SetErrorLogDetails] 
						@LocalExecutionId = @ExecutionId,
						@JsonErrorDetails = @ErrorJson;
							
					FETCH NEXT FROM @RunningCursor INTO @RunningPipelineId, @RunningPipelineStageId, @RunId;
				END;
				CLOSE @RunningCursor;
				DEALLOCATE @RunningCursor;
			END;


		IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''None''
			BEGIN
				--do nothing allow processing to carry on regardless
				RETURN 0;
			END;
			
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''Simple''
			BEGIN
				IF EXISTS
					(
					SELECT 
						*
					FROM 
						[control].[CurrentExecution]
					WHERE 
						[LocalExecutionId] = @ExecutionId
						AND [StageId] = @StageId
						AND [IsBlocked] = 1
					)
					BEGIN		
						UPDATE
							[control].[BatchExecution]
						SET
							[EndDateTime] = GETUTCDATE(),
							[BatchStatus] = ''Stopped''
						WHERE
							[ExecutionId] = @ExecutionId;
						
						--Saves the infant pipeline and activities being called throwing the exception at this level.
						RAISERROR(''All pipelines are blocked. Stopping processing.'',16,1); 
						--If not thrown here, the proc [control].[UpdateExecutionLog] would eventually throw an exception.
						RETURN 0;
					END			
			END;
		
		ELSE IF ([control].[GetPropertyValueInternal](''FailureHandling'')) = ''DependencyChain''
			BEGIN
				IF EXISTS
					(
					SELECT 
						*
					FROM 
						[control].[CurrentExecution]
					WHERE 
						[LocalExecutionId] = @ExecutionId
						AND [StageId] = @StageId
						AND [IsBlocked] = 1
					)
					BEGIN		
						DECLARE @PipelineId INT;
						DECLARE @Cursor CURSOR ;

						SET @Cursor = CURSOR FOR 
												SELECT 
													[PipelineId] 
												FROM 
													[control].[CurrentExecution] 
												WHERE 
													[LocalExecutionId] = @ExecutionId
													AND [StageId] = @StageId 
													AND [IsBlocked] = 1

						OPEN @Cursor
						FETCH NEXT FROM @Cursor INTO @PipelineId
						
						WHILE @@FETCH_STATUS = 0
						BEGIN 
							EXEC [control].[SetExecutionBlockDependants]
								@ExecutionId = @ExecutionId,
								@PipelineId = @PipelineId;
							
							FETCH NEXT FROM @Cursor INTO @PipelineId;
						END;
						CLOSE @Cursor;
						DEALLOCATE @Cursor;
					END;
			END;
		ELSE
			BEGIN
				RAISERROR(''Unknown failure handling state.'',16,1);
				RETURN 0;
			END;
	END;
	');

	PRINT N'Update complete for [common].[CheckForBlockedPipelines]';
END


END

PRINT N'------------- Migration for [control] schema objects complete -------------';
END

PRINT N''
IF @MigrateIngest = 1
BEGIN
PRINT N'----------------------- Migrate [ingest] schema -----------------------';
/*
Migrate Schema
*/
BEGIN
	IF NOT EXISTS (
		SELECT * 
		FROM sys.schemas
		WHERE name = 'ingest' 
		)
	BEGIN
		PRINT N'Schema [ingest] does not exist. Creating...'
		EXEC ('CREATE SCHEMA [ingest]');
		PRINT N'Schema [ingest] has been created'

	END
END
/*
Migrate Tables
		[ingest].[APITokens] (Table)
		[ingest].[Attributes] (Table)
		[ingest].[Datasets] (Table)
		[ingest].[AuditAttributes] (Table)
*/
BEGIN
-- [ingest].[APITokens]
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [ingest].[APITokens] -----';
	PRINT N'Checking for existing table [ingest].[APITokens]...';

	-- Migration Case 1: ingest.APITokens already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'APITokens')
	
	BEGIN
		PRINT N'Table [ingest].[APITokens] exists, creating a copy';
		EXEC sp_rename 'ingest.APITokens', 'APITokens_Migration';
		--ALTER TABLE ingest.APITokensMigration ADD ResourceName AS (AzureResourceName);  
	END

	PRINT N'Creating new table [ingest].[APITokens]...';

	CREATE TABLE [ingest].[APITokens] (
		[APITokenId]                  INT            IDENTITY (1, 1) NOT NULL,
		[ConnectionFK]                INT            NULL,
		[IdentityToken]               NVARCHAR (MAX) NULL,
		[IdentityTokenExpiryDateTime] DATETIME2 (7)  NULL,
		[RefreshToken]                NVARCHAR (MAX) NULL,
		[RefreshTokenExpiryDateTime]  DATETIME2 (7)  NULL,
		PRIMARY KEY CLUSTERED ([APITokenId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [ingest].[APITokens] created';
	PRINT N'Migrating data to new table [ingest].[APITokens]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'APITokens_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [ingest].[APITokens_Migration])
		BEGIN
			SET IDENTITY_INSERT [ingest].[APITokens] ON;
			INSERT INTO [ingest].[APITokens] ([APITokenId],[ConnectionFK],[IdentityToken],[IdentityTokenExpiryDateTime],[RefreshToken],[RefreshTokenExpiryDateTime])
			SELECT  
				[APITokenId],
				[ConnectionFK],
				[IdentityToken],
				[IdentityTokenExpiryDateTime],
				[RefreshToken],
				[RefreshTokenExpiryDateTime]
			FROM     [ingest].[APITokens_Migration]
			ORDER BY [APITokenId] ASC;
			SET IDENTITY_INSERT [ingest].[APITokens] OFF;
		END
	END

	PRINT N'Migrated data to new table [ingest].[APITokens]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [ingest].[APITokens_Migration];
	END

-- [ingest].[Attributes]
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [ingest].[Attributes] -----';
	PRINT N'Checking for existing table [ingest].[Attributes]...';

	-- Migration Case 1: ingest.Attributes already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'Attributes')
	
	BEGIN
		PRINT N'Table [ingest].[Attributes] exists, creating a copy';
		EXEC sp_rename 'ingest.Attributes', 'Attributes_Migration';
	END

	PRINT N'Creating new table [ingest].[APITokens]...';

	CREATE TABLE [ingest].[Attributes] (
		[AttributeId]               INT            IDENTITY (1, 1) NOT NULL,
		[DatasetFK]                 INT            NULL,
		[AttributeName]             NVARCHAR (50)  NOT NULL,
		[AttributeSourceDataType]   NVARCHAR (50)  NULL,
		[AttributeTargetDataType]   NVARCHAR (50)  NULL,
		[AttributeTargetDataFormat] VARCHAR (100)  NULL,
		[AttributeDescription]      NVARCHAR (500) NULL,
		[PkAttribute]               BIT            NOT NULL,
		[PartitionByAttribute]      BIT            NOT NULL,
		[Enabled]                   BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([AttributeId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [ingest].[Attributes] created';
	PRINT N'Migrating data to new table [ingest].[Attributes]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'Attributes_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [ingest].[Attributes_Migration])
		BEGIN
			SET IDENTITY_INSERT [ingest].[Attributes] ON;
			INSERT INTO [ingest].[Attributes] ([AttributeId],[DatasetFK],[AttributeName],[AttributeSourceDataType],[AttributeTargetDataType],[AttributeTargetDataFormat],[AttributeDescription],[PkAttribute],[PartitionByAttribute],[Enabled])
			SELECT  
				[AttributeId],
				[DatasetFK],
				[AttributeName],
				[AttributeSourceDataType],
				[AttributeTargetDataType],
				[AttributeTargetDataFormat],
				[AttributeDescription],
				[PkAttribute],
				[PartitionByAttribute],
				[Enabled]
			FROM     [ingest].[Attributes_Migration]
			ORDER BY [AttributeId] ASC;
			SET IDENTITY_INSERT [ingest].[Attributes] OFF;
		END
	END

	PRINT N'Migrated data to new table [ingest].[Attributes]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [ingest].[Attributes_Migration];
	END

-- [ingest].[Datasets]
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [ingest].[Datasets] -----';
	PRINT N'Checking for existing table [ingest].[Datasets]...';

	-- Migration Case 1: ingest.Datasets already exists
	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'Datasets')
	
	BEGIN
		PRINT N'Table [ingest].[Datasets] exists, creating a copy';
		EXEC sp_rename 'ingest.Datasets', 'Datasets_Migration';
		IF EXISTS (
			SELECT 1 FROM sys.columns WHERE [name] = N'CDCWhereClause'
			AND [object_id] = OBJECT_ID(N'ingest.Datasets_Migration'))
		BEGIN
			ALTER TABLE [ingest].[Datasets_Migration] ADD LoadClause AS (CDCWhereClause);  
		END
	END
	PRINT N'Creating new table [ingest].[Datasets]...';

	CREATE TABLE [ingest].[Datasets] (
		[DatasetId]                       INT            IDENTITY (1, 1) NOT NULL,
		[ConnectionFK]                    INT            NOT NULL,
		[MergeComputeConnectionFK]        INT            NULL,
		[DatasetDisplayName]              NVARCHAR (50)  NOT NULL,
		[SourcePath]                      NVARCHAR (100) NOT NULL,
		[SourceName]                      NVARCHAR (100) NOT NULL,
		[ExtensionType]                   NVARCHAR (20)  NULL,
		[VersionNumber]                   INT            NOT NULL,
		[VersionValidFrom]                DATETIME2 (7)  NULL,
		[VersionValidTo]                  DATETIME2 (7)  NULL,
		[LoadType]                        CHAR (1)       NOT NULL,
		[LoadStatus]                      INT            NULL,
		[LoadClause]                      NVARCHAR (MAX) NULL,
		[RawLastFullLoadDate]             DATETIME2 (7)  NULL,
		[RawLastIncrementalLoadDate]      DATETIME2 (7)  NULL,
		[CleansedPath]                    NVARCHAR (100) NOT NULL,
		[CleansedName]                    NVARCHAR (100) NOT NULL,
		[CleansedLastFullLoadDate]        DATETIME2 (7)  NULL,
		[CleansedLastIncrementalLoadDate] DATETIME2 (7)  NULL,
		[Enabled]                         BIT            NOT NULL,
		PRIMARY KEY CLUSTERED ([DatasetId] ASC) ON [PRIMARY]
	) ON [PRIMARY];


	PRINT N'Table [ingest].[Datasets] created';
	PRINT N'Migrating data to new table [ingest].[Datasets]';

	IF EXISTS (
		SELECT * 
		FROM INFORMATION_SCHEMA.TABLES 
		WHERE TABLE_SCHEMA = 'ingest' 
		AND  TABLE_NAME = 'Datasets_Migration') 
	BEGIN
		IF EXISTS (SELECT TOP 1 1 
			   FROM   [ingest].[Datasets_Migration])
		BEGIN
			SET IDENTITY_INSERT [ingest].[Datasets] ON;
			INSERT INTO [ingest].[Datasets] ([DatasetId],[ConnectionFK],[MergeComputeConnectionFK],[DatasetDisplayName],[SourcePath],[SourceName],[ExtensionType],[VersionNumber],[VersionValidFrom],[VersionValidTo],[LoadType],[LoadStatus],[LoadClause],[RawLastFullLoadDate],[RawLastIncrementalLoadDate],[CleansedPath],[CleansedName],[CleansedLastFullLoadDate],[CleansedLastIncrementalLoadDate],[Enabled])
			SELECT  
				[DatasetId],
				[ConnectionFK],
				[MergeComputeConnectionFK],
				[DatasetDisplayName],
				[SourcePath],
				[SourceName],
				[ExtensionType],
				[VersionNumber],
				[VersionValidFrom],
				[VersionValidTo],
				[LoadType],
				[LoadStatus],
				[LoadClause],
				[RawLastFullLoadDate],
				[RawLastIncrementalLoadDate],
				[CleansedPath],
				[CleansedName],
				[CleansedLastFullLoadDate],
				[CleansedLastIncrementalLoadDate],
				[Enabled]
			FROM     [ingest].[Datasets_Migration]
			ORDER BY [DatasetId] ASC;
			SET IDENTITY_INSERT [ingest].[Datasets] OFF;
		END
	END

	PRINT N'Migrated data to new table [ingest].[Datasets]';
	PRINT N'Drop historic table';
	DROP TABLE IF EXISTS [ingest].[Datasets_Migration];
	END

-- [ingest].[AuditAttributes]
	BEGIN
	PRINT N'';
	PRINT N'----- Migration for Table [ingest].[AuditAttributes] -----';
	PRINT N'Drop table [ingest].[AuditAttributes] if it exists...';

	-- Migration Case 1: ingest.AuditAttributes already exists
	DROP TABLE IF EXISTS [ingest].[AuditAttributes];

	END
END
/*
Migrate Table Constraints
*/
BEGIN
	PRINT N'Creating [DatasetFK] Foreign Key on [ingest].[Attributes]..';
	ALTER TABLE [ingest].[Attributes] WITH NOCHECK
		ADD FOREIGN KEY ([DatasetFK]) REFERENCES [ingest].[Datasets] ([DatasetId]);

	PRINT N'Creating Check Constraint [ingest].[chkDatasetDisplayNameNoSpaces]...';
	ALTER TABLE [ingest].[Datasets] WITH NOCHECK
		ADD CONSTRAINT [chkDatasetDisplayNameNoSpaces] CHECK ((NOT [DatasetDisplayName] like '% %'));
END
/*
Migrate Views
		[ingest].[DatasetsLatestVersion] (View)
*/
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest] Views -----';

	PRINT N'----- Drop View [ingest].[DatasetsLatestVersion] -----';
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND OBJECT_ID = OBJECT_ID('[ingest].[DatasetsLatestVersion]'))
	BEGIN
		DROP VIEW [ingest].[DatasetsLatestVersion]
	END
END

/*
Migrate Functions
       [ingest].[GetIngestLoadAction] (Function)
*/
BEGIN
--[ingest].[GetIngestLoadAction]
	BEGIN
	PRINT N'----- Creating Function [ingest].[GetIngestLoadAction] -----';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND OBJECT_ID = OBJECT_ID('[ingest].[GetIngestLoadAction]'))
	BEGIN
		EXEC ('CREATE FUNCTION [ingest].[GetIngestLoadAction] (@ExampleParameter INT) 
		RETURNS INT 
		AS 
		BEGIN 
			RETURN 1;
		END;')
	END

	EXEC ('
	ALTER FUNCTION [ingest].[GetIngestLoadAction]
		(
            @DatasetId INT,
            @IngestStage VARCHAR(10)
        )
        RETURNS VARCHAR(1)
        AS 
        BEGIN
        DECLARE @LoadStatus INT
        DECLARE @LoadType VARCHAR(1)
        DECLARE @LoadAction VARCHAR(1)
        DECLARE @RawLastLoadDate DATETIME2
        DECLARE @CleansedLastLoadDate DATETIME2

        -- Defensive check for valid @IngestStage parameter: RAISERROR not allowed in UDF
        -- IF @IngestStage NOT IN (''Raw'',''Cleansed'')
        -- BEGIN
        --     RAISERROR(''Ingest Stage specified not supported. Please specify either Raw or Cleansed action'', 16, 1)
        -- END

        SELECT 
            @LoadStatus = LoadStatus,
            @LoadType = LoadType
        FROM 
            ingest.[Datasets]
        WHERE
            DatasetId = @DatasetId

        -- PRINT @LoadStatus

        -- No load of any kind for this dataset
        -- next raw load: full
        -- next incremental load: error
        IF @LoadStatus = 0 
        BEGIN
            IF @IngestStage = ''Raw''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Cleansed''
            BEGIN
                SET @LoadAction = ''X''
                --RAISERROR(''No Raw Full load completed. Please confirm this has not failed before proceeding with this cleansed load operation.'',16,1)
            END
        END
        -- raw no loads
        -- next raw load: full
        -- next incremental load: error
        IF ( (2 & @LoadStatus) <> 2 )
        BEGIN
            IF @IngestStage = ''Raw''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Cleansed''
            BEGIN
                SET @LoadAction = ''X''
                -- RAISERROR(''No Raw Full load completed. Please confirm this has not failed before proceeding with this cleansed load operation.'',16,1)
            END
        END

        -- raw full, cleansed null, 
        -- next raw load: incremental (if LoadType = ''I'')
        -- next cleansed load: full
        -- set raw comparison date = rawlastloaddate, cleansed comparison date = cleansedlastfullloaddate (nullable)
        IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) <> 4 ) AND ( (8 & @LoadStatus) <> 8)
        BEGIN
            IF @IngestStage = ''Raw'' AND @LoadType = ''F''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Raw'' AND @LoadType = ''I''
            BEGIN
                SET @LoadAction = ''I''
            END
            IF @IngestStage = ''Cleansed''
            BEGIN
                SET @LoadAction = ''F''
            END
        END

        -- raw full, cleased full
        -- next raw load: incremental (if LoadType = ''I'')
        -- next cleansed load: full
        -- set raw comparison date = rawlastloaddate, cleansed comparison date = cleansedlastfullloaddate (nullable)
        IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) <> 4 ) AND ( (8 & @LoadStatus) = 8)
        BEGIN
            IF @IngestStage = ''Raw'' AND @LoadType = ''F''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Raw'' AND @LoadType = ''I''
            BEGIN
                SET @LoadAction = ''I''
            END
            IF @IngestStage = ''Cleansed''
            BEGIN
                SET @LoadAction = ''F''
            END
        END

        -- raw full, raw incremental and cleansed null
        -- next raw load: incremental (if LoadType = ''I'')
        -- next cleansed load: full
        IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) = 4 ) AND ( (8 & @LoadStatus) <> 8)
        BEGIN
            IF @IngestStage = ''Raw'' AND @LoadType = ''F''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Raw'' AND @LoadType = ''I''
            BEGIN
                SET @LoadAction = ''I''
            END
            IF @IngestStage = ''Cleansed''
            BEGIN
                SET @LoadAction = ''F''
            END
        END



        -- raw full, raw incremental and cleansed full
        -- next raw load: incremental  (if LoadType = ''I'')
        -- next cleansed load: incremental  (if LoadType = ''I'')
        IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) = 4 ) AND ( (8 & @LoadStatus) = 8)
        BEGIN
            IF @IngestStage = ''Raw'' AND @LoadType = ''F''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Raw'' AND @LoadType = ''I''
            BEGIN
                SET @LoadAction = ''I''
            END
            IF @IngestStage = ''Cleansed'' AND @LoadType = ''F''
            BEGIN
                SET @LoadAction = ''F''
            END
            IF @IngestStage = ''Cleansed'' AND @LoadType = ''I''
            BEGIN
                SET @LoadAction = ''I''
            END

        END

        RETURN @LoadAction;
        END
    ');

	EXEC sys.sp_refreshsqlmodule  N'ingest.GetIngestLoadAction';
	END
END
/*
Migrate Stored Procedures
       [ingest].[SetLatestRefreshToken] (Procedure)
       [ingest].[GetLatestRefreshToken] (Procedure)
       [ingest].[AddIngestPayloadPipelineDependencies] (Procedure)
       [ingest].[SetIngestLoadStatus] (Procedure)
       [ingest].[GetMergePayload] (Procedure)
       [ingest].[GetDatasetPayload] (Procedure)
	   [ingest].[AddAuditAttribute] (Procedure)
*/
BEGIN

-- [ingest].[SetLatestRefreshToken] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[SetLatestRefreshToken] Stored Procedure -----';

	PRINT N'Creating [ingest].[SetLatestRefreshToken] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[SetLatestRefreshToken]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[SetLatestRefreshToken] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[SetLatestRefreshToken]';
	EXEC('
	ALTER PROCEDURE [ingest].[SetLatestRefreshToken]
	(
	@Input NVARCHAR(MAX),
	@DatasetId INT
	) AS
	BEGIN

		DECLARE @ConnectionId INT

		SELECT @ConnectionID = ConnectionFK
		FROM [ingest].[Datasets]
		WHERE DatasetId = @DatasetId

		-- Defensive Programming Check - Ensure record exists for ConnectionFK in [ingest].[APITokens] table
		DECLARE @Counter INT

		SELECT @Counter = COUNT(*)
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId

		IF @COUNTER = 0
		BEGIN
			RAISERROR(''No results returned for the provided Connection Id. Confirm Refresh Token logic is required for this API, and populate initial values as required.'',16,1)
			RETURN 0;
		END

	
		-- INSERT Statement
		INSERT INTO [ingest].[APITokens] (ConnectionFK, IdentityToken, IdentityTokenExpiryDateTime, RefreshToken, RefreshTokenExpiryDateTime)
		SELECT @ConnectionId, IdentityToken, IdentityTokenExpiryDateTime, RefreshToken, RefreshTokenExpiryDateTime
		FROM OPENJSON(@input)
		WITH (
			IdentityToken NVARCHAR(MAX) ''$.identityToken'',
			IdentityTokenExpiryDateTime NVARCHAR(MAX) ''$.identityTokenExpires'',
			RefreshToken NVARCHAR(MAX) ''$.refreshToken'',
			RefreshTokenExpiryDateTime NVARCHAR(MAX) ''$.refreshTokenExpires''
		);

	END
	');

	PRINT N'Update complete for [ingest].[SetLatestRefreshToken]';
END

-- [ingest].[GetLatestRefreshToken] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[GetLatestRefreshToken] Stored Procedure -----';

	PRINT N'Creating [ingest].[GetLatestRefreshToken] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[GetLatestRefreshToken]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[GetLatestRefreshToken] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[GetLatestRefreshToken]';
	EXEC('
	ALTER PROCEDURE [ingest].[GetLatestRefreshToken]
	(
	@DatasetId INT
	)
	AS
	BEGIN

		DECLARE @ConnectionId INT

		SELECT @ConnectionID = ConnectionFK
		FROM [ingest].[Datasets]
		WHERE DatasetId = @DatasetId

		-- Defensive Programming Check - Ensure record exists for ConnectionFK in [ingest].[APITokens] table
		DECLARE @Counter INT

		SELECT @Counter = COUNT(*)
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId

		IF @COUNTER = 0
		BEGIN
			RAISERROR(''No results returned for the provided Connection Id. Confirm Refresh Token logic is required for this API, and populate initial values as required.'',16,1)
			RETURN 0;
		END

		-- Defensive Programming Check - Ensure Refresh Token Expiry Date is in the future
		DECLARE @RefreshTokenValid BIT
		SELECT TOP 1
			@RefreshTokenValid = CASE 
				WHEN RefreshTokenExpiryDateTime > GETDATE() THEN 1
				ELSE 0
			END
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId
		ORDER BY APITokenId DESC
	
		IF @RefreshTokenValid = 0
		BEGIN
			RAISERROR(''Latest Refresh Token has expired, Please review and update metadata accordingly.'',16,1)
			RETURN 0;
		END

		-- SELECT Statement
		SELECT TOP 1
			IdentityToken,
			IdentityTokenExpiryDateTime,
			RefreshToken,
			RefreshTokenExpiryDateTime
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId
		ORDER BY APITokenId DESC


	END
	');

	PRINT N'Update complete for [ingest].[GetLatestRefreshToken]';
END

-- [ingest].[AddIngestPayloadPipelineDependencies] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[AddIngestPayloadPipelineDependencies] Stored Procedure -----';

	PRINT N'Creating [ingest].[AddIngestPayloadPipelineDependencies] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[AddIngestPayloadPipelineDependencies]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[AddIngestPayloadPipelineDependencies] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[AddIngestPayloadPipelineDependencies]';
	EXEC('
	ALTER PROCEDURE [ingest].[SetLatestRefreshToken]
	(
		@DatasetDisplayName VARCHAR(50)
	) AS
	DECLARE @DatasetId INT

	-- defensive checks only 1 dataset id returned
	DECLARE @DatasetCount INT

	SELECT @DatasetCount = COUNT(*)
	FROM [ingest].[Datasets] AS ds
	INNER JOIN [ingest].[Connections] AS cs
	ON ds.ConnectionFK = cs.ConnectionId
	WHERE ds.Enabled = 1
	AND cs.Enabled = 1
	AND ds.DatasetDisplayName = @DatasetDisplayName

	IF @DatasetCount = 0
	BEGIN
		RAISERROR(''No rows returned. Please review the Dataset Id provided and confirm this is enabled.'',16,1)
		RETURN 0;
	END
	IF @DatasetCount > 1
	BEGIN
		RAISERROR(''More than 1 row returned. Please review there is 1 active Dataset for the provided Dataset Id, and the connection details.'',16,1)
		RETURN 0;
	END

	SELECT 
		@DatasetId = DatasetId
	FROM [ingest].[Datasets]
	WHERE DatasetDisplayName = @DatasetDisplayName
	AND Enabled = 1


	DECLARE @Dependencies TABLE (
		PipelineId INT, -- Raw
		DependantPipelineId INT -- Cleansed
	)

	DECLARE @DependenciesStagingTable TABLE (
		PipelineId INT,
		StageId INT,
		ParameterValue INT
	)
	DECLARE @PipelineIdResult INT;
	DECLARE @DependantPipelineIdResult INT;

	INSERT INTO @DependenciesStagingTable (PipelineId,StageId,ParameterValue)
	SELECT 
		p.PipelineId, p.StageId, CAST(pp.ParameterValue AS INT) AS ParameterValue --,*
	FROM control.Pipelines AS p
	INNER JOIN control.PipelineParameters AS pp
	ON p.PipelineId = pp.PipelineId
	WHERE p.PipelineName LIKE ''Ingest_PL_%''

	SELECT @PipelineIdResult = PipelineId 
	FROM @DependenciesStagingTable
	INNER JOIN ingest.Datasets AS d
	ON ParameterValue = d.DatasetId
	WHERE ParameterValue = @DatasetId
	AND StageId = 1

	SELECT @DependantPipelineIdResult = PipelineId 
	FROM @DependenciesStagingTable
	INNER JOIN ingest.Datasets AS d
	ON ParameterValue = d.DatasetId
	WHERE ParameterValue = @DatasetId
	AND StageId = 2

	INSERT INTO @Dependencies (PipelineId,DependantPipelineId)
	SELECT @PipelineIdResult, @DependantPipelineIdResult

	IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NULL
	BEGIN 
		RAISERROR(''Missing Ids for this Dataset'',16,1)
		RETURN 0;
	END
	ELSE IF @PipelineIdResult IS NULL AND @DependantPipelineIdResult IS NOT NULL
	BEGIN 
		RAISERROR(''Missing PipelineId (Raw Ingest Pipeline)'',16,1)
		RETURN 0;
	END
	ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NULL
	BEGIN 
		RAISERROR(''Missing DependantPipelineId (Cleansed Merge Pipeline)'',16,1)
		RETURN 0;
	END
	ELSE IF @PipelineIdResult IS NOT NULL AND @DependantPipelineIdResult IS NOT NULL
	BEGIN 
		MERGE INTO control.PipelineDependencies AS target
		USING @Dependencies AS source
		ON target.PipelineId = source.PipelineId
		AND target.DependantPipelineId = source.DependantPipelineId
		WHEN NOT MATCHED THEN
			INSERT (PipelineId, DependantPipelineId) VALUES (source.PipelineId, source.DependantPipelineId);
		PRINT ''Dependencies merged into control.PipelineDependencies''
	END
	ELSE 
	BEGIN
		RAISERROR(''Unexpected Error'',16,1)
		RETURN 0;
	END
	');

	PRINT N'Update complete for [ingest].[SetLatestRefreshToken]';
END

-- [ingest].[SetIngestLoadStatus] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[SetIngestLoadStatus] Stored Procedure -----';

	PRINT N'Creating [ingest].[SetIngestLoadStatus] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[SetIngestLoadStatus]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[SetIngestLoadStatus] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[SetIngestLoadStatus]';
	EXEC('
	ALTER PROCEDURE [ingest].[SetIngestLoadStatus]
	(
    @DatasetId INT,
    @LoadType VARCHAR(1),
    @IngestStage VARCHAR(20),
    @FileLoadDateTime DATETIME2
	)
	AS
	BEGIN
	DECLARE @LoadStatus INT

	SELECT 
		@LoadStatus = LoadStatus
	FROM 
		[ingest].[Datasets]
	WHERE
		DatasetId = @DatasetId

	IF @LoadType = ''F'' AND @IngestStage = ''Raw''
	BEGIN
		-- Add that a raw full load has occurred
		SET @LoadStatus = @LoadStatus | POWER(2,1) 
    
		-- Remove the raw incremental load status
		SET @LoadStatus = @LoadStatus & ~POWER(2,2) 

		UPDATE [ingest].[Datasets]
		SET LoadStatus = @LoadStatus,
			RawLastFullLoadDate = @FileLoadDateTime
		WHERE DatasetId = @DatasetId
	END

	IF @LoadType = ''I'' AND @IngestStage = ''Raw''
	BEGIN
		SET @LoadStatus = @LoadStatus | POWER(2,2) 

		UPDATE [ingest].[Datasets]
		SET LoadStatus = @LoadStatus,
			RawLastIncrementalLoadDate = @FileLoadDateTime
		WHERE DatasetId = @DatasetId
	END

	IF @LoadType = ''F'' AND @IngestStage = ''Cleansed''
	BEGIN
		-- Add that a cleansed full load has occurred
		SET @LoadStatus = @LoadStatus | POWER(2,3)  

		-- Remove the cleansed incremental load status
		SET @LoadStatus = @LoadStatus & ~POWER(2,4) 

		UPDATE [ingest].[Datasets]
		SET LoadStatus = @LoadStatus,
			CleansedLastFullLoadDate = @FileLoadDateTime
		WHERE DatasetId = @DatasetId
	END

	IF @LoadType = ''I'' AND @IngestStage = ''Cleansed''
	BEGIN
		SET @LoadStatus = @LoadStatus | POWER(2,4)  
		UPDATE [ingest].[Datasets]
		SET LoadStatus = @LoadStatus,
			CleansedLastIncrementalLoadDate = @FileLoadDateTime
		WHERE DatasetId = @DatasetId
	END

	END
	');

	PRINT N'Update complete for [ingest].[SetLatestRefreshToken]';
END

-- [ingest].[GetMergePayload] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[GetMergePayload] Stored Procedure -----';

	PRINT N'Creating [ingest].[GetMergePayload] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[GetMergePayload]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[GetMergePayload] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[GetMergePayload]';
	EXEC('
	ALTER PROCEDURE [ingest].[GetMergePayload]
	    (
        @DatasetId INT
        )
    AS
    BEGIN

        -- Defensive check for results returned
        DECLARE @ResultRowCount INT

        SELECT 
            @ResultRowCount = COUNT(*)
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN 
            [common].Connections AS cn
        ON  
            ds.ConnectionFK = cn.ConnectionId
        INNER JOIN 
            [common].ComputeConnections AS cn2
        ON 
            ds.MergeComputeConnectionFK = cn2.ComputeConnectionId
        INNER JOIN
            common.Connections AS cn3
        ON 
            cn3.ConnectionDisplayName = ''PrimaryResourceGroup''
        INNER JOIN
            [common].Connections AS cn4
        ON 
            cn4.ConnectionDisplayName = ''PrimarySubscription''
        INNER JOIN
            [common].Connections AS cn5
        ON 
            cn5.ConnectionDisplayName = ''PrimaryDataLake'' AND cn5.SourceLocation IN (''raw'',''bronze'')
        INNER JOIN
            [common].Connections AS cn6
        ON 
            cn6.ConnectionDisplayName = ''PrimaryDataLake'' AND cn6.SourceLocation IN (''cleansed'', ''silver'')

        WHERE
            ds.DatasetId = @DatasetId
        AND
            ds.[Enabled] = 1
        AND
            cn.[Enabled] = 1
        AND
            cn2.[Enabled] = 1
        AND
            cn3.[Enabled] = 1
        AND
            cn4.[Enabled] = 1
        AND
            cn5.[Enabled] = 1
        AND
            cn6.[Enabled] = 1

        IF @ResultRowCount = 0
        BEGIN
            RAISERROR(''No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections and Attributes are enabled.'',16,1)
            RETURN 0;
        END


        DECLARE @CleansedColumnsList NVARCHAR(MAX)
        DECLARE @CleansedColumnsTypeList NVARCHAR(MAX)
        DECLARE @CleansedColumnsFormatList NVARCHAR(MAX)

        DECLARE @PkAttributesList NVARCHAR(MAX) = ''''
        DECLARE @PartitionByAttributesList NVARCHAR(MAX) = ''''

        DECLARE @DateTimeFolderHierarchy NVARCHAR(1000)

        -- Get attribute data as comma separated string values for the dataset
        SELECT 
            @CleansedColumnsList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),'',''),
            @CleansedColumnsTypeList = STRING_AGG(CAST(att.AttributeTargetDataType AS NVARCHAR(MAX)),'',''),
            @CleansedColumnsFormatList = STRING_AGG(CAST(att.AttributeTargetDataFormat AS NVARCHAR(MAX)), '','')
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN 
            ingest.Attributes AS att
        ON 
            att.DatasetFK = ds.DatasetId
        WHERE
            ds.DatasetId = @DatasetId
        AND
            ds.[Enabled] = 1
        AND
            att.[Enabled] = 1

        GROUP BY ds.DatasetId

        -- Get pk columns as comma separated string values for the dataset
        SELECT 
            @PkAttributesList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),'','')
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN 
            ingest.Attributes AS att
        ON 
            att.DatasetFK = ds.DatasetId
        WHERE
            ds.DatasetId = @DatasetId
        AND
            ds.[Enabled] = 1
        AND 
            att.[PkAttribute] = 1
        AND 
            att.[Enabled] = 1
        GROUP BY 
            ds.DatasetId

        -- Get pk columns as comma separated string values for the dataset
        SELECT 
            @PkAttributesList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),'','')
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN 
            ingest.Attributes AS att
        ON 
            att.DatasetFK = ds.DatasetId
        WHERE
            ds.[DatasetId] = @DatasetId
        AND 
            ds.[Enabled] = 1
        AND 
            att.[Enabled] = 1
        AND 
            att.[PartitionByAttribute] = 1
        GROUP BY 
            ds.DatasetId

        DECLARE @LoadAction VARCHAR(1)
        DECLARE @RawLastLoadDate DATETIME2
        DECLARE @CleansedLastLoadDate DATETIME2

        SELECT @LoadAction = ingest.GetIngestLoadAction(@DatasetId, ''Cleansed'')
        IF @LoadAction = ''F''
            SELECT 
                @RawLastLoadDate = RawLastFullLoadDate,
                @CleansedLastLoadDate = CleansedLastFullLoadDate
            FROM 
                [ingest].[Datasets] AS ds
            WHERE 
                ds.[DatasetId] = @DatasetId
            AND 
                ds.[Enabled] = 1
        ELSE IF @LoadAction = ''I''
            SELECT 
                @RawLastLoadDate = RawLastIncrementalLoadDate,
                @CleansedLastLoadDate = CleansedLastIncrementalLoadDate
            FROM 
                [ingest].[Datasets] AS ds
            WHERE 
                ds.[DatasetId] = @DatasetId
            AND 
                ds.[Enabled] = 1

        ELSE IF @LoadAction = ''X''
        BEGIN
            RAISERROR(''Erroneous Load Status. Review the ingest LoadStatus value for the dataset in [ingest].[Datasets]'',16,1)
            RETURN 0;
        END
        ELSE
        BEGIN
            RAISERROR(''Unexpected Load action. Review the ingest LoadStatus value for the dataset in [ingest].[Datasets]'',16,1)
            RETURN 0;
        END
        SELECT 
            @DateTimeFolderHierarchy = ''year='' + CAST(FORMAT(@RawLastLoadDate,''yyyy'') AS VARCHAR) + ''/'' + 
            ''month='' + CAST(FORMAT(@RawLastLoadDate,''MM'') AS VARCHAR) + ''/'' + 
            ''day='' + CAST(FORMAT(@RawLastLoadDate,''dd'') AS VARCHAR) + ''/'' + 
            ''hour='' + CAST(FORMAT(@RawLastLoadDate,''HH'') AS VARCHAR) 
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1

        SELECT 
            [cn].[ConnectionDisplayName] AS ''RawSchemaName'',
            [cn2].[ConnectionLocation] AS ''ComputeWorkspaceURL'',
            [cn2].[ComputeLocation] AS ''ComputeClusterId'',
            [cn2].[ComputeSize] AS ''ComputeSize'',
            [cn2].[ComputeVersion] AS ''ComputeVersion'',
            [cn2].[CountNodes] AS ''CountNodes'',
            [cn2].[LinkedServiceName] AS ''ComputeLinkedServiceName'',
            [cn2].[ResourceName] AS ''ComputeResourceName'',
            [cn3].[SourceLocation] AS ''ResourceGroupName'',
            [cn4].[SourceLocation] AS ''SubscriptionId'',
            [cn5].[ConnectionLocation] AS ''RawStorageName'',
            [cn5].[SourceLocation] AS ''RawContainerName'',
            [cn6].[ConnectionLocation] AS ''CleansedStorageName'',
            [cn6].[SourceLocation] AS ''CleansedContainerName'',
            [cn5].[Username] AS ''RawStorageAccessKey'',
            [cn6].[Username] AS ''CleansedStorageAccessKey'',

            ds.DatasetDisplayName,
            ds.SourceName,
            ds.ExtensionType AS ''RawFileType'',
            ds.VersionNumber,
            [cn].[ConnectionDisplayName] AS ''CleansedSchemaName'',
            ds.CleansedName AS ''CleansedTableName'',
            ds.Enabled,
            ds.LoadType,
            @LoadAction AS ''LoadAction'',
            @RawLastLoadDate AS ''RawLastLoadDate'',
            @CleansedLastLoadDate AS ''CleansedLastLoadDate'',
            @CleansedColumnsList AS ''CleansedColumnsList'', 
            @CleansedColumnsTypeList AS ''CleansedColumnsTypeList'',
            @CleansedColumnsFormatList AS ''CleansedColumnsFormatList'',
            @PkAttributesList AS ''CleansedPkList'',
            @PartitionByAttributesList AS ''CleansedPartitionFields'',
            @DateTimeFolderHierarchy AS ''DateTimeFolderHierarchy''
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN 
            [common].Connections AS cn
        ON  
            ds.ConnectionFK = cn.ConnectionId
        INNER JOIN 
            [common].ComputeConnections AS cn2
        ON 
            ds.MergeComputeConnectionFK = cn2.ComputeConnectionId
        INNER JOIN
            [common].Connections AS cn3
        ON 
            cn3.ConnectionDisplayName = ''PrimaryResourceGroup''
        INNER JOIN
            [common].Connections AS cn4
        ON 
            cn4.ConnectionDisplayName = ''PrimarySubscription''
        INNER JOIN
            [common].Connections AS cn5
        ON 
            cn5.ConnectionDisplayName = ''PrimaryDataLake'' AND cn5.SourceLocation IN (''raw'',''bronze'')
        INNER JOIN
            [common].Connections AS cn6
        ON 
            cn6.ConnectionDisplayName = ''PrimaryDataLake'' AND cn6.SourceLocation IN (''cleansed'',''silver'')
        WHERE
            ds.DatasetId = @DatasetId
        AND
            ds.[Enabled] = 1
        AND
            cn.[Enabled] = 1
        AND
            cn2.[Enabled] = 1
        AND
            cn3.[Enabled] = 1
        AND
            cn4.[Enabled] = 1
        AND
            cn5.[Enabled] = 1
        AND
            cn6.[Enabled] = 1


    END
	');

	PRINT N'Update complete for [ingest].[GetMergePayload]';
END

-- [ingest].[GetDatasetPayload] 
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[GetDatasetPayload] Stored Procedure -----';

	PRINT N'Creating [ingest].[GetDatasetPayload] if it does not exist...';
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('[ingest].[GetDatasetPayload]'))
	BEGIN
		EXEC('CREATE PROCEDURE [ingest].[GetDatasetPayload] AS BEGIN SET NOCOUNT ON; END');
	END

	PRINT N'Updating [ingest].[GetDatasetPayload]';
	EXEC('
	ALTER PROCEDURE [ingest].[GetDatasetPayload]
	    (
        @DatasetId INT
    )
    AS
    BEGIN

        -- Defensive check for results returned
        DECLARE @ResultRowCount INT

        SELECT 
            @ResultRowCount = COUNT(*)
        FROM
        [ingest].[Datasets] ds
        INNER JOIN [common].[Connections] cn1
            ON ds.[ConnectionFK] = cn1.[ConnectionId]
        INNER JOIN [common].[Connections] cn2
            ON cn2.[ConnectionDisplayName] = ''PrimaryDataLake'' AND cn2.[SourceLocation] IN (''raw'',''bronze'')
        INNER JOIN [common].[Connections] cn3
            ON cn3.[ConnectionDisplayName] = ''PrimaryKeyVault''
        WHERE
        ds.[DatasetId] = @DatasetId
        AND 
            ds.[Enabled] = 1
        AND 
            cn1.[Enabled] = 1
        AND 
            cn2.[Enabled] = 1
        AND 
            cn3.[Enabled] = 1

        IF @ResultRowCount = 0
        BEGIN
            RAISERROR(''No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections are enabled.'',16,1)
        RETURN 0;
        END


        -- Set LoadType conditions
        DECLARE @LoadType CHAR(1)
        DECLARE @LoadAction VARCHAR(12)

        SET @LoadType = ingest.GetIngestLoadAction(@DatasetId, ''Raw'')


        -- Set Source Language Type
        DECLARE @SourceLanguageType VARCHAR(5)
        DECLARE @ConnectionType VARCHAR(50)

        SELECT 
            @SourceLanguageType = ct.[SourceLanguageType],
            @ConnectionType = ct.[ConnectionTypeDisplayName]
        FROM [common].[ConnectionTypes] AS ct
        INNER JOIN [common].[Connections] AS cn
            ON ct.ConnectionTypeId = cn.ConnectionTypeFK
        INNER JOIN [ingest].[Datasets] AS ds
            ON cn.ConnectionId = ds.ConnectionFK
        WHERE 
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
        AND 
            ct.[Enabled] = 1
        AND 
            cn.[Enabled] = 1

        DECLARE @SourceQuery VARCHAR(MAX) = ''''

        -- Construct source query
        IF @SourceLanguageType = ''T-SQL''
        BEGIN
        SELECT
        @SourceQuery += '','' + [AttributeName]
        FROM
        [ingest].[Datasets] AS ds
            INNER JOIN [ingest].[Attributes] AS at
                ON ds.[DatasetId] = at.[DatasetFK]
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
        AND 
        at.Enabled = 1

        SELECT 
                @SourceQuery = ''SELECT '' + STUFF(@SourceQuery,1,1,'''') + '' FROM '' + QUOTENAME(ds.[SourcePath]) + ''.'' + QUOTENAME(ds.[SourceName])
            FROM 
                [ingest].[Datasets] AS ds
            WHERE
                ds.DatasetId = @DatasetId 
            AND 
                ds.[Enabled] = 1
        END

        ELSE IF @SourceLanguageType = ''PSQL''
        BEGIN
        SELECT
        @SourceQuery += '','' + [AttributeName]
        FROM
        [ingest].[Datasets] AS ds
            INNER JOIN [ingest].[Attributes] AS at
                ON ds.[DatasetId] = at.[DatasetFK]
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
        AND 
        at.Enabled = 1

        SELECT 
                @SourceQuery = ''SELECT '' + STUFF(@SourceQuery,1,1,'''') + '' FROM '' + UPPER(ds.[SourcePath]) + ''.'' + UPPER(ds.[SourceName])
            FROM 
                [ingest].[Datasets] AS ds
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1    
        END

        ELSE IF @SourceLanguageType = ''SOQL''
        BEGIN
        SELECT
        @SourceQuery += '','' + [AttributeName]
        FROM
        [ingest].[Datasets] AS ds
            INNER JOIN [ingest].[Attributes] AS at
                ON ds.[DatasetId] = at.[DatasetFK]
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
        AND 
        at.Enabled = 1

        SELECT 
                @SourceQuery = ''SELECT '' + STUFF(@SourceQuery,1,1,'''') + '' FROM '' + UPPER(ds.[SourceName])
            FROM 
                [ingest].[Datasets] AS ds
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1    
        END

        -- Logic not required/built yet.
        ELSE IF @SourceLanguageType = ''SQL''
        BEGIN
            SET @SourceQuery = @SourceQuery
        END

        ELSE IF @SourceLanguageType = ''XML''
        BEGIN
        DECLARE @LoadClause XML

        -- Start building the XML statement for the query
        SET @SourceQuery = ''<fetch>''

        SELECT
        @SourceQuery += ''<entity name="'' + [SourceName] + ''">''
        ,@LoadClause = LoadClause -- Unused if we''re running a full load.
        FROM
        [ingest].[Datasets] AS ds
        WHERE
        ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1

        -- recursively add the attributes to load
        SELECT
        @SourceQuery += ''<attribute name="'' + [AttributeName] + ''" />''
        FROM
        [ingest].[Datasets] AS ds
        INNER JOIN [ingest].[Attributes] AS at
        ON ds.[DatasetId] = at.[DatasetFK]
        WHERE
        ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
        AND 
        at.Enabled = 1

        IF (@LoadType = ''I'')
        BEGIN
        DECLARE @Result DATETIME;
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @ParameterDef NVARCHAR(MAX);
        DECLARE @XmlValue NVARCHAR(MAX)

        SELECT @XmlValue = @LoadClause.value(''(/filter/condition/@value)[1]'', ''NVARCHAR(MAX)'')

        -- Define the dynamic SQL query -- replace value of (/filter/condition/@value)[1]      with "Jun 20 2023 12:41PM"
        SET @SQL = N''SELECT @OutputResult = '' + @XmlValue;

        -- Define the parameter definition for the OUTPUT parameter
        SET @ParameterDef = N''@OutputResult DATETIME OUTPUT'';

        -- Execute the dynamic SQL and save the result to the @Result variable
        EXEC sp_executesql @SQL, @ParameterDef, @OutputResult=@Result OUTPUT;

        -- Update the value in the XML variable
        SET @LoadClause.modify(''replace value of (/filter/condition/@value)[1] with sql:variable("@Result")'');


        SET @SourceQuery += CAST(@LoadClause AS nvarchar(MAX));

        END 
        SET @SourceQuery += ''</entity></fetch>''
        END

        ELSE IF @SourceLanguageType = ''NA'' AND @ConnectionType <> ''REST API''
        BEGIN
            SELECT 
                @SourceQuery = cn.SourceLocation + ''/'' + ds.SourcePath
            FROM 
                [ingest].[Datasets] AS ds
            INNER JOIN [common].[Connections] AS cn
                ON ds.ConnectionFK = cn.ConnectionId
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
        END

        ELSE IF @ConnectionType = ''REST API''
        BEGIN
            DECLARE @LoadClauseAPI NVARCHAR(MAX);
            DECLARE @LoadClauseAPIReplaced NVARCHAR(MAX);

            -- Define all your parameters and their corresponding values
            DECLARE @params TABLE (ParamName NVARCHAR(50), ParamValue NVARCHAR(30));

            INSERT INTO @params (ParamName, ParamValue)
            VALUES
            (''PARAMETER_GT_1_YEAR'', CONVERT(NVARCHAR, DATEADD(YEAR, -1, GETUTCDATE()), 126)),
            (''PARAMETER_GT_1_MONTH'', CONVERT(NVARCHAR, DATEADD(MONTH, -1, GETUTCDATE()), 126)),
            (''PARAMETER_GT_1_DAY'', CONVERT(NVARCHAR, DATEADD(DAY, -1, GETUTCDATE()), 126)),
            (''PARAMETER_GT_1_HOUR'', CONVERT(NVARCHAR, DATEADD(HOUR, -1, GETUTCDATE()), 126)),
            (''PARAMETER_NOW'', CONVERT(NVARCHAR, GETUTCDATE(), 126)),
            (''PARAMETER_LT_1_YEAR'', CONVERT(NVARCHAR, DATEADD(YEAR, 1, GETUTCDATE()), 126)),
            (''PARAMETER_LT_1_MONTH'', CONVERT(NVARCHAR, DATEADD(MONTH, 1, GETUTCDATE()), 126)),
            (''PARAMETER_LT_1_DAY'', CONVERT(NVARCHAR, DATEADD(DAY, 1, GETUTCDATE()), 126)),
            (''PARAMETER_LT_1_HOUR'', CONVERT(NVARCHAR, DATEADD(HOUR, 1, GETUTCDATE()), 126));

            -- Original LoadClause
            SELECT 
            @LoadClauseAPI = LoadClause,
            @LoadClauseAPIReplaced = LoadClause
            FROM ingest.Datasets
            WHERE DatasetId = @DatasetId

            -- Perform the replacements
            SET @LoadClauseAPIReplaced = @LoadClauseAPI;

            DECLARE @param NVARCHAR(50), @value NVARCHAR(30);

            DECLARE param_cursor CURSOR FOR 
            SELECT ParamName, ParamValue FROM @params;

            OPEN param_cursor;
            FETCH NEXT FROM param_cursor INTO @param, @value;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @LoadClauseAPIReplaced = REPLACE(@LoadClauseAPIReplaced, @param, @value);
                FETCH NEXT FROM param_cursor INTO @param, @value;
            END;
            
            SET @SourceQuery = @LoadClauseAPIReplaced; 

            CLOSE param_cursor;
            DEALLOCATE param_cursor;

        END

        ELSE
        BEGIN
        RAISERROR(''Connection Type / Language Type combination not supported.'',16,1)
        RETURN 0;
        END

        IF (@LoadType = ''F'')
        BEGIN
            SET @SourceQuery = @SourceQuery
            SET @LoadAction = ''full''
        END

        ELSE IF (@LoadType = ''I'') AND (@ConnectionType = ''REST API'')
        BEGIN
            SET @SourceQuery = @SourceQuery
            SET @LoadAction = ''incremental''
        END

        ELSE IF (@LoadType = ''I'') AND (@SourceLanguageType <> ''XML'') AND (@ConnectionType <> ''REST API'')
        BEGIN
            SELECT 
                @SourceQuery = @SourceQuery + '' '' + ds.[LoadClause]
            FROM 
                [ingest].[Datasets] AS ds
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1

            SET @LoadAction = ''incremental''
        END

        ELSE IF (@LoadType = ''I'') AND (@SourceLanguageType = ''XML'')
        BEGIN
            SET @SourceQuery = @SourceQuery
            SET @LoadAction = ''incremental''
        END

        --ELSE IF @LoadType = ''FW''
        --ELSE IF @LoadType = ''H''
        ELSE
        BEGIN
        RAISERROR(''Load type condition not yet supported.'',16,1);
        RETURN 0;
        END

        IF @SourceLanguageType IN (''T-SQL'', ''PSQL'', ''SQL'')
        BEGIN
        SET @SourceQuery = @SourceQuery + '';''
        END

        SELECT
            RIGHT(''0000'' + CAST(ds.[VersionNumber] AS VARCHAR),4) AS ''VersionNumber'',
            ds.[SourceName],
            ds.[SourcePath],
            ds.[DatasetDisplayName],
            ds.[ExtensionType],
            cn1.*,
            cn2.[ConnectionLocation] AS ''TargetStorageName'',
            cn2.[SourceLocation] AS ''TargetStorageContainer'',
            cn3.[ConnectionLocation] AS ''KeyVaultBaseURL'',
            @SourceQuery AS ''SourceQuery'',
            @LoadType AS ''LoadType'',
            @LoadAction AS LoadAction
        FROM 
            [ingest].[Datasets] ds
        INNER JOIN [common].[Connections] cn1
        ON ds.[ConnectionFK] = cn1.[ConnectionId]
        INNER JOIN [common].[Connections] cn2
        ON cn2.[ConnectionDisplayName] = ''PrimaryDataLake'' AND cn2.[SourceLocation] IN (''raw'',''bronze'')
        INNER JOIN [common].[Connections] cn3
        ON cn3.[ConnectionDisplayName] = ''PrimaryKeyVault''
        WHERE
            [DatasetId] = @DatasetId
        AND 
            ds.[Enabled] = 1
        AND 
            cn1.[Enabled] = 1
        AND 
            cn2.[Enabled] = 1
        AND 
            cn3.[Enabled] = 1

    END
	');

	PRINT N'Update complete for [ingest].[GetDatasetPayload]';
END

-- [ingest].[AddAuditAttribute]
BEGIN
	PRINT N'';
	PRINT N'----- Migration for [ingest].[GetDatasetPayload] Stored Procedure -----';

	PRINT N'Drop [ingest].[GetDatasetPayload] if it exists...';
	DROP PROCEDURE IF EXISTS [ingest].[AddAuditAttribute];
END

END

PRINT N'------------- Migration for [ingest] schema objects complete -------------';
END

PRINT N''

PRINT N'------------------------------ Migrate Roles ------------------------------';
If @MigrateRoles = 1
BEGIN
-- Create user
	IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE type = 'E' AND name = @ADFUserName)
	BEGIN
		EXEC('CREATE USER [' + @ADFUserName + '] FROM EXTERNAL PROVIDER');
	END
-- Create Role
	IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE type = 'R' AND name = 'db_cumulususer')
	BEGIN
		CREATE ROLE [db_cumulususer];
	END
-- Grant permissions
	GRANT 
		EXECUTE, 
		SELECT,
		CONTROL,
		ALTER
	ON SCHEMA::[control] TO [db_cumulususer];
	GRANT 
		EXECUTE, 
		SELECT,
		CONTROL,
		ALTER
	ON SCHEMA::[ingest] TO [db_cumulususer];
	GRANT 
		EXECUTE, 
		SELECT,
		CONTROL,
		ALTER
	ON SCHEMA::[transform] TO [db_cumulususer];

-- Add user to role
	EXEC('ALTER ROLE [db_cumulususer]  ADD MEMBER [' + @ADFUserName + ']');
END
PRINT N'-------------------- Migration for Roles complete -------------------------';
PRINT N'';
PRINT N'Update complete.';

PRINT N'';
PRINT N'--------------- Check all objects are created successfully ---------------'
-- BEGIN
-- 	EXEC sp_MSForEachTable @command1='INSERT #countsAfter (table_name, row_count) SELECT ''?'', COUNT(*) FROM ?';
-- 	SELECT @TotalRowCountAfter = SUM(row_count) FROM #countsAfter 	
-- 	WHERE table_name NOT IN 
-- 		(select table_name FROM #countsExclusion);;

-- 	SELECT @TotalRowCountBefore AS TotalRowCountBefore, @TotalRowCountAfter AS TotalRowCountAfter

-- 	IF @TotalRowCountBefore <> @TotalRowCountAfter
-- 	BEGIN
-- 		SELECT table_name, row_count FROM #countsBefore ORDER BY table_name, row_count DESC;
-- 		SELECT table_name, row_count FROM #countsAfter ORDER BY table_name, row_count DESC;
-- 		RAISERROR('Data row count after migration not same as before migration. Please review script before committing code.',16,1);
-- 	END
-- END
 COMMIT TRANSACTION COMMONSCHEMA
    PRINT '[common] objects created or updated'
END TRY

BEGIN CATCH 
  IF (@@TRANCOUNT > 0)
   BEGIN
      ROLLBACK TRANSACTION COMMONSCHEMA
      PRINT 'Error detected, all changes reversed'
   END 
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage
END CATCH
