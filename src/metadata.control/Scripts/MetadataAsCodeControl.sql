-- Add tenants to the metadata control table.
EXEC [control].[AddTenants] '$(TenantID)', 'Default', 'Example value for $(Environment) environment.'

-- Add Subscriptions to the metadata control table.
EXEC [control].[AddSubscriptions] '$(SubscriptionID)', 'Default', 'Example value for $(Environment) environment.', '$(TenantID)'

-- Add Orchestrators to the metadata control table.
EXEC [control].[AddOrchestrators] '$(ADFName)', 'ADF', 1, '$(RGName)', '$(SubscriptionID)', 'Example Data Factory used for $(Environment).'