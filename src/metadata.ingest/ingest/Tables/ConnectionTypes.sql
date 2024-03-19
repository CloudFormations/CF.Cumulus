CREATE TABLE [ingest].[ConnectionTypes](
	[ConnectionTypeId] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeDisplayName] [nvarchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConnectionTypeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

