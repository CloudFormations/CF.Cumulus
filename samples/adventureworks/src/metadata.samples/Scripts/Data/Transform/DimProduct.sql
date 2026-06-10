--Metadata As code Transform Datasets and Attributes
BEGIN TRY
-- Notebooks
EXEC [transform].[AddNotebooks] 'CF.Cumulus.Ingest.Compute', 'Managed', 'DimProduct', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimProduct', 1;

-- Datasets;
EXEC [transform].[AddTransformDatasets]
	@CreateNotebookName = 'CreateDim',
	@BusinessLogicName = 'DimProduct',
	@CleansedConnectionDisplayName = 'PrimaryDataLake',
	@CleansedSourceLocation = 'cleansed',
	@CuratedConnectionDisplayName = 'PrimaryDataLake',
	@CuratedSourceLocation = 'curated',
	@DomainName = 'Demo',
	@SchemaName = 'Dim',
	@DatasetName ='Product',
	@VersionNumber =1,
	@VersionValidFrom ='2026-01-01',
	@VersionValidTo =NULL,
	@LoadType = 'F',
	@LoadStatus = 0,
	@LastLoadDate = NULL,
	@Enabled =1


-- Attributes;
EXEC [transform].[AddTransformAttributes] 'Product', 'Dim', 'ProductSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Product', 'Dim', 'ProductKey', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Product', 'Dim', 'ProductName', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Product', 'Dim', 'ProductColour', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Product', 'Dim', 'ProductSize', 'STRING', '', 0, 0, 0, 1;

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Dimension', @PipelineName='Transform_PL_Managed', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';

--Pipeline Dependencies
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Product', @StageName='Cleansed', @DependantDatasetDisplayName='Product', @DependantStageName='Dimension';

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' + 'Error in dataset [DimProduct]: ' + ERROR_MESSAGE() + ' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH