CREATE PROCEDURE [samples].[SetSampleConnections]
AS
DECLARE @ConnectionTypeFK INT;
-- DECLARE @KeyVaultPath NVARCHAR(100);

SELECT @ConnectionTypeFK = ConnectionTypeId
FROM [common].[ConnectionTypes]
WHERE ConnectionTypeDisplayName = 'Azure SQL Database';

INSERT INTO [common].[Connections]
           ([ConnectionTypeFK]
           ,[ConnectionDisplayName]
           ,[ConnectionLocation]
           ,[ResourceName]
           ,[SourceLocation]
           ,[LinkedServiceName]
           ,[Username]
           ,[KeyVaultSecret]
           ,[Enabled])
     VALUES
     (@ConnectionTypeFK
           ,'AdventureWorksDatabase'
           ,'cfcdemodevsqldbuks01.database.windows.net' -- baseUrl
           ,'CumulusDemoDataSource01'
           ,'CumulusDemoDataSource01'
           ,'Ingest_LS_SQLDB_MIAuth'
           ,'NA'
           ,'NA'
           ,1);
GO