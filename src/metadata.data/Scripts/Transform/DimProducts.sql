--Metadata As code Transform Datasets and Attributes

-- Notebooks
EXEC [transform].[AddNotebooks] 'CF.Cumulus.Transform.Compute', 'Managed', 'DimProducts', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimProducts', 1;

-- Datasets;
EXEC [transform].[AddTransformDatasets]
	@CreateNotebookName = 'CreateDim',
	@BusinessLogicName = 'DimProducts',
	@CleansedConnectionDisplayName = 'PrimaryDataLake',
	@CleansedSourceLocation = 'cleansed',
	@CuratedConnectionDisplayName = 'PrimaryDataLake',
	@CuratedSourceLocation = 'curated',
	@DomainName = 'Demo',
	@SchemaName = 'Dim',
	@DatasetName ='Products',
	@VersionNumber =1,
	@VersionValidFrom ='2026-01-01',
	@VersionValidTo =NULL,
	@LoadType = 'F',
	@LoadStatus = 0,
	@LastLoadDate = NULL,
	@Enabled =1


-- Attributes;
EXEC [transform].[AddTransformAttributes] 'Products', 'Dim', 'ProductSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Products', 'Dim', 'ProductKey', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Products', 'Dim', 'ProductName', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Products', 'Dim', 'ProductColour', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Products', 'Dim', 'ProductSize', 'STRING', '', 0, 0, 0, 1;
