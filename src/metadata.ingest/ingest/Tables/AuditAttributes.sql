CREATE TABLE [ingest].[AuditAttributes](
	[AuditAttributeId] [int] IDENTITY(1,1) NOT NULL,
	[AttributeName] [nvarchar](50) NOT NULL,
	[LayerName] [nvarchar](50) NOT NULL,
	[AttributeDataType] [nvarchar](50) NULL,
	[AttributeDataFormat] [varchar](100) NULL,
	[AttributeDescription] [nvarchar](200) NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[AuditAttributeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO