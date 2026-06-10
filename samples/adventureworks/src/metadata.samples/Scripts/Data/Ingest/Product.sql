-- Metadata As Code - Ingest - add sample Datasets

BEGIN TRY

--Datasets:
EXEC [ingest].[AddDatasets] 
    @ConnectionDisplayName = 'AdventureWorksDemo',
    @LinkedServiceName = 'Ingest_LS_SQLDB_MIAuth',
    @ResourceName = '$(AdventureWorksDatabaseName)',
    @ComputeConnectionDisplayName = 'CF.Cumulus.Ingest.Compute',
    @RawConnectionDisplayName = 'PrimaryDataLake',
    @RawSourceLocation = 'Raw',
    @CleansedConnectionDisplayName = 'PrimaryDataLake',
    @CleansedSourceLocation = 'Cleansed',
    @DatasetDisplayName = 'Product',
    @SourcePath = 'SalesLT',
    @SourceName = 'Product',
    @ExtensionType = 'parquet',
    @VersionNumber = 1,
    @VersionValidFrom = '2025-01-01 00:00:00.0000000',
    @VersionValidTo = NULL,
    @LoadType = 'I',
    @LoadStatus = 0,
    @OverrideLoadStatus = 0,
    @LoadClause = 'WHERE ModifiedDate > GETDATE() - 7',
    @CleansedPath = 'SalesLT',
    @CleansedName = 'Product',
    @Enabled = 1


--Attributes for Product
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Name', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductNumber', 'nvarchar(25)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Color', 'nvarchar(15)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'StandardCost', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ListPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Size', 'nvarchar(5)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Weight', 'decimal(8,2)', 'FLOAT', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductCategoryID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductModelID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'SellStartDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'SellEndDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'DiscontinuedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ThumbNailPhoto', 'varbinary', 'BINARY', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ThumbnailPhotoFileName', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';

--Pipeline Dependencies
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Product', @StageName='Raw', @DependantDatasetDisplayName='Product', @DependantStageName='Cleansed';

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' + 'Error in dataset [Product]: ' + ERROR_MESSAGE() + ' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH