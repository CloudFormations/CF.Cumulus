-- Metadata As Code - Ingest - add sample Datasets

--Datasets:
EXEC [ingest].[AddDatasets] 'AdventureWorksDemo', 'Ingest_LS_SQLDB_MIAuth', '$(DemoResourceName)', 'CF.Cumulus.Ingest.Compute', 'SalesOrderDetail', 'SalesLT', 'SalesOrderDetail', 'parquet', 1, '2025-01-01 00:00:00.0000000', NULL, 'I', 0, 0, 'WHERE ModifiedDate > GETDATE() - 7', 'SalesLT', 'SalesOrderDetail', 1;

--Attributes for SalesOrderDetail
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'SalesOrderDetailID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'OrderQty', 'smallint', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ProductID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'UnitPriceDiscount', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'LineTotal', 'numeric', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'SalesOrderDetail', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
