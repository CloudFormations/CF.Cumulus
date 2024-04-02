CREATE PROCEDURE [ingest].[GetDatasetPayload]
	(
	@DatasetId INT
	)
AS
BEGIN
	
    -- Set Source Language Type

    DECLARE @SourceLanguageType VARCHAR(5)

    SELECT 
        @SourceLanguageType = ct.[SourceLanguageType]
    FROM [ingest].[ConnectionTypes] AS ct
    INNER JOIN [ingest].[Connections] AS cn
        ON ct.ConnectionTypeId = cn.ConnectionTypeFK
    INNER JOIN [ingest].[Datasets] AS ds
        ON cn.ConnectionId = ds.ConnectionFK
    WHERE 
        ds.DatasetId = @DatasetId

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


		SELECT 
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + QUOTENAME(ds.[SourcePath]) + '.' + QUOTENAME(ds.[SourceName])
        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId


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


		SELECT 
            @SourceQuery = 'SELECT ' + STUFF(@SourceQuery,1,1,'') + ' FROM ' + UPPER(ds.[SourcePath]) + '.' + UPPER(ds.[SourceName]) + ';'


        FROM 
            [ingest].[Datasets] AS ds
        WHERE
            ds.DatasetId = @DatasetId


	END
    ELSE IF @SourceLanguageType = 'SQL'
    BEGIN
        SELECT @SourceQuery = @SourceQuery
    END
    ELSE IF @SourceLanguageType = 'NA'
    BEGIN
        SELECT 
            @SourceQuery = cn.SourceLocation + '/' + ds.SourcePath
        FROM 
            [ingest].[Datasets] AS ds
        INNER JOIN [ingest].[Connections] AS cn
            ON ds.ConnectionFK = cn.ConnectionId
        WHERE
            ds.DatasetId = @DatasetId
    END
	ELSE
		RAISERROR('Not supported',1,16)



	SELECT
		RIGHT('0000' + CAST(ds.[VersionNumber] AS VARCHAR),4) AS 'VersionNumber',
		ds.[SourceName],
		ds.[DatasetDisplayName],
		cn1.*,
		cn2.[ConnectionLocation] AS 'TargetStorageName',
		cn2.[SourceLocation] AS 'TargetStorageContainer',
		cn3.[ConnectionLocation] AS 'KeyVaultBaseURL',
		
		@SourceQuery AS 'SourceQuery'
		--'SELECT * FROM ' + QUOTENAME(ds.[SourcePath]) + '.' + QUOTENAME(ds.[SourceName]) AS 'SourceQuery'
	FROM
		[ingest].[Datasets] ds
		INNER JOIN [ingest].[Connections] cn1
			ON ds.[ConnectionFK] = cn1.[ConnectionId]
		INNER JOIN [ingest].[Connections] cn2
			ON cn2.[ConnectionDisplayName] = 'PrimaryDataLake'
		INNER JOIN [ingest].[Connections] cn3
			ON cn3.[ConnectionDisplayName] = 'PrimaryKeyVault'
	WHERE
		[DatasetId] = @DatasetId

END
GO


