CREATE TABLE [transform].[Attributes](
	[AttributeId] [int] IDENTITY(1,1) NOT NULL,
	[DatasetFK] [int] NOT NULL,
	-- [SourceAttributeFK] [int] NOT NULL, -- Won't work if composite or aggregate column
	[AttributeName] [nvarchar](100) NOT NULL,
	[AttributeTargetDataType] [nvarchar](50) NULL,
	-- [AttributeTargetDataFormat] [varchar](100) NULL,  -- Remove as source will be delta so no formatting required?
	[AttributeDescription] [nvarchar](200) NULL,
	[BKAttribute] [bit] NOT NULL,
	[SurrogateKeyAttribute] [bit] NOT NULL,
	[PartitionByAttribute] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[AttributeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [transform].[Attributes]  WITH CHECK ADD FOREIGN KEY([DatasetFK])
REFERENCES [transform].[Datasets] ([DatasetId])
GO