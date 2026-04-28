-- Batches
EXEC [control].[AddBatches] 'Hourly', 'Hourly Worker Pipelines.', 1;

-- Stages
EXEC [control].[AddStages] 'HourlyRaw', 1, 'Extract/Ingest all data from source systems.', 1
EXEC [control].[AddStages] 'HourlyCleansed', 2, 'Merge Raw data into Delta Tables.', 1
EXEC [control].[AddStages] 'HourlyDimension', 3, 'Transform cleansed data and apply business logic for Dimensions.', 1
EXEC [control].[AddStages] 'HourlyFact', 4, 'Transform cleansed data and apply business logic for Facts.', 1

-- BatchStageLink
EXEC [control].[AddBatchStageLink] 'Hourly', 'HourlyRaw';
EXEC [control].[AddBatchStageLink] 'Hourly', 'HourlyCleansed';
EXEC [control].[AddBatchStageLink] 'Hourly', 'HourlyDimension';
EXEC [control].[AddBatchStageLink] 'Hourly', 'HourlyFact';