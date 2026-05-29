--Metadata As code Transform Datasets and Attributes
DECLARE @DatasetName NVARCHAR(255) = 'DimDate';

BEGIN TRY
-- Notebooks
EXEC [transform].[AddNotebooks] 'CF.Cumulus.Ingest.Compute', 'Managed', 'DimDate', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimDate', 1;

-- Datasets;
EXEC [transform].[AddTransformDatasets]
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


--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Dimension', @PipelineName='Transform_PL_Managed', @DatasetDisplayName='Date', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';

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