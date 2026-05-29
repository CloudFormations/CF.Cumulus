--Metadata As code Transform Datasets and Attributes
DECLARE @DatasetName NVARCHAR(255) = 'FactSales';

BEGIN TRY
-- Notebooks
EXEC [transform].[AddNotebooks] 'CF.Cumulus.Ingest.Compute', 'Managed', 'FactSales', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/FactSales', 1;

-- Datasets;

EXEC [transform].[AddTransformDatasets]
	@CreateNotebookName = 'CreateFact',
	@BusinessLogicName = 'FactSales',
	@CleansedConnectionDisplayName = 'PrimaryDataLake',
	@CleansedSourceLocation = 'cleansed',
	@CuratedConnectionDisplayName = 'PrimaryDataLake',
	@CuratedSourceLocation = 'curated',
	@DomainName = 'Demo',
	@SchemaName = 'Fact',
	@DatasetName ='Sales',
	@VersionNumber =1,
	@VersionValidFrom ='2026-01-01',
	@VersionValidTo =NULL,
	@LoadType = 'F',
	@LoadStatus = 0,
	@LastLoadDate = NULL,
	@Enabled =1

-- Attributes;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SaleSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SalesOrderKey', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SalesOrderDetailKey', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'OrderDateSK', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'DueDateSK', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'ShipDateSK', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'ProductSK', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'ProductOrderQuantity', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'UnitPrice', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'LineTotal', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SaleLineTotalAmount', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SaleOrderTotalAmount', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Sales', 'Fact', 'SaleOrderShippingTotalAmount', 'INT', '', 0, 0, 0, 1;


--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Fact', @PipelineName='Transform_PL_Managed', @DatasetDisplayName='Sales', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';

--Pipeline Dependencies
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Product', @StageName='Dimension', @DependantDatasetDisplayName='Sales', @DependantStageName='Fact';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Date', @StageName='Dimension', @DependantDatasetDisplayName='Sales', @DependantStageName='Fact';


END TRY
BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(MAX) =
        'Error in dataset [' + @DatasetName + ']: ' + ERROR_MESSAGE() +
        ' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')';
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' + @ErrorMsg + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH