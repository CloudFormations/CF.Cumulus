CREATE TABLE [transform].[Notebooks](
	[NotebookId] [int] IDENTITY(1,1) NOT NULL,
	[NotebookTypeFK] [int] NOT NULL,
	[NotebookName] [nvarchar](100) NOT NULL,
	[NotebookPath] [nvarchar](500) NOT NULL,
	[Enabled] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[NotebookId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [transform].[Notebooks]  WITH CHECK ADD FOREIGN KEY([NotebookTypeFK])
REFERENCES [transform].[NotebookTypes] ([NotebookTypeId])
GO
