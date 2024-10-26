CREATE TABLE [ingest].[Datasets](
	[DatasetId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionFK] [int] NOT NULL,
	[MergeComputeConnectionFK] [int] NULL,
	[DatasetDisplayName] [nvarchar](50) NOT NULL,
	[SourcePath] [nvarchar](100) NOT NULL,
	[SourceName] [nvarchar](100) NOT NULL,
	[ExtensionType] [nvarchar](20) NULL,
	[VersionNumber] [int] NOT NULL,
	[VersionValidFrom] [datetime2](7) NULL,
	[VersionValidTo] [datetime2](7) NULL,
	[LoadType] [char](1) NOT NULL,
	[LoadStatus] [int] NULL,
	[LoadClause] [nvarchar](max) NULL,
	[RawLastFullLoadDate] [datetime2](7) NULL,
	[RawLastIncrementalLoadDate] [datetime2](7) NULL,
	[CleansedPath] [nvarchar](100) NOT NULL,
	[CleansedName] [nvarchar](100) NOT NULL,
	[CleansedLastFullLoadDate] [datetime2](7) NULL,
	[CleansedLastIncrementalLoadDate] [datetime2](7) NULL,
	[Enabled] [bit] NOT NULL
	
PRIMARY KEY CLUSTERED 
(
	[DatasetId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [ingest].[Datasets]  WITH CHECK ADD  CONSTRAINT [chkDatasetDisplayNameNoSpaces] CHECK  ((NOT [DatasetDisplayName] like '% %'))
GO

ALTER TABLE [ingest].[Datasets] CHECK CONSTRAINT [chkDatasetDisplayNameNoSpaces]
GO

ALTER TABLE[ingest].[Datasets]  WITH CHECK ADD FOREIGN KEY([MergeComputeConnectionFK])
REFERENCES [ingest].[ComputeConnections] ([ComputeConnectionId])
GO

ALTER TABLE[ingest].[Datasets]  WITH CHECK ADD FOREIGN KEY([ConnectionFK])
REFERENCES [ingest].[Connections] ([ConnectionId])
GO