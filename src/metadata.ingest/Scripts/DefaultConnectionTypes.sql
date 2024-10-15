	
	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Files',
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Oracle',
		@SourceLanguageType = 'PSQL',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'SQL Server',
		@SourceLanguageType = 'T-SQL',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'PostgreSQL', 
		@SourceLanguageType = 'SQL',
		@Enabled = 0;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure SQL Database', 
		@SourceLanguageType = 'T-SQL',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Data Lake Gen2', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Key Vault', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Databricks', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;
		
	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Resource Group', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Subscription', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Dynamics 365', 
		@SourceLanguageType = 'XML',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'REST API', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;