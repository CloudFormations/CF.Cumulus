CREATE TABLE [cumulus.control].[Tenants]
	(
	[TenantId] [UNIQUEIDENTIFIER] NOT NULL,
	[Name] [NVARCHAR](200) NOT NULL,
	[Description] [NVARCHAR](MAX) NULL,
	CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED ([TenantId] ASC)
	)