	
	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Files',
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Oracle',
		@SourceLanguageType = 'PSQL',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'SQL Server',
		@SourceLanguageType = 'T-SQL',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'PostgreSQL', 
		@SourceLanguageType = 'SQL',
		@Enabled = 0;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Synapse',
		@SourceLanguageType = 'NA',
		@Enabled = 0;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Fabric',
		@SourceLanguageType = 'NA',
		@Enabled = 0;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure SQL Database', 
		@SourceLanguageType = 'T-SQL',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Data Lake Gen2', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Key Vault', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Databricks', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;
		
	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Resource Group', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Azure Subscription', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Dynamics 365', 
		@SourceLanguageType = 'XML',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'REST API', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'SAP ECC',
		@SourceLanguageType = 'OData',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Salesforce',
		@SourceLanguageType = 'SOQL',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Jira', 
		@SourceLanguageType = 'SQL',
		@Enabled = 1;

	EXEC [common].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Amazon S3', 
		@SourceLanguageType = 'NA',
		@Enabled = 1;
