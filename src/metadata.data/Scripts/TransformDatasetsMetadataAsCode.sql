--Metadata As code Transform Datasets and Attributes

-- Notebooks
EXEC ##AddNotebooks 'Managed', 'DimDate', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimDate', 1;
EXEC ##AddNotebooks 'Managed', 'DimProducts', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/DimProducts', 1;
EXEC ##AddNotebooks 'Managed', 'FactSales', '/Workspace/Shared/Live/files/transform/businesslogicnotebooks/FactSales', 1;

-- Datasets;
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateDim', 'DimDate', 'Curated', 'DimDate', 1, NULL, NULL, 'F', 0, NULL, 1;
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateDim', 'DimProducts', 'Curated', 'DimProducts', 1, NULL, NULL, 'F', 0, NULL, 1;
EXEC ##AddTransformDatasets 'CF.Cumulus.Transform.Compute', 'CreateFact', 'FactSales', 'Curated', 'FactSales', 1, NULL, NULL, 'F', 0, NULL, 1;

-- Attributes;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'DateSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'Date', 'DATE', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'DateKey', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'DayName', 'STRING', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'DayOfMonth', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'MonthName', 'STRING', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'Quarter', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimDate', 'Curated', 'Year', 'INT', '', 0, 0, 0, 1;

EXEC ##AddTransformAttributes 'DimProducts', 'Curated', 'ProductSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC ##AddTransformAttributes 'DimProducts', 'Curated', 'ProductKey', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimProducts', 'Curated', 'ProductName', 'STRING', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimProducts', 'Curated', 'ProductColour', 'STRING', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'DimProducts', 'Curated', 'ProductSize', 'STRING', '', 0, 0, 0, 1;

EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SaleSK', 'INT', 'Auto-Generated Surrogate Key', 0, 1, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SalesOrderKey', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SalesOrderDetailKey', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'OrderDateSK', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'DueDateSK', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'ShipDateSK', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'ProductSK', 'INT', '', 1, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'ProductOrderQuantity', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'UnitPrice', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'LineTotal', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SaleLineTotalAmount', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SaleOrderTotalAmount', 'INT', '', 0, 0, 0, 1;
EXEC ##AddTransformAttributes 'FactSales', 'Curated', 'SaleOrderShippingTotalAmount', 'INT', '', 0, 0, 0, 1;