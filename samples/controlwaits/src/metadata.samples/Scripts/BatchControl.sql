-- Batches
EXEC [control].[AddBatches] 'Control', 'Control Demo Pipelines.', 1;

-- Stages
EXEC [control].[AddStages] 'Stage1', 1, 'Example first stage.', 1
EXEC [control].[AddStages] 'Stage2', 2, 'Example second stage.', 1
EXEC [control].[AddStages] 'Stage3', 3, 'Example third stage.', 1
EXEC [control].[AddStages] 'Stage4', 4, 'Example fourth stage.', 1

-- BatchStageLink
EXEC [control].[AddBatchStageLink] 'Control', 'Stage1'
EXEC [control].[AddBatchStageLink] 'Control', 'Stage2'
EXEC [control].[AddBatchStageLink] 'Control', 'Stage3'
EXEC [control].[AddBatchStageLink] 'Control', 'Stage4'

