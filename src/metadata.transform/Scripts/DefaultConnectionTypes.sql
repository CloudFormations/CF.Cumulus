	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure SQL Database', 
		@SourceLanguageType = 'T-SQL',
		@Enabled = 1;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Data Lake Gen2', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Key Vault', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Databricks', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Synapse', 
		@SourceLanguageType = 'NA',
		@Enabled = 0;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Fabric', 
		@SourceLanguageType = 'NA',
		@Enabled = 0;
		
	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Resource Group', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [transform].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Subscription', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;