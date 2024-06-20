CREATE TABLE [transform].[Datasets](
	[DatasetId] [int] IDENTITY(1,1) NOT NULL,
	[ComputeConnectionFK] [int] NULL,
	[SchemaName] [nvarchar](100) NOT NULL,
	[DatasetName] [nvarchar](100) NOT NULL,
	[BusinessLogicNotebookPath] [nvarchar](500) NULL,
	[VersionNumber] [int] NOT NULL,
	[VersionValidFrom] [datetime2](7) NULL,
	[VersionValidTo] [datetime2](7) NULL,
	[LoadType] [char](1) NOT NULL,
	[LoadStatus] [int] NULL, 
	[LastLoadDate] [datetime2](7) NULL,
	[Enabled] [bit] NOT NULL	
PRIMARY KEY CLUSTERED 
(
	[DatasetId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [transform].[Datasets]  WITH CHECK ADD FOREIGN KEY([ComputeConnectionFK])
REFERENCES [transform].[ComputeConnections] ([ComputeConnectionId])
GO
