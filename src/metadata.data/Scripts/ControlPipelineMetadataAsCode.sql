--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='SalesOrderHeader', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='SalesOrderHeader', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Dimension', @PipelineName='Transform_PL_managed', @DatasetDisplayName='DimDate', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Dimension', @PipelineName='Transform_PL_managed', @DatasetDisplayName='DimProducts', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Fact', @PipelineName='Transform_PL_managed', @DatasetDisplayName='FactSales', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';

--Pipeline Dependencies
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='SalesOrderHeader', @StageName='Raw', @DependantDatasetDisplayName='SalesOrderHeader', @DependantStageName='Cleansed';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='SalesOrderDetail', @StageName='Raw', @DependantDatasetDisplayName='SalesOrderDetail', @DependantStageName='Cleansed';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Product', @StageName='Raw', @DependantDatasetDisplayName='Product', @DependantStageName='Cleansed';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='Product', @StageName='Cleansed', @DependantDatasetDisplayName='DimProducts', @DependantStageName='Dimension';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='DimProducts', @StageName='Dimension', @DependantDatasetDisplayName='FactSales', @DependantStageName='Fact';
EXEC [common].[AddGenericPayloadPipelineDependencies] @DatasetDisplayName='DimDate', @StageName='Dimension', @DependantDatasetDisplayName='FactSales', @DependantStageName='Fact';


