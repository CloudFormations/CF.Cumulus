CREATE TABLE [transform].[ConnectionTypes](
	[ConnectionTypeId] [int] IDENTITY(1,1) NOT NULL,
	[SourceLanguageType] [varchar](5) NULL,
	[ConnectionTypeDisplayName] [nvarchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK__Connecti__69EB7405ED3FCEA7] PRIMARY KEY CLUSTERED 
(
	[ConnectionTypeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

