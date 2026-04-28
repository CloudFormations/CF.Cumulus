-- Batches
EXEC [control].[AddBatches] 'ControlDemo', 'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1

-- Stages
EXEC [control].[AddStages] 'ControlRaw', 1, 'Demo of wait pipelines representing Raw load .', 0
EXEC [control].[AddStages] 'ControlCleansed', 2, 'Demo of wait pipelines representing cleansed load.', 0
EXEC [control].[AddStages] 'ControlCurated', 3, 'Demo of wait pipelines representing curated load.', 0
EXEC [control].[AddStages] 'ControlSpeed', 4, 'Demo of wait pipelines loading of frequently used data.', 0

-- BatchStageLink
EXEC [control].[AddBatchStageLink] 'ControlDemo', 'ControlRaw'
EXEC [control].[AddBatchStageLink] 'ControlDemo', 'ControlCleansed'
EXEC [control].[AddBatchStageLink] 'ControlDemo', 'ControlCurated'