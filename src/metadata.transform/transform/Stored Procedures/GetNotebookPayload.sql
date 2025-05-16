CREATE PROCEDURE [transform].[GetNotebookPayload]
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
        cn.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        [common].[Connections] AS cn2
    ON 
        cn2.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        [common].[Connections] AS cn3
    ON 
        cn3.ConnectionDisplayName = 'PrimaryDataLake' AND cn3.SourceLocation = 'curated'
    INNER JOIN
        [common].[Connections] AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimaryDataLake' AND cn4.SourceLocation = 'cleansed'
    INNER JOIN 
        [common].Connections AS cn5
    ON cn5.ConnectionDisplayName = 'PrimaryKeyVault'
    WHERE
        ds.DatasetId = @DatasetId

    IF @ResultRowCount = 0
    BEGIN
        RAISERROR('No results returned for the provided Dataset Id.  Confirm Dataset is enabled, and related Connections and Notebooks Parameters are enabled.',16,1)
        RETURN 0;
    END

    IF @ResultRowCount > 1
    BEGIN
        RAISERROR('Multiple results returned for the provided Dataset Id. Confirm that only a single active dataset is being referenced.',16,1)
        RETURN 0;
    END


    DECLARE @CuratedColumnsList NVARCHAR(MAX)
    DECLARE @CuratedColumnsTypeList NVARCHAR(MAX)

    DECLARE @BkAttributesList NVARCHAR(MAX) = ''
    DECLARE @PartitionByAttributesList NVARCHAR(MAX) = ''
    DECLARE @SurrogateKeyAttribute NVARCHAR(100) = ''

    DECLARE @DateTimeFolderHierarchy NVARCHAR(MAX)

    -- Get attribute data as comma separated string values for the dataset. This excludes the SurrogateKey.
    SELECT 
        @CuratedColumnsList = STRING_AGG(att.AttributeName,','),
        @CuratedColumnsTypeList = STRING_AGG(att.AttributeTargetDataType,',')
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
    IF @SurrogateKeyAttribute = ''
    BEGIN
        RAISERROR('No Surrogate Key Attribute specified for this dataset. Please ensure this is added to the transform.Attributes table, and specified in your bespoke notebook logic to populate the table.',16,1)
        RETURN 0;
    END

    -- Get Bk columns as comma separated string values for the dataset
    SELECT 
        @BkAttributesList = STRING_AGG(att.AttributeName,',')
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
        @PartitionByAttributesList = STRING_AGG(att.AttributeName,',')
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
            WHEN LoadType = 'F' THEN 'F'
            WHEN LoadType = 'I' AND LoadStatus = 0 THEN 'F'
            WHEN LoadType = 'I' AND LoadStatus <> 0 THEN 'I'
            ELSE 'X'
        END 
    FROM [transform].[Datasets]
    WHERE DatasetId = @DatasetId

    IF @LoadAction = 'X'
    BEGIN
        RAISERROR('Unexpected Load Type specified for Curated data load.',16,1)
        RETURN 0;
    END

    SELECT 
        [ccn].[ConnectionLocation] AS 'ComputeWorkspaceURL',
        [ccn].[ConnectionDisplayName] AS 'ComputeName',
        [ccn].[ComputeLocation] AS 'ComputeClusterId',
        [ccn].[ComputeSize],
        [ccn].[ComputeVersion],
        [ccn].[CountNodes],
        [ccn].[LinkedServiceName] AS 'ComputeLinkedServiceName',
        [ccn].[ResourceName] AS 'ComputeResourceName',
        [cn].[SourceLocation] AS 'ResourceGroupName',
        [cn2].[SourceLocation] AS 'SubscriptionId',
        [cn3].[ConnectionLocation] AS 'CuratedStorageName',
        [cn3].[SourceLocation] AS 'CuratedContainerName',
        [cn4].[ConnectionLocation] AS 'CleansedStorageName',
        [cn4].[SourceLocation] AS 'CleansedContainerName',
        [cn3].[Username] AS 'CuratedStorageAccessKey',
        [cn4].[Username] AS 'CleansedStorageAccessKey',
        [cn5].[ConnectionLocation] AS 'KeyVaultAddress',

        ds.DatasetName,
        ds.SchemaName,
        n2.NotebookPath AS 'BusinessLogicNotebookPath',
        n1.NotebookPath AS 'ExecutionNotebookPath',
        @CuratedColumnsList AS 'ColumnsList',
        @CuratedColumnsTypeList AS 'ColumnTypeList',
        @SurrogateKeyAttribute AS 'SurrogateKey',
        @BkAttributesList AS 'BkAttributesList',
        @PartitionByAttributesList AS 'PartitionByAttributesList',

        @LoadAction AS 'LoadType',
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
        cn.ConnectionDisplayName = 'PrimaryResourceGroup'
    INNER JOIN
        [common].[Connections] AS cn2
    ON 
        cn2.ConnectionDisplayName = 'PrimarySubscription'
    INNER JOIN
        [common].[Connections] AS cn3
    ON 
        cn3.ConnectionDisplayName = 'PrimaryDataLake' AND cn3.SourceLocation = 'curated'
    INNER JOIN
        [common].[Connections] AS cn4
    ON 
        cn4.ConnectionDisplayName = 'PrimaryDataLake' AND cn4.SourceLocation = 'cleansed'
    INNER JOIN 
        [common].Connections AS cn5
    ON cn5.ConnectionDisplayName = 'PrimaryKeyVault'
    WHERE
        ds.DatasetId = @DatasetId

END
