-- Batches
EXEC [control].[AddBatches] 'Daily', 'Daily Worker Pipelines.', 1;

-- Stages
EXEC [control].[AddStages] 'Raw', 1, 'Extract/Ingest all data from source systems.', 1
EXEC [control].[AddStages] 'Cleansed', 2, 'Merge Raw data into Delta Tables.', 1
EXEC [control].[AddStages] 'Dimension', 3, 'Transform cleansed data and apply business logic for Dimensions.', 1
EXEC [control].[AddStages] 'Fact', 4, 'Transform cleansed data and apply business logic for Facts.', 1

-- BatchStageLink
EXEC [control].[AddBatchStageLink] 'Daily', 'Raw'
EXEC [control].[AddBatchStageLink] 'Daily', 'Cleansed'
EXEC [control].[AddBatchStageLink] 'Daily', 'Dimension'
EXEC [control].[AddBatchStageLink] 'Daily', 'Fact'

