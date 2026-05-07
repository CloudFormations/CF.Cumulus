CREATE PROCEDURE [samples].[SetSampleComputeConnections]
AS
DECLARE @ConnectionTypeFK INT;

SELECT @ConnectionTypeFK = ConnectionTypeId
FROM [common].[ConnectionTypes]
WHERE ConnectionTypeDisplayName = 'Azure Databricks';

INSERT INTO [common].[ComputeConnections]
           ([ConnectionTypeFK]
           ,[ConnectionDisplayName]
           ,[ConnectionLocation]
           ,[ComputeLocation]
           ,[ComputeSize]
           ,[ComputeVersion]
           ,[CountNodes]
           ,[ResourceName]
           ,[LinkedServiceName]
           ,[EnvironmentName]
           ,[Enabled])
     VALUES
     (@ConnectionTypeFK
           ,'DevDatabricksJobClusterSmall'
           ,'https://adb-XXX.azuredatabricks.net' -- baseUrl
           ,'databrickscomputeguid'
           ,'Standard_D4ds_v5'
           ,'15.4.x-scala2.12'
           ,1
           ,'databricksworkspacename'
           ,'Ingest_LS_Databricks_Cluster_MIAuth'
           ,'Dev'
           ,1);
GO