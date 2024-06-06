CREATE TABLE [ingest].[ComputeConnections](
	[ComputeConnectionId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeFK] [int] NOT NULL,
	[ConnectionDisplayName] [nvarchar](50) NOT NULL,
	[ConnectionLocation] [nvarchar](200) NULL,
	[ComputeLocation] [nvarchar](200) NULL,
	[ComputeSize] [nvarchar](200) NOT NULL,
	[ComputeVersion] [nvarchar](100) NOT NULL,
	[CountNodes] int NOT NULL,
	[AzureResourceName] [nvarchar](100) NULL,
	[LinkedServiceName] [nvarchar](200) NOT NULL,
	[IntegrationRuntimeName] [nvarchar](200) NOT NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[ComputeConnectionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ingest].[ComputeConnections]  WITH CHECK ADD  CONSTRAINT [FK__Connectio__Conne__361223C5] FOREIGN KEY([ConnectionTypeFK])
REFERENCES [ingest].[ConnectionTypes] ([ConnectionTypeId])
GO

ALTER TABLE [ingest].[ComputeConnections] CHECK CONSTRAINT [FK__Connectio__Conne__361223C5]
GO

ALTER TABLE [ingest].[ComputeConnections]  WITH CHECK ADD  CONSTRAINT [chkComputeConnectionDisplayNameNoSpaces] CHECK  ((NOT [ConnectionDisplayName] like '% %'))
GO

ALTER TABLE [ingest].[ComputeConnections] CHECK CONSTRAINT [chkComputeConnectionDisplayNameNoSpaces]
GO