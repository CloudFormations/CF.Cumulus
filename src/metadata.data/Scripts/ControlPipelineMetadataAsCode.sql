--Metadata as Code for Control Pipelines

--Pipelines
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='SalesOrderHeader', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Raw', @PipelineName='Ingest_PL_MSSQL', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='SalesOrderHeader', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='SalesOrderDetail', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Cleansed', @PipelineName='Ingest_PL_Merge', @DatasetDisplayName='Product', @OrchestratorName='$(ADFName)', @ComponentName = 'Ingest';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Curated', @PipelineName='Transform_PL_Unmanaged', @DatasetDisplayName='DimDate', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Curated', @PipelineName='Transform_PL_Unmanaged', @DatasetDisplayName='DimProducts', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';
EXEC [common].[AddIngestOrTransformPayloadPipeline] @StageName='Serve', @PipelineName='Transform_PL_Unmanaged', @DatasetDisplayName='FactSales', @OrchestratorName='$(ADFName)', @ComponentName = 'Transform';

--Pipeline Dependencies
EXEC [ingest].[AddIngestPayloadPipelineDependencies] @DatasetDisplayName='SalesOrderHeader';
EXEC [ingest].[AddIngestPayloadPipelineDependencies] @DatasetDisplayName='SalesOrderDetail';
EXEC [ingest].[AddIngestPayloadPipelineDependencies] @DatasetDisplayName='Product';

EXEC [transform].[AddTransformPayloadPipelineDependencies] @DatasetDisplayName='DimDate';
EXEC [transform].[AddTransformPayloadPipelineDependencies] @DatasetDisplayName='DimProducts';
EXEC [transform].[AddTransformPayloadPipelineDependencies] @DatasetDisplayName='FactSales';