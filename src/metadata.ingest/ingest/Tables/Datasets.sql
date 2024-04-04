CREATE TABLE [ingest].[Datasets](
	[DatasetId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionFK] [int] NOT NULL,
	[DatasetDisplayName] [nvarchar](50) NOT NULL,
	[SourcePath] [nvarchar](100) NOT NULL,
	[SourceName] [nvarchar](100) NOT NULL,
	[ExtensionType] [nvarchar](20) NULL,
	[VersionNumber] [int] NOT NULL,
	[VersionValidFrom] [datetime2](7) NULL,
	[VersionValidTo] [datetime2](7) NULL,
	[FullLoad] [bit] NOT NULL,
	[FirstLoad] [bit] NOT NULL,
	[FirstLoadCompleteDate] [datetime2](7) NULL,
	[LoadType] [char](1) NOT NULL,
	[CDCWhereClause] [nvarchar](max) NULL,
	[Enabled] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DatasetId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [ingest].[Datasets] ADD  DEFAULT ((0)) FOR [FirstLoad]
GO

ALTER TABLE [ingest].[Datasets] ADD  DEFAULT ('F') FOR [LoadType]
GO

ALTER TABLE [ingest].[Datasets]  WITH CHECK ADD  CONSTRAINT [chkDatasetDisplayNameNoSpaces] CHECK  ((NOT [DatasetDisplayName] like '% %'))
GO

ALTER TABLE [ingest].[Datasets] CHECK CONSTRAINT [chkDatasetDisplayNameNoSpaces]
GO

