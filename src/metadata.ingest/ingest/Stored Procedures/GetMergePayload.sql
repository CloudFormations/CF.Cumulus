CREATE PROCEDURE [ingest].[GetMergePayload]
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
        [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN 
        ingest.Connections AS cn
    ON  
        ds.ConnectionFK = cn.ConnectionId
    INNER JOIN 
        ingest.ComputeConnections AS cn2
    ON 
        ds.MergeComputeConnectionFK = cn2.ComputeConnectionId
    INNER JOIN
        ingest.Connections AS cn3
    ON 
        cn3.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        ingest.Connections AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        ingest.Connections AS cn5
    ON 
        cn5.ConnectionDisplayName = 'PrimaryDataLake' AND cn5.SourceLocation = 'raw'
    INNER JOIN
        ingest.Connections AS cn6
    ON 
        cn6.ConnectionDisplayName = 'PrimaryDataLake' AND cn6.SourceLocation = 'cleansed'
    
    WHERE
        ds.DatasetId = @DatasetId

    IF @ResultRowCount = 0
    BEGIN
        RAISERROR('No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections and Attributes are enabled.',16,1)
    END


    DECLARE @CleansedColumnsList NVARCHAR(250)
    DECLARE @CleansedColumnsTypeList NVARCHAR(250)
    DECLARE @CleansedColumnsFormatList NVARCHAR(250)

    DECLARE @PkAttributesList NVARCHAR(250) = ''
    DECLARE @PartitionByAttributesList NVARCHAR(250) = ''

    DECLARE @DateTimeFolderHierarchy NVARCHAR(250)

    -- Get attribute data as comma separated string values for the dataset
    SELECT 
        @CleansedColumnsList = STRING_AGG(att.AttributeName,','),
        @CleansedColumnsTypeList = STRING_AGG(att.AttributeTargetDataType,','),
        @CleansedColumnsFormatList = STRING_AGG(att.AttributeTargetDataFormat, ',')
    FROM 
        [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN 
        ingest.Attributes AS att
    ON 
        att.DatasetFK = ds.DatasetId
    WHERE
        ds.DatasetId = @DatasetId
    GROUP BY ds.DatasetId

    -- Get pk columns as comma separated string values for the dataset
    SELECT 
        @PkAttributesList = STRING_AGG(att.AttributeName,',')
    FROM 
        [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN 
        ingest.Attributes AS att
    ON 
        att.DatasetFK = ds.DatasetId
    WHERE
        ds.DatasetId = @DatasetId
    AND 
        att.PkAttribute = 1
    GROUP BY 
        ds.DatasetId

    -- Get pk columns as comma separated string values for the dataset
    SELECT 
        @PkAttributesList = STRING_AGG(att.AttributeName,',')
    FROM 
        [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN 
        ingest.Attributes AS att
    ON 
        att.DatasetFK = ds.DatasetId
    WHERE
        ds.DatasetId = @DatasetId
    AND 
        att.PartitionByAttribute = 1
    GROUP BY 
        ds.DatasetId

    DECLARE @LoadAction VARCHAR(1)
    DECLARE @RawLastLoadDate DATETIME2
    DECLARE @CleansedLastLoadDate DATETIME2

    SELECT @LoadAction = ingest.GetIngestLoadAction(@DatasetId, 'Cleansed')
    IF @LoadAction = 'F'
        SELECT 
            @RawLastLoadDate = RawLastFullLoadDate,
            @CleansedLastLoadDate = CleansedLastFullLoadDate
        FROM 
            [ingest].[DatasetsLatestVersion]
        WHERE 
            DatasetId = @DatasetId
    ELSE IF @LoadAction = 'I'
        SELECT 
            @RawLastLoadDate = RawLastIncrementalLoadDate,
            @CleansedLastLoadDate = CleansedLastIncrementalLoadDate
        FROM 
            [ingest].[DatasetsLatestVersion]
        WHERE 
            DatasetId = @DatasetId
    
    ELSE IF @LoadAction = 'X'
        RAISERROR('Erroneous Load Status. Review the ingest LoadStatus value for the dataset in [ingest].[DatasetsLatestVersion]',16,1)
    ELSE
        RAISERROR('Unexpected Load action. Review the ingest LoadStatus value for the dataset in [ingest].[DatasetsLatestVersion]',16,1)
  
    SELECT 
        @DateTimeFolderHierarchy = 'year=' + CAST(FORMAT(@RawLastLoadDate,'yyyy') AS VARCHAR) + '/' + 
        'month=' + CAST(FORMAT(@RawLastLoadDate,'MM') AS VARCHAR) + '/' + 
        'day=' + CAST(FORMAT(@RawLastLoadDate,'dd') AS VARCHAR) 
    FROM 
        [ingest].[DatasetsLatestVersion] AS ds
    WHERE
        ds.DatasetId = @DatasetId

    SELECT 
        [cn].[ConnectionDisplayName] AS 'RawSchemaName',
        [cn2].[ConnectionLocation] AS 'ComputeWorkspaceURL',
        [cn2].[ComputeLocation] AS 'ComputeClusterId',
		[cn2].[ComputeSize] AS 'ComputeSize',
		[cn2].[ComputeVersion] AS 'ComputeVersion',
		[cn2].[CountNodes] AS 'CountNodes',
        [cn2].[LinkedServiceName] AS 'ComputeLinkedServiceName',
        [cn2].[AzureResourceName] AS 'ComputeResourceName',
        [cn3].[SourceLocation] AS 'ResourceGroupName',
        [cn4].[SourceLocation] AS 'SubscriptionId',
        [cn5].[ConnectionLocation] AS 'RawStorageName',
		[cn5].[SourceLocation] AS 'RawContainerName',
        [cn6].[ConnectionLocation] AS 'CleansedStorageName',
		[cn6].[SourceLocation] AS 'CleansedContainerName',
        [cn5].[Username] AS 'RawStorageAccessKey',
        [cn6].[Username] AS 'CleansedStorageAccessKey',

        ds.DatasetDisplayName,
        -- ds.SourcePath AS 'RawSchemaName',
        ds.SourceName,
        ds.ExtensionType AS 'RawFileType',
        ds.VersionNumber,
        [cn].[ConnectionDisplayName] AS 'CleansedSchemaName',
        ds.CleansedName AS 'CleansedTableName',
        ds.Enabled,
        @LoadAction AS 'LoadAction',
        @RawLastLoadDate AS 'RawLastLoadDate',
        @CleansedLastLoadDate AS 'CleansedLastLoadDate',
        @CleansedColumnsList AS 'CleansedColumnsList', 
        @CleansedColumnsTypeList AS 'CleansedColumnsTypeList',
        @CleansedColumnsFormatList AS 'CleansedColumnsFormatList',
        @PkAttributesList AS 'CleansedPkList',
        @PartitionByAttributesList AS 'CleansedPartitionFields',
        @DateTimeFolderHierarchy AS 'DateTimeFolderHierarchy'
    FROM 
        [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN 
        ingest.Connections AS cn
    ON  
        ds.ConnectionFK = cn.ConnectionId
    INNER JOIN 
        ingest.ComputeConnections AS cn2
    ON 
        ds.MergeComputeConnectionFK = cn2.ComputeConnectionId
    INNER JOIN
        ingest.Connections AS cn3
    ON 
        cn3.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        ingest.Connections AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        ingest.Connections AS cn5
    ON 
        cn5.ConnectionDisplayName = 'PrimaryDataLake' AND cn5.SourceLocation = 'raw'
    INNER JOIN
        ingest.Connections AS cn6
    ON 
        cn6.ConnectionDisplayName = 'PrimaryDataLake' AND cn6.SourceLocation = 'cleansed'
    WHERE
        ds.DatasetId = @DatasetId


END
GO