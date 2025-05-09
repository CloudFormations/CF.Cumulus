--Metadata As Code Transform

--Notebook Types
EXEC ##AddNotebookTypes 'Unmanaged', 1
EXEC ##AddNotebookTypes 'Managed', 1
EXEC ##AddNotebookTypes 'Create Dimension Table', 1
EXEC ##AddNotebookTypes 'Create Fact Table', 1

EXEC ##AddNotebooks 'Unmanaged', 'UnmanagedQuery', '/Workspace/Shared/Live/transform/unmanagednotebooks/UnmanagedQuery', 1
EXEC ##AddNotebooks 'Unmanaged', 'CreateDimDate', '/Workspace/Shared/Live/transform/unmanagednotebooks/CreateDimDate', 1
EXEC ##AddNotebooks 'Unmanaged', 'CreateDimProducts', '/Workspace/Shared/Live/transform/unmanagednotebooks/CreateDimProducts', 1
EXEC ##AddNotebooks 'Unmanaged', 'CreateFactSales', '/Workspace/Shared/Live/transform/unmanagednotebooks/CreateFactSales', 1

EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'UnmanagedQuery', 'UnmanagedQuery', 'Samples', 'NYCTaxiTrip', 1, NULL, NULL, 'F', 0, NULL, 1
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateDimDate', 'CreateDimDate', 'Curated', 'DimDate', 1, NULL, NULL, 'F', 0, NULL, 1
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateDimProducts', 'CreateDimProducts', 'Curated', 'DimProducts', 1, NULL, NULL, 'F', 0, NULL, 1
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateFactSales', 'CreateFactSales', 'Curated', 'FactSales', 1, NULL, NULL, 'F', 0, NULL, 1