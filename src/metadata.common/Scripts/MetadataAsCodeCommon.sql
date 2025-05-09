-- Metadata As Code - Common - add connections and compute connections

--Connections - Azure services:
EXEC ##AddConnections 'Azure Data Lake Gen2', 'PrimaryDataLake', '$(DLS)', NULL, 'raw', 'NA', 'Ingest_LS_DataLake_MIAuth', '$(DLSRawKey)', 'NA', 1;
EXEC ##AddConnections 'Azure Data Lake Gen2', 'PrimaryDataLake', '$(DLS)', NULL, 'cleansed', 'NA', 'Ingest_LS_DataLake_MIAuth', '$(DLSCleansedKey)', 'NA', 1;
EXEC ##AddConnections 'Azure Key Vault', 'PrimaryKeyVault', 'https://$(KeyVaultName).vault.azure.net/', NULL, '$(KeyVaultName)', '$(KeyVaultName)', 'Common_LS_cumuluskeys', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure Resource Group', 'PrimaryResourceGroup', NULL, NULL, '$(RG)', '$(RG)', 'NA', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure Subscription', 'PrimarySubscription', NULL, NULL, '$(SubID)', '$(SubID)', 'NA', 'NA', 'NA', 1;
EXEC ##AddConnections 'Azure SQL Database', 'AdventureWorksDemo', '$(DemoConnLocation)', NULL, '$(DemoSourceLocation)', '$(DemoResourceName)', '$(DemoLinkedServ)', '$(DemoUsername)', '$(DemoKVSecret)', 1;

--ComputeConnections
EXEC ##AddComputeConnections 'Azure Databricks', 'CF.Cumulus.Ingest.Compute', '$(DBURL)', '$(IngestCompute)', 'Standard_D4ds_v5', '15.4.x-scala2.12', 1, '$(DBName)', 'Ingest_LS_Databricks_Cluster_MIAuth', 'Dev', 1;
EXEC ##AddComputeConnections 'Azure Databricks', 'CF.Cumulus.Transform.Compute', '$(DBURL)', '$(TransformCompute)', 'Standard_E8_v3', '15.4.x-scala2.12', 2, '$(DBName)', 'Ingest_LS_Databricks_JobCluster_MIAuth', 'Dev', 1;