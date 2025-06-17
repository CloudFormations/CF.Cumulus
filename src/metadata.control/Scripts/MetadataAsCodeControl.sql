--Metadata As Code Control

-- Add batches, stages and the links between them to the metadata control table.
EXEC [control].[AddStages] 'Raw', 'Extract/Ingest all data from source systems.', 1
EXEC [control].[AddStages] 'Cleansed', 'Merge Raw data into Delta Tables.', 1
EXEC [control].[AddStages] 'Dimension', 'Transform cleansed data and apply business logic for Dimensions.', 1
EXEC [control].[AddStages] 'Fact', 'Transform cleansed data and apply business logic for Facts.', 1
EXEC [control].[AddStages] 'Speed', 'Regular loading of frequently used data.', 0
EXEC [control].[AddStages] 'ControlRaw', 'Demo of wait pipelines representing Raw load .', 0
EXEC [control].[AddStages] 'ControlCleansed', 'Demo of wait pipelines representing cleansed load.', 0
EXEC [control].[AddStages] 'ControlSpeed', 'Demo of wait pipelines loading of frequently used data.', 0

EXEC [control].[AddBatches] 'ControlDemoHourly', 'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1
EXEC [control].[AddBatches] 'Hourly', 'Hourly Worker Pipelines.', 1
EXEC [control].[AddBatches] 'Daily', 'Daily Worker Pipelines.', 1
EXEC [control].[AddBatches] 'ControlDemoDaily', 'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1

EXEC [control].[AddBatchStageLink] 'ControlDemoHourly', 'ControlSpeed'
EXEC [control].[AddBatchStageLink] 'Hourly', 'Speed'
EXEC [control].[AddBatchStageLink] 'Daily', 'Raw'
EXEC [control].[AddBatchStageLink] 'Daily', 'Cleansed'
EXEC [control].[AddBatchStageLink] 'Daily', 'Dimension'
EXEC [control].[AddBatchStageLink] 'Daily', 'Fact'
EXEC [control].[AddBatchStageLink] 'ControlDemoDaily', 'ControlRaw'
EXEC [control].[AddBatchStageLink] 'ControlDemoDaily', 'ControlCleansed'

-- Add tenants to the metadata control table.
EXEC [control].[AddTenants] '$(TenantID)', 'Default', 'Example value for $(Environment) environment.'

-- Add Subscriptions to the metadata control table.
EXEC [control].[AddSubscriptions] '$(SubscriptionID)', 'Default', 'Example value for $(Environment) environment.', '$(TenantID)'

-- Add Orchestrators to the metadata control table.
EXEC [control].[AddOrchestrators] '$(ADFName)', 'ADF', 1, '$(RGName)', '$(SubscriptionID)', 'Example Data Factory used for $(Environment).'