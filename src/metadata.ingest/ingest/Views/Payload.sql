/****** Object:  View [ingest].[Payload]    Script Date: 3/19/2024 1:26:16 PM ******/
CREATE VIEW [ingest].[Payload] AS 
SELECT 
    CASE 
        WHEN ct.ConnectionTypeDisplayName = 'SQL Server' THEN c.SourceLocation + '.' + d.SourcePath + '.' + d.SourceName
        WHEN ct.ConnectionTypeDisplayName = 'Files' THEN  c.SourceLocation + '/' + d.SourcePath
        ELSE NULL
    END AS CompleteSource
    , c.SourceLocation
    , d.SourceName
    , ct.ConnectionTypeDisplayName
    , c.ConnectionDisplayName
    , c.LinkedServiceName
    , c.IntegrationRuntimeName
    , c.TemplatePipelineName
    , c.AkvUserName
    , c.AkvPasswordName
    , d.VersionNumber
    , d.DatasetId
    , d.DatasetDisplayName
    , d.ExtensionType
    , d.FullLoad
FROM ingest.ConnectionTypes AS ct 
INNER JOIN ingest.Connections AS c 
    ON ct.ConnectionTypeId = c.ConnectionTypeFK
INNER JOIN ingest.DatasetsLatestVersion AS d
    ON c.ConnectionId = d.ConnectionFK
WHERE 
    (ct.Enabled = 1
        AND c.Enabled = 1
        AND d.Enabled = 1
    )
AND d.VersionValidFrom <= GETDATE()
AND
    (d.VersionValidTo >= GETDATE()
        OR d.VersionValidTo IS NULL
    )
GO

