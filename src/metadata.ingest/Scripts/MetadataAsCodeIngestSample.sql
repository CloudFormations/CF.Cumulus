-- Metadata As Code - Ingest - add sample Datasets

--Datasets:
EXEC ##AddDatasets 'AdventureWorksDemo', 'Ingest_LS_SQLDB_MIAuth', 'CumulusDemoDataSource01', 'CF.Cumulus.Ingest.Compute', 'SalesOrderHeader', 'SalesLT', 'SalesOrderHeader', 'parquet', 1, '2025-01-01 00:00:00.0000000', NULL, 'I', 0, 0, 'WHERE ModifiedDate > GETDATE() - 7', 'SalesLT', 'SalesOrderHeader', 1;
EXEC ##AddDatasets 'AdventureWorksDemo', 'Ingest_LS_SQLDB_MIAuth', 'CumulusDemoDataSource01', 'CF.Cumulus.Ingest.Compute', 'SalesOrderDetail', 'SalesLT', 'SalesOrderDetail', 'parquet', 1, '2025-01-01 00:00:00.0000000', NULL, 'I', 0, 0, 'WHERE ModifiedDate > GETDATE() - 7', 'SalesLT', 'SalesOrderDetail', 1;
EXEC ##AddDatasets 'AdventureWorksDemo', 'Ingest_LS_SQLDB_MIAuth', 'CumulusDemoDataSource01', 'CF.Cumulus.Ingest.Compute', 'Product', 'SalesLT', 'Product', 'parquet', 1, '2025-01-01 00:00:00.0000000', NULL, 'I', 0, 0, 'WHERE ModifiedDate > GETDATE() - 7', 'SalesLT', 'Product', 1;

--Attributes for SalesOrderHeader
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'SalesOrderID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'RevisionNumber', 'tinyint', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'OrderDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'DueDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'ShipDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'Status', 'tinyint', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'OnlineOrderFlag', 'bit', 'BOOLEAN', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'SalesOrderNumber', 'nvarchar(25)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'PurchaseOrderNumber', 'nvarchar(25)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'AccountNumber', 'nvarchar(15)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'CustomerID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'ShipToAddressID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'BillToAddressID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'ShipMethod', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'CreditCardApprovalCode', 'varchar', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'SubTotal', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'TaxAmt', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'Freight', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'TotalDue', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'Comment', 'nvarchar(-1)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderHeader', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1

--Attributes for SalesOrderDetail
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderDetailID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'OrderQty', 'smallint', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ProductID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPriceDiscount', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'LineTotal', 'numeric', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1

--Attributes for Product
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ProductID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'Name', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ProductNumber', 'nvarchar(25)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'Color', 'nvarchar(15)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'StandardCost', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ListPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'Size', 'nvarchar(5)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'Weight', 'decimal(8,2)', 'FLOAT', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ProductCategoryID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ProductModelID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'SellStartDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'SellEndDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'DiscontinuedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ThumbNailPhoto', 'varbinary', 'BINARY', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ThumbnailPhotoFileName', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC ##AddAttributes 'AdventureWorksDemo', 'Product', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1