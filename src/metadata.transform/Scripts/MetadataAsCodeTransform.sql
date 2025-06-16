--Metadata As Code Transform

--Notebook Types
EXEC [transform].[AddNotebookTypes] 'Unmanaged', 1
EXEC [transform].[AddNotebookTypes] 'Managed', 1
EXEC [transform].[AddNotebookTypes] 'Create Dimension Table', 1
EXEC [transform].[AddNotebookTypes] 'Create Fact Table', 1

EXEC [transform].[AddNotebooks] 'Create Dimension Table', 'CreateDim', '/Workspace/Shared/Live/files/transform/CreateDimensionTable', 1;
EXEC [transform].[AddNotebooks] 'Create Fact Table', 'CreateFact', '/Workspace/Shared/Live/files/transform/CreateFactTable', 1;