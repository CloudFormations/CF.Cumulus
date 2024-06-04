CREATE TABLE [transform].[NotebookParameters](
	[ParameterId] [int] IDENTITY(1,1) NOT NULL,
	[NotebookFK] [int] NOT NULL,
	[ParameterDisplayName] [nvarchar](100) NOT NULL,
	[ParameterType] [nvarchar](100) NOT NULL, -- Insert, Merge, Delete, other, etc
	[SQL] [nvarchar](max) NOT NULL,
	[Enabled] [bit] NOT NULL
	
PRIMARY KEY CLUSTERED 
(
	[ParameterId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [transform].[NotebookParameters]  WITH CHECK ADD FOREIGN KEY([NotebookFK])
REFERENCES [transform].[Notebooks] ([NotebookId])
GO

