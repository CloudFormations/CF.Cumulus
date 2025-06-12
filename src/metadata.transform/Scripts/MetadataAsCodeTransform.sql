--Metadata As Code Transform

--Notebook Types
EXEC ##AddNotebookTypes 'Unmanaged', 1
EXEC ##AddNotebookTypes 'Managed', 1
EXEC ##AddNotebookTypes 'Create Dimension Table', 1
EXEC ##AddNotebookTypes 'Create Fact Table', 1

EXEC ##AddNotebooks 'Create Dimension Table', 'CreateDim', '/Workspace/Shared/Live/files/transform/CreateDimensionTable', 1;
EXEC ##AddNotebooks 'Create Fact Table', 'CreateFact', '/Workspace/Shared/Live/files/transform/CreateFactTable', 1;