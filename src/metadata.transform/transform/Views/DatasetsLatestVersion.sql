CREATE VIEW [transform].[DatasetsLatestVersion] AS 
WITH CTE AS (
    SELECT 
        DatasetName
        , MAX(VersionNumber) AS VersionNumber
    FROM transform.Datasets
    GROUP BY  
        DatasetName
)
SELECT 
    n.*
FROM CTE
INNER JOIN transform.Datasets AS n
    ON CTE.DatasetName = n.DatasetName 
    AND CTE.VersionNumber = n.VersionNumber
GO