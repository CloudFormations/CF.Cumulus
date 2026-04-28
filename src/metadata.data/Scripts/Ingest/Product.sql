-- Metadata As Code - Ingest - add sample Datasets

--Datasets:
EXEC [ingest].[AddDatasets] 'AdventureWorksDemo', 'Ingest_LS_SQLDB_MIAuth', '$(DemoResourceName)', 'CF.Cumulus.Ingest.Compute', 'Product', 'SalesLT', 'Product', 'parquet', 1, '2025-01-01 00:00:00.0000000', NULL, 'I', 0, 0, 'WHERE ModifiedDate > GETDATE() - 7', 'SalesLT', 'Product', 1;

--Attributes for Product
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductID', 'int', 'INTEGER', '', '', 1, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Name', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductNumber', 'nvarchar(25)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Color', 'nvarchar(15)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'StandardCost', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ListPrice', 'money', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Size', 'nvarchar(5)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'Weight', 'decimal(8,2)', 'FLOAT', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductCategoryID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ProductModelID', 'int', 'INTEGER', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'SellStartDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'SellEndDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'DiscontinuedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ThumbNailPhoto', 'varbinary', 'BINARY', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ThumbnailPhotoFileName', 'nvarchar(50)', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'rowguid', 'uniqueidentifier', 'STRING', '', '', 0, 0, 1
EXEC [ingest].[AddAttributes] 'AdventureWorksDemo', 'Product', 1, 'ModifiedDate', 'datetime', 'TIMESTAMP', 'yyyy-MM-dd HH:mm:ss', '', 0, 0, 1