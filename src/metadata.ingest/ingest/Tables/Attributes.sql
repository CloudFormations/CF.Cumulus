CREATE TABLE [ingest].[Attributes](
	[AttributeId] [int] IDENTITY(1,1) NOT NULL,
	[DatasetFK] [int] NULL,
	[AttributeName] [nvarchar](50) NOT NULL,
	[AttributeSourceDataType] [nvarchar](50) NULL,
	[AttributeTargetName] [nvarchar](50) NULL,
	[AttributeTargetDataType] [nvarchar](50) NULL,
	[AttributeTargetDataFormat] [varchar](100) NULL,
	[AttributeDescription] [nvarchar](200) NULL,
	[PkAttribute] [bit] NOT NULL,
	[PartitionByAttribute] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[AttributeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ingest].[Attributes]  WITH CHECK ADD FOREIGN KEY([DatasetFK])
REFERENCES [ingest].[Datasets] ([DatasetId])
GO

