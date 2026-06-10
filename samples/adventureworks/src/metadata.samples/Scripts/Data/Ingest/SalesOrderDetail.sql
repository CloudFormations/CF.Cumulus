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
    @DatasetDisplayName = 'SalesOrderDetail',
    @SourcePath = 'SalesLT',
    @SourceName = 'SalesOrderDetail',
    @ExtensionType = 'parquet',
    @VersionNumber = 1,
    @VersionValidFrom = '2025-01-01 00:00:00.0000000',
    @VersionValidTo = NULL,
    @LoadType = 'I',
    @LoadStatus = 0,
    @OverrideLoadStatus = 0,
    @LoadClause = 'WHERE ModifiedDate > GETDATE() - 7',
    @CleansedPath = 'SalesLT',
    @CleansedName = 'SalesOrderDetail',
    @Enabled = 1

--Attributes for SalesOrderDetail
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderDetailID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'OrderQty', 'smallint', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ProductID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPriceDiscount', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'LineTotal', 'numeric', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';

--Pipeline Dependencies
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='SalesOrderDetail', @StageName='Raw', @DependantDatasetDisplayName='SalesOrderDetail', @DependantStageName='Cleansed';


END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' + 'Error in dataset [SalesOrderDetail]: ' + ERROR_MESSAGE() + ' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH