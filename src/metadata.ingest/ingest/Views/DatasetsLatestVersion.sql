CREATE VIEW [ingest].[DatasetsLatestVersion] AS 
WITH CTE AS (
    SELECT 
        DatasetDisplayName
        , MAX(VersionNumber) AS VersionNumber
    FROM ingest.Datasets
    GROUP BY  
        DatasetDisplayName
)
SELECT 
    d.*
FROM CTE
INNER JOIN ingest.Datasets AS d
    ON CTE.DatasetDisplayName = d.DatasetDisplayName 
    AND CTE.VersionNumber = d.VersionNumber
GO

