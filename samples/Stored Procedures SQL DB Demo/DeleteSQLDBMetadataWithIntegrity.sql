CREATE PROCEDURE [samples].[DeleteSQLDBMetadataWithIntegrity]
AS
DECLARE @DeleteRecords TABLE (
    ConnectionId INT
    , ComputeConnectionId INT
    , DatasetId INT
    --, AttributeId INT
);

INSERT INTO @DeleteRecords (ConnectionId, ComputeConnectionId, DatasetId)
SELECT c.ConnectionId, cc.ComputeConnectionId, d.DatasetId
FROM [common].[ConnectionTypes] AS ct
INNER JOIN [common].[Connections] AS c
ON ct.[ConnectionTypeId] = c.[ConnectionTypeFK]
INNER JOIN [ingest].[Datasets] AS d
ON c.[ConnectionId] = d.[ConnectionFK]
INNER JOIN [common].[ComputeConnections] AS cc
ON cc.[ComputeConnectionId] = d.[MergeComputeConnectionFK]
INNER JOIN [ingest].[Attributes] AS a
ON d.[DatasetId] = a.[DatasetFK]
WHERE ct.ConnectionTypeDisplayName = 'Azure SQL Database';

-- Delete in following order to avoid breaking FK constraints.

DELETE FROM [ingest].[Attributes]
WHERE AttributeId IN (SELECT AttributeId FROM @DeleteRecords);

DELETE FROM [ingest].[Datasets]
WHERE DatasetId IN (SELECT DatasetId FROM @DeleteRecords);

DELETE FROM [common].[Connections]
WHERE ConnectionId IN (SELECT ConnectionId FROM @DeleteRecords);

DELETE FROM [common].[ComputeConnections]
WHERE ComputeConnectionId IN (SELECT ComputeConnectionId FROM @DeleteRecords);

DBCC CHECKIDENT('ingest.Attributes', RESEED, 1);
DBCC CHECKIDENT('ingest.Datasets', RESEED, 1);
DBCC CHECKIDENT('common.Connections', RESEED, 1);
DBCC CHECKIDENT('common.ComputeConnections', RESEED, 1);