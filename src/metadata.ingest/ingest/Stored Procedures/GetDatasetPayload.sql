CREATE PROCEDURE [ingest].[GetDatasetPayload]
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
    [ingest].[DatasetsLatestVersion] ds
    INNER JOIN [ingest].[Connections] cn1
        ON ds.[ConnectionFK] = cn1.[ConnectionId]
    INNER JOIN [ingest].[Connections] cn2
        ON cn2.[ConnectionDisplayName] = 'PrimaryDataLake' AND cn2.[SourceLocation] = 'raw'
    INNER JOIN [ingest].[Connections] cn3
        ON cn3.[ConnectionDisplayName] = 'PrimaryKeyVault'
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
        RAISERROR('No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections are enabled.',16,1)
    RETURN 0;
    END


    -- Set LoadType conditions
    DECLARE @LoadType CHAR(1)
    DECLARE @LoadAction VARCHAR(12)

    SET @LoadType = ingest.GetIngestLoadAction(@DatasetId, 'Raw')


    -- Set Source Language Type
    DECLARE @SourceLanguageType VARCHAR(5)

    SELECT 
        @SourceLanguageType = ct.[SourceLanguageType]
    FROM [ingest].[ConnectionTypes] AS ct
    INNER JOIN [ingest].[Connections] AS cn
        ON ct.ConnectionTypeId = cn.ConnectionTypeFK
    INNER JOIN [ingest].[DatasetsLatestVersion] AS ds
        ON cn.ConnectionId = ds.ConnectionFK
    WHERE 
        ds.DatasetId = @DatasetId
    AND 
        ds.[Enabled] = 1
    AND 
        ct.[Enabled] = 1
    AND 
        cn.[Enabled] = 1

    DECLARE @SourceQuery VARCHAR(MAX) = ''

    -- Construct source query
    IF @SourceLanguageType = 'T-SQL'
    BEGIN
    SELECT
    @SourceQuery += ',' + [AttributeName]
    FROM
    [ingest].[DatasetsLatestVersion] AS ds
        INNER JOIN [ingest].[Attributes] AS at
            ON ds.[DatasetId] = at.[DatasetFK]
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    AND 
    at.Enabled = 1

    SELECT 
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + QUOTENAME(ds.[SourcePath]) + '.' + QUOTENAME(ds.[SourceName])
        FROM 
            [ingest].[DatasetsLatestVersion] AS ds
        WHERE
            ds.DatasetId = @DatasetId 
        AND 
            ds.[Enabled] = 1
    END

    ELSE IF @SourceLanguageType = 'PSQL'
    BEGIN
    SELECT
    @SourceQuery += ',' + [AttributeName]
    FROM
    [ingest].[DatasetsLatestVersion] AS ds
        INNER JOIN [ingest].[Attributes] AS at
            ON ds.[DatasetId] = at.[DatasetFK]
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    AND 
    at.Enabled = 1

    SELECT 
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + UPPER(ds.[SourcePath]) + '.' + UPPER(ds.[SourceName])
        FROM 
            [ingest].[DatasetsLatestVersion] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1    
    END

    -- Logic not required/built yet.
    ELSE IF @SourceLanguageType = 'SQL'
    BEGIN
        SET @SourceQuery = @SourceQuery
    END

    ELSE IF @SourceLanguageType = 'XML'
    BEGIN
    DECLARE @CDCWhereClause XML

    -- Start building the XML statement for the query
    SET @SourceQuery = '<fetch>'

    SELECT
    @SourceQuery += '<entity name="' + [SourceName] + '">'
    ,@CDCWhereClause = CDCWhereClause -- Unused if we're running a full load.
    FROM
    [ingest].[DatasetsLatestVersion] AS ds
    WHERE
    ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1

    -- recursively add the attributes to load
    SELECT
    @SourceQuery += '<attribute name="' + [AttributeName] + '" />'
    FROM
    [ingest].[DatasetsLatestVersion] AS ds
    INNER JOIN [ingest].[Attributes] AS at
    ON ds.[DatasetId] = at.[DatasetFK]
    WHERE
    ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    AND 
    at.Enabled = 1

    IF (@LoadType = 'I')
    BEGIN
    DECLARE @Result DATETIME;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ParameterDef NVARCHAR(MAX);
    DECLARE @XmlValue NVARCHAR(MAX)

    SELECT @XmlValue = @CDCWhereClause.value('(/filter/condition/@value)[1]', 'NVARCHAR(MAX)')

    -- Define the dynamic SQL query -- replace value of (/filter/condition/@value)[1]      with "Jun 20 2023 12:41PM"
    SET @SQL = N'SELECT @OutputResult = ' + @XmlValue;

    -- Define the parameter definition for the OUTPUT parameter
    SET @ParameterDef = N'@OutputResult DATETIME OUTPUT';

    -- Execute the dynamic SQL and save the result to the @Result variable
    EXEC sp_executesql @SQL, @ParameterDef, @OutputResult=@Result OUTPUT;

    -- Update the value in the XML variable
    SET @CDCWhereClause.modify('replace value of (/filter/condition/@value)[1] with sql:variable("@Result")');


    SET @SourceQuery += CAST(@CDCWhereClause AS nvarchar(MAX));

    END 
    SET @SourceQuery += '</entity></fetch>'
    END

    ELSE IF @SourceLanguageType = 'NA'
    BEGIN
        SELECT 
            @SourceQuery = cn.SourceLocation + '/' + ds.SourcePath
        FROM 
            [ingest].[DatasetsLatestVersion] AS ds
        INNER JOIN [ingest].[Connections] AS cn
            ON ds.ConnectionFK = cn.ConnectionId
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    END
    ELSE
    BEGIN
    RAISERROR('Language Type not supported.',16,1)
    RETURN 0;
    END

    IF (@LoadType = 'F')
    BEGIN
    SET @SourceQuery = @SourceQuery
            SET @LoadAction = 'full'
    END
    ELSE IF (@LoadType = 'I') AND @SourceLanguageType <> 'XML'
    BEGIN
    SELECT 
                @SourceQuery = @SourceQuery + ' ' + ds.[CDCWhereClause]
            FROM 
                [ingest].[DatasetsLatestVersion] AS ds
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1

            SET @LoadAction = 'incremental'
    END
    ELSE IF (@LoadType = 'I') AND @SourceLanguageType = 'XML'
    BEGIN
    SET @SourceQuery = @SourceQuery
            SET @LoadAction = 'incremental'
    END
    --ELSE IF @LoadType = 'FW'
    --ELSE IF @LoadType = 'H'
    ELSE
    BEGIN
    RAISERROR('Load type condition not yet supported.',16,1);
    RETURN 0;
    END

    IF @SourceLanguageType IN ('T-SQL', 'PSQL', 'SQL')
    BEGIN
    SET @SourceQuery = @SourceQuery + ';'
    END

    SELECT
    RIGHT('0000' + CAST(ds.[VersionNumber] AS VARCHAR),4) AS 'VersionNumber',
    ds.[SourceName],
    ds.[DatasetDisplayName],
    ds.[ExtensionType],
    cn1.*,
    cn2.[ConnectionLocation] AS 'TargetStorageName',
    cn2.[SourceLocation] AS 'TargetStorageContainer',
    cn3.[ConnectionLocation] AS 'KeyVaultBaseURL',

    @SourceQuery AS 'SourceQuery',
        @LoadType AS 'LoadType',
        @LoadAction AS LoadAction
    --'SELECT * FROM ' + QUOTENAME(ds.[SourcePath]) + '.' + QUOTENAME(ds.[SourceName]) AS 'SourceQuery'
    FROM
    [ingest].[DatasetsLatestVersion] ds
    INNER JOIN [ingest].[Connections] cn1
    ON ds.[ConnectionFK] = cn1.[ConnectionId]
    INNER JOIN [ingest].[Connections] cn2
    ON cn2.[ConnectionDisplayName] = 'PrimaryDataLake' AND cn2.[SourceLocation] = 'raw'
    INNER JOIN [ingest].[Connections] cn3
    ON cn3.[ConnectionDisplayName] = 'PrimaryKeyVault'
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
GO


