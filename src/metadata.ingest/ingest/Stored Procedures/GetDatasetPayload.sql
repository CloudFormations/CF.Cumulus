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
    [ingest].[Datasets] ds
    INNER JOIN [common].[Connections] cn1
        ON ds.[ConnectionFK] = cn1.[ConnectionId]
    INNER JOIN [common].[Connections] cn2
        ON cn2.[ConnectionDisplayName] = 'PrimaryDataLake' AND cn2.[SourceLocation] IN ('raw','bronze')
    INNER JOIN [common].[Connections] cn3
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
    DECLARE @Unpack BIT

    SELECT 
        @Unpack = CASE 
            WHEN LoadType = 'U' THEN 1 
            ELSE 0 
        END
    FROM [ingest].[Datasets]
    WHERE DatasetId = @DatasetId

    SET @LoadType = ingest.GetIngestLoadAction(@DatasetId, 'Raw')


    -- Set Source Language Type
    DECLARE @SourceLanguageType VARCHAR(15)
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

    DECLARE @SourceQuery VARCHAR(MAX) = ''

    -- Construct source query
    IF @SourceLanguageType = 'T-SQL'
    BEGIN
    SELECT
    @SourceQuery += ',' + [AttributeName]
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
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + QUOTENAME(ds.[SourcePath]) + '.' + QUOTENAME(ds.[SourceName])
        FROM 
            [ingest].[Datasets] AS ds
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
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + UPPER(ds.[SourcePath]) + '.' + UPPER(ds.[SourceName])
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1    
    END

    ELSE IF @SourceLanguageType = 'SOQL'
    BEGIN
    SELECT
    @SourceQuery += ',' + [AttributeName]
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
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + UPPER(ds.[SourceName])
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1    
    END

    ELSE IF @SourceLanguageType = 'SQL'
    BEGIN
    SELECT
        @SourceQuery += ',' + [AttributeName]
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
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + ds.[SourcePath]+ '.' + ds.[SourceName]
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId 
        AND 
            ds.[Enabled] = 1
    
    END

    ELSE IF @SourceLanguageType = 'WorkdayXML'
    BEGIN
        SELECT
        @SourceQuery = ds.LoadClause -- Keeps XML for Workday in Here for Full load. IN Future replace full load with incremental filter
        FROM
        [ingest].[Datasets] AS ds
            -- INNER JOIN [ingest].[Attributes] AS at
                --   ON ds.[DatasetId] = at.[DatasetFK]
            WHERE
                ds.DatasetId = @DatasetId
            AND 
                ds.[Enabled] = 1
    
    END

    ELSE IF @SourceLanguageType = 'XML'
    BEGIN
    DECLARE @LoadClause XML

    -- Start building the XML statement for the query
    SET @SourceQuery = '<fetch>'

    SELECT
    @SourceQuery += '<entity name="' + [SourceName] + '">'
    ,@LoadClause = LoadClause -- Unused if we're running a full load.
    FROM
    [ingest].[Datasets] AS ds
    WHERE
    ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1

    -- recursively add the attributes to load
    SELECT
    @SourceQuery += '<attribute name="' + [AttributeName] + '" />'
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

    IF (@LoadType = 'I')
    BEGIN
    DECLARE @Result DATETIME;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ParameterDef NVARCHAR(MAX);
    DECLARE @XmlValue NVARCHAR(MAX)

    SELECT @XmlValue = @LoadClause.value('(/filter/condition/@value)[1]', 'NVARCHAR(MAX)')

    -- Define the dynamic SQL query -- replace value of (/filter/condition/@value)[1]      with "Jun 20 2023 12:41PM"
    SET @SQL = N'SELECT @OutputResult = ' + @XmlValue;

    -- Define the parameter definition for the OUTPUT parameter
    SET @ParameterDef = N'@OutputResult DATETIME OUTPUT';

    -- Execute the dynamic SQL and save the result to the @Result variable
    EXEC sp_executesql @SQL, @ParameterDef, @OutputResult=@Result OUTPUT;

    -- Update the value in the XML variable
    SET @LoadClause.modify('replace value of (/filter/condition/@value)[1] with sql:variable("@Result")');


    SET @SourceQuery += CAST(@LoadClause AS nvarchar(MAX));

    END 
    SET @SourceQuery += '</entity></fetch>'
    END

    ELSE IF @SourceLanguageType = 'NA' AND @ConnectionType <> 'REST API'
    BEGIN
        SELECT 
            @SourceQuery = cn.SourceLocation + '/' + ds.SourcePath
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN [common].[Connections] AS cn
            ON ds.ConnectionFK = cn.ConnectionId
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    END

    ELSE IF @ConnectionType = 'REST API'
    BEGIN
        DECLARE @LoadClauseAPI NVARCHAR(MAX);
        DECLARE @LoadClauseAPIReplaced NVARCHAR(MAX);

        -- Define all your parameters and their corresponding values
        DECLARE @params TABLE (ParamName NVARCHAR(50), ParamValue NVARCHAR(30));

        INSERT INTO @params (ParamName, ParamValue)
        VALUES
        ('PARAMETER_GT_1_YEAR', CONVERT(NVARCHAR, DATEADD(YEAR, -1, GETUTCDATE()), 126)),
        ('PARAMETER_GT_1_MONTH', CONVERT(NVARCHAR, DATEADD(MONTH, -1, GETUTCDATE()), 126)),
        ('PARAMETER_GT_1_DAY', CONVERT(NVARCHAR, DATEADD(DAY, -1, GETUTCDATE()), 126)),
        ('PARAMETER_GT_1_HOUR', CONVERT(NVARCHAR, DATEADD(HOUR, -1, GETUTCDATE()), 126)),
        ('PARAMETER_NOW', CONVERT(NVARCHAR, GETUTCDATE(), 126)),
        ('PARAMETER_LT_1_YEAR', CONVERT(NVARCHAR, DATEADD(YEAR, 1, GETUTCDATE()), 126)),
        ('PARAMETER_LT_1_MONTH', CONVERT(NVARCHAR, DATEADD(MONTH, 1, GETUTCDATE()), 126)),
        ('PARAMETER_LT_1_DAY', CONVERT(NVARCHAR, DATEADD(DAY, 1, GETUTCDATE()), 126)),
        ('PARAMETER_LT_1_HOUR', CONVERT(NVARCHAR, DATEADD(HOUR, 1, GETUTCDATE()), 126));

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

    ELSE IF @Unpack = 1 AND  @SourceLanguageType = 'BIN'
    BEGIN
        SELECT
            @SourceQuery = ds.LoadClause
        FROM
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1
    END

    ELSE IF @Unpack = 0 AND  @SourceLanguageType = 'BIN'
    BEGIN
        SET @SourceQuery = ''
    END

    ELSE
    BEGIN
        RAISERROR('Connection Type / Language Type combination not supported.',16,1)
        RETURN 0;
    END

    IF (@LoadType = 'F')
    BEGIN
        SET @SourceQuery = @SourceQuery
        SET @LoadAction = 'full'
    END

    ELSE IF (@LoadType = 'I') AND (@ConnectionType = 'REST API')
    BEGIN
        SET @SourceQuery = @SourceQuery
        SET @LoadAction = 'incremental'
    END
 
	ELSE IF (@LoadType = 'I') AND (@ConnectionType = 'Files')
    BEGIN
        RAISERROR('The Files Connection type does not support incremental loading. Please change the load type in Ingest.datasets.',16,1)
        RETURN 0;
    END

    ELSE IF (@LoadType = 'I') AND (@SourceLanguageType <> 'XML') AND (@ConnectionType <> 'REST API')
    BEGIN
        SELECT 
            @SourceQuery = @SourceQuery + ' ' + ds.[LoadClause]
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId
        AND 
            ds.[Enabled] = 1

        SET @LoadAction = 'incremental'
    END

    ELSE IF (@LoadType = 'I') AND (@SourceLanguageType = 'XML')
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
        ds.[SourcePath],
        ds.[DatasetDisplayName],
        ds.[ExtensionType],
        cn1.*,
        cn2.[ConnectionLocation] AS 'TargetStorageName',
        cn2.[SourceLocation] AS 'TargetStorageContainer',
        cn3.[ConnectionLocation] AS 'KeyVaultBaseURL',
        @SourceQuery AS 'SourceQuery',
        @LoadType AS 'LoadType',
        @LoadAction AS LoadAction
    FROM 
        [ingest].[Datasets] ds
    INNER JOIN [common].[Connections] cn1
    ON ds.[ConnectionFK] = cn1.[ConnectionId]
    INNER JOIN [common].[Connections] cn2
    ON cn2.[ConnectionDisplayName] = 'PrimaryDataLake' AND cn2.[SourceLocation] IN ('raw','bronze')
    INNER JOIN [common].[Connections] cn3
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