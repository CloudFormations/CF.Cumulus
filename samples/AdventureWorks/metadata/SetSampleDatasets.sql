CREATE PROCEDURE [samples].[SetSampleDatasets]
AS
DECLARE @AdventureWorksDatabaseConnectionFK INT

SELECT @AdventureWorksDatabaseConnectionFK = ConnectionId
FROM [ingest].[Connections]
WHERE ConnectionDisplayName = 'AdventureWorksDatabase';

INSERT INTO [ingest].[Datasets]
           ([ConnectionFK]
           ,[MergeComputeConnectionFK]
           ,[DatasetDisplayName]
           ,[SourcePath]
           ,[SourceName]
           ,[ExtensionType]
           ,[VersionNumber]
           ,[VersionValidFrom]
           ,[LoadType]
           ,[LoadStatus]
           ,[LoadClause]
           ,[CleansedPath]
           ,[CleansedName]
           ,[Enabled])
     VALUES 
  (@AdventureWorksDatabaseConnectionFK, 1 ,'SalesOrderHeader' ,'SalesLT' ,'SalesOrderHeader' ,'parquet' ,1 ,'2025-01-01 00:00:00.0000000' ,'I' ,0 ,'WHERE ModifiedDate > GETDATE() - 7','SalesLT' ,'SalesOrderHeader',1),
  (@AdventureWorksDatabaseConnectionFK, 1 ,'SalesOrderDetail' ,'SalesLT' ,'SalesOrderDetail' ,'parquet' ,1 ,'2025-01-01 00:00:00.0000000' ,'I' ,0 ,'WHERE ModifiedDate > GETDATE() - 7','SalesLT' ,'SalesOrderDetail',1),
  (@AdventureWorksDatabaseConnectionFK, 1 ,'Product' ,'SalesLT' ,'Product' ,'parquet' ,1 ,'2025-01-01 00:00:00.0000000' ,'I' ,0 ,'WHERE ModifiedDate > GETDATE() - 7','SalesLT' ,'Product',1);
  

GO
