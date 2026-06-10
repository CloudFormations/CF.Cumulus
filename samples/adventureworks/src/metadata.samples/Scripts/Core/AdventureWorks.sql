--Connections - Azure services:
EXEC [common].[AddConnections] 
	@ConnectionTypeDisplayName ='Azure SQL Database',
	@ConnectionDisplayName ='AdventureWorksDemo',
	@ConnectionLocation = '$(AdventureWorksServerName)',
	@ConnectionPort = NULL,
	@SourceLocation = '$(AdventureWorksDatabaseName)',
	@ResourceName = '$(AdventureWorksDatabaseName)',
	@LinkedServiceName = 'Ingest_LS_SQLDB_MIAuth',
	@Username = 'NA',
    @KeyVaultSecret = 'NA',
	@Enabled = 1;
