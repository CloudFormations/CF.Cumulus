CREATE TABLE [transform].[Connections](
	[ConnectionId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeFK] [int] NOT NULL,
	[ConnectionDisplayName] [nvarchar](50) NOT NULL,
	[ConnectionLocation] [nvarchar](200) NULL,
	[ConnectionPort] [nvarchar](50) NULL,
	[SourceLocation] [nvarchar](200) NOT NULL,
	[AzureResourceName] [nvarchar](100) NULL,
	[LinkedServiceName] [nvarchar](200) NOT NULL,
	[IntegrationRuntimeName] [nvarchar](200) NOT NULL,
	[TemplatePipelineName] [nvarchar](200) NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[KeyVaultSecret] [nvarchar](100) NOT NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[ConnectionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [transform].[Connections]  WITH CHECK ADD  CONSTRAINT [FK__Connectio__Conne__361203C5] FOREIGN KEY([ConnectionTypeFK])
REFERENCES [transform].[ConnectionTypes] ([ConnectionTypeId])
GO

ALTER TABLE [transform].[Connections] CHECK CONSTRAINT [FK__Connectio__Conne__361203C5]
GO

ALTER TABLE [transform].[Connections]  WITH CHECK ADD  CONSTRAINT [chkConnectionDisplayNameNoSpaces] CHECK  ((NOT [ConnectionDisplayName] like '% %'))
GO

ALTER TABLE [transform].[Connections] CHECK CONSTRAINT [chkConnectionDisplayNameNoSpaces]
GO