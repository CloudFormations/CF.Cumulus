--Metadata As Code Control

-- Add batches, stages and the links between them to the metadata control table.
EXEC ##AddStages 'Raw', 'Extract/Ingest all data from source systems.', 1
EXEC ##AddStages 'Cleansed', 'Merge Raw data into Delta Tables.', 1
EXEC ##AddStages 'Curated', 'Transform cleansed data and apply business logic.', 1
EXEC ##AddStages 'Serve', 'Load Curated data into semantic layer.', 1
EXEC ##AddStages 'Speed', 'Regular loading of frequently used data.', 0
EXEC ##AddStages 'ControlRaw', 'Demo of wait pipelines representing Raw load .', 0
EXEC ##AddStages 'ControlCleansed', 'Demo of wait pipelines representing cleansed load.', 0
EXEC ##AddStages 'ControlSpeed', 'Demo of wait pipelines loading of frequently used data.', 0

EXEC ##AddBatches 'ControlDemoHourly', 'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1
EXEC ##AddBatches 'Hourly', 'Hourly Worker Pipelines.', 1
EXEC ##AddBatches 'Daily', 'Daily Worker Pipelines.', 1
EXEC ##AddBatches 'ControlDemoDaily', 'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1

EXEC ##AddBatchStageLink 'ControlDemoHourly', 'ControlSpeed'
EXEC ##AddBatchStageLink 'Hourly', 'Speed'
EXEC ##AddBatchStageLink 'Daily', 'Raw'
EXEC ##AddBatchStageLink 'Daily', 'Cleansed'
EXEC ##AddBatchStageLink 'Daily', 'Curated'
EXEC ##AddBatchStageLink 'Daily', 'Serve'
EXEC ##AddBatchStageLink 'ControlDemoDaily', 'ControlRaw'
EXEC ##AddBatchStageLink 'ControlDemoDaily', 'ControlCleansed'

-- Add tenants to the metadata control table.
EXEC ##AddTenants '$(TenantID)', 'Default', 'Example value for $(Environment) environment.'

-- Add Subscriptions to the metadata control table.
EXEC ##AddSubscriptions '$(SubscriptionID)', 'Default', 'Example value for $(Environment) environment.', '$(TenantID)'

-- Add Orchestrators to the metadata control table.
EXEC ##AddOrchestrators '$(ADFName)', 'ADF', 1, '$(RGName)', '$(SubscriptionID)', 'Example Data Factory used for $(Environment).'