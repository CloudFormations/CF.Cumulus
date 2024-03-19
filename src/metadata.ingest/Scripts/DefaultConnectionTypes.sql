	
	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Files',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'Oracle',
		@Enabled = 1;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'SQL Server',
		@Enabled = 0;

	EXEC [ingest].[AddConnectionType] 
		@ConnectionTypeDisplayName = N'PostgreSQL', 
		@Enabled = 0;
