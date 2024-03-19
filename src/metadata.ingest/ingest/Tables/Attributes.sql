SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ingest].[Attributes](
	[AttributeId] [int] IDENTITY(1,1) NOT NULL,
	[DatasetFK] [int] NULL,
	[AttributeName] [nvarchar](50) NOT NULL,
	[AttributeDataType] [nvarchar](50) NULL,
	[AttributeDescription] [nvarchar](200) NULL,
	[DeltaFilterColumn] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AttributeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ingest].[Attributes]  WITH CHECK ADD FOREIGN KEY([DatasetFK])
REFERENCES [ingest].[Datasets] ([DatasetId])
GO

