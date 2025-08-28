
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
        cn3.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        [common].Connections AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        [common].Connections AS cn5
    ON 
        cn5.ConnectionDisplayName = 'PrimaryDataLake' AND cn5.SourceLocation IN ('raw','bronze')
    INNER JOIN
        [common].Connections AS cn6
    ON 
        cn6.ConnectionDisplayName = 'PrimaryDataLake' AND cn6.SourceLocation IN ('cleansed', 'silver')

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
        RAISERROR('No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections and Attributes are enabled.',16,1)
        RETURN 0;
    END


    DECLARE @CleansedColumnsList NVARCHAR(MAX)
    DECLARE @CleansedColumnsTypeList NVARCHAR(MAX)
    DECLARE @CleansedColumnsFormatList NVARCHAR(MAX)
    DECLARE @CleansedUnpackList NVARCHAR(MAX)

    DECLARE @PkAttributesList NVARCHAR(MAX) = ''
    DECLARE @PartitionByAttributesList NVARCHAR(MAX) = ''

    DECLARE @DateTimeFolderHierarchy NVARCHAR(1000)

    -- Get attribute data as comma separated string values for the dataset
    SELECT 
        @CleansedColumnsList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),','),
        @CleansedColumnsTypeList = STRING_AGG(CAST(att.AttributeTargetDataType AS NVARCHAR(MAX)),','),
        @CleansedColumnsFormatList = STRING_AGG(CAST(att.AttributeTargetDataFormat AS NVARCHAR(MAX)), ',')
        @CleansedUnpackList = STRING_AGG(CAST(att.AttributeUnpack AS NVARCHAR(MAX)), ',')
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
        @PkAttributesList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),',')
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
        @PkAttributesList = STRING_AGG(CAST(att.AttributeName AS NVARCHAR(MAX)),',')
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

    SELECT @LoadAction = ingest.GetIngestLoadAction(@DatasetId, 'Cleansed')
    IF @LoadAction = 'F'
        SELECT 
            @RawLastLoadDate = RawLastFullLoadDate,
            @CleansedLastLoadDate = CleansedLastFullLoadDate
        FROM 
            [ingest].[Datasets] AS ds
        WHERE 
            ds.[DatasetId] = @DatasetId
        AND 
            ds.[Enabled] = 1
    ELSE IF @LoadAction = 'I'
        SELECT 
            @RawLastLoadDate = RawLastIncrementalLoadDate,
            @CleansedLastLoadDate = CleansedLastIncrementalLoadDate
        FROM 
            [ingest].[Datasets] AS ds
        WHERE 
            ds.[DatasetId] = @DatasetId
        AND 
            ds.[Enabled] = 1

    ELSE IF @LoadAction = 'X'
    BEGIN
        RAISERROR('Erroneous Load Status. Review the ingest LoadStatus value for the dataset in [ingest].[Datasets]',16,1)
        RETURN 0;
    END
    ELSE
    BEGIN
        RAISERROR('Unexpected Load action. Review the ingest LoadStatus value for the dataset in [ingest].[Datasets]',16,1)
        RETURN 0;
    END
    SELECT 
        @DateTimeFolderHierarchy = 'year=' + CAST(FORMAT(@RawLastLoadDate,'yyyy') AS VARCHAR) + '/' + 
        'month=' + CAST(FORMAT(@RawLastLoadDate,'MM') AS VARCHAR) + '/' + 
        'day=' + CAST(FORMAT(@RawLastLoadDate,'dd') AS VARCHAR) + '/' + 
        'hour=' + CAST(FORMAT(@RawLastLoadDate,'HH') AS VARCHAR) 
    FROM 
        [ingest].[Datasets] AS ds
    WHERE
        ds.DatasetId = @DatasetId
    AND 
        ds.[Enabled] = 1

    SELECT 
        [cn].[ConnectionDisplayName] AS 'RawSchemaName',
        [cn2].[ConnectionDisplayName] AS 'ComputeName',
        [cn2].[ConnectionLocation] AS 'ComputeWorkspaceURL',
        [cn2].[ComputeLocation] AS 'ComputeClusterId',
        [cn2].[ComputeSize] AS 'ComputeSize',
        [cn2].[ComputeVersion] AS 'ComputeVersion',
        [cn2].[CountNodes] AS 'CountNodes',
        [cn2].[LinkedServiceName] AS 'ComputeLinkedServiceName',
        [cn2].[ResourceName] AS 'ComputeResourceName',
        [cn3].[SourceLocation] AS 'ResourceGroupName',
        [cn4].[SourceLocation] AS 'SubscriptionId',
        [cn5].[ConnectionLocation] AS 'RawStorageName',
        [cn5].[SourceLocation] AS 'RawContainerName',
        [cn6].[ConnectionLocation] AS 'CleansedStorageName',
        [cn6].[SourceLocation] AS 'CleansedContainerName',
        [cn5].[Username] AS 'RawStorageAccessKey',
        [cn6].[Username] AS 'CleansedStorageAccessKey',
        [cn7].[ConnectionLocation] AS 'KeyVaultAddress',

        ds.DatasetDisplayName,
        ds.SourcePath,
        ds.SourceName,
        ds.ExtensionType AS 'RawFileType',
        ds.VersionNumber,
        [cn].[ConnectionDisplayName] AS 'CleansedSchemaName',
        ds.CleansedName AS 'CleansedTableName',
        ds.Enabled,
        ds.LoadType,
        @LoadAction AS 'LoadAction',
        @RawLastLoadDate AS 'RawLastLoadDate',
        @CleansedLastLoadDate AS 'CleansedLastLoadDate',
        @CleansedColumnsList AS 'CleansedColumnsList', 
        @CleansedColumnsTypeList AS 'CleansedColumnsTypeList',
        @CleansedColumnsFormatList AS 'CleansedColumnsFormatList',
        @CleansedUnpackList AS 'CleansedUnpackList',
        @PkAttributesList AS 'CleansedPkList',
        @PartitionByAttributesList AS 'CleansedPartitionFields',
        @DateTimeFolderHierarchy AS 'DateTimeFolderHierarchy'
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
        cn3.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        [common].Connections AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        [common].Connections AS cn5
    ON 
        cn5.ConnectionDisplayName = 'PrimaryDataLake' AND cn5.SourceLocation IN ('raw','bronze')
    INNER JOIN
        [common].Connections AS cn6
    ON 
        cn6.ConnectionDisplayName = 'PrimaryDataLake' AND cn6.SourceLocation IN ('cleansed','silver')
    INNER JOIN 
        [common].Connections AS cn7
    ON cn7.ConnectionDisplayName = 'PrimaryKeyVault'
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