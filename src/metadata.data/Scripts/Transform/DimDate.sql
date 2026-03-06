--Metadata As code Transform Datasets and Attributes

-- Notebooks
EXEC [transform].[AddNotebooks] 'Managed', 'DimDate', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimDate', 1;

-- Datasets;
EXEC [transform].[AddTransformDatasets]
	@ComputeConnectionDisplayName = 'CF.Cumulus.Transform.Compute',
	@CreateNotebookName = 'CreateDim',
	@BusinessLogicName = 'DimDate',
	@CleansedConnectionDisplayName = 'PrimaryDataLake',
	@CleansedSourceLocation = 'cleansed',
	@CuratedConnectionDisplayName = 'PrimaryDataLake',
	@CuratedSourceLocation = 'curated',
	@DomainName = 'Demo',
	@SchemaName = 'Dim',
	@DatasetName ='Date',
	@VersionNumber =1,
	@VersionValidFrom ='2026-01-01',
	@VersionValidTo =NULL,
	@LoadType = 'F',
	@LoadStatus = 0,
	@LastLoadDate = NULL,
	@Enabled =1

-- Attributes;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'DateSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'Date', 'DATE', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'DateKey', 'INT', '', 1, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'DayName', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'DayOfMonth', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'MonthName', 'STRING', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'Quarter', 'INT', '', 0, 0, 0, 1;
EXEC [transform].[AddTransformAttributes] 'Date', 'Dim', 'Year', 'INT', '', 0, 0, 0, 1;