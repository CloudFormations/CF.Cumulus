-- Metadata As Code - Common - add connections and compute connections

--Connections - Azure services:
EXEC ##AddConnections 'Azure Data Lake Gen2', 'PrimaryDataLake', '$(DLSName)', NULL, 'raw', 'NA', 'Ingest_LS_DataLake_MIAuth', '$(DLSName)rawaccesskey', 'NA', 1;
EXEC ##AddConnections 'Azure Data Lake Gen2', 'PrimaryDataLake', '$(DLSName)', NULL, 'cleansed', 'NA', 'Ingest_LS_DataLake_MIAuth', '$(DLSName)cleansedaccesskey', 'NA', 1;
EXEC ##AddConnections 'Azure Data Lake Gen2', 'PrimaryDataLake', '$(DLSName)', NULL, 'curated', 'NA', 'Ingest_LS_DataLake_MIAuth', '$(DLSName)curatedaccesskey', 'NA', 1;
EXEC ##AddConnections 'Azure Key Vault', 'PrimaryKeyVault', 'https://$(KeyVaultName).vault.azure.net/', NULL, '$(KeyVaultName)', '$(KeyVaultName)', 'Common_LS_cumuluskeys', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure Resource Group', 'PrimaryResourceGroup', 'NA', NULL, '$(RGName)', '$(RGName)', 'NA', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure Subscription', 'PrimarySubscription', 'NA', NULL, '$(SubscriptionID)', '$(SubscriptionID)', 'NA', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure SQL Database', 'AdventureWorksDemo', '$(DemoConnectionLocation)', NULL, '$(DemoSourceLocation)', '$(DemoResourceName)', '$(DemoLinkedService)', '$(DemoUsername)', '$(DemoKVSecret)', 1;

--ComputeConnections
EXEC ##AddComputeConnections 'Azure Databricks', 'CF.Cumulus.Ingest.Compute', '$(DatabricksWSURL)', '', 'Standard_D4ds_v5', '15.4.x-scala2.12', 1, '$(DatabricksWSName)', 'Common_LS_Databricks_Cluster_MIAuth', '$(EnvironmentName)', 1;
EXEC ##AddComputeConnections 'Azure Databricks', 'CF.Cumulus.Transform.Compute', '$(DatabricksWSURL)', '', 'Standard_E8_v3', '15.4.x-scala2.12', 2, '$(DatabricksWSName)', 'Common_LS_Databricks_JobCluster_MIAuth', '$(EnvironmentName)', 1;