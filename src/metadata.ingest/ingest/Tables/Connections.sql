CREATE TABLE [ingest].[Connections](
	[ConnectionId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeFK] [int] NOT NULL,
	[ConnectionDisplayName] [nvarchar](50) NOT NULL,
	[SourceLocation] [nvarchar](100) NOT NULL,
	[LinkedServiceName] [nvarchar](200) NOT NULL,
	[IntegrationRuntimeName] [nvarchar](200) NOT NULL,
	[TemplatePipelineName] [nvarchar](200) NOT NULL,
	[AkvUserName] [nvarchar](100) NOT NULL,
	[AkvPasswordName] [nvarchar](100) NOT NULL,
	[Enabled] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConnectionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [AK_ConnectionDisplayName] UNIQUE NONCLUSTERED 
(
	[ConnectionDisplayName] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ingest].[Connections]  WITH CHECK ADD FOREIGN KEY([ConnectionTypeFK])
REFERENCES [ingest].[ConnectionTypes] ([ConnectionTypeId])
GO

ALTER TABLE [ingest].[Connections]  WITH CHECK ADD  CONSTRAINT [chkConnectionDisplayNameNoSpaces] CHECK  ((NOT [ConnectionDisplayName] like '% %'))
GO

ALTER TABLE [ingest].[Connections] CHECK CONSTRAINT [chkConnectionDisplayNameNoSpaces]
GO

