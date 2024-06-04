CREATE VIEW [transform].[NotebooksLatestVersion] AS 
WITH CTE AS (
    SELECT 
        NotebookName
        , MAX(VersionNumber) AS VersionNumber
    FROM transform.Notebooks
    GROUP BY  
        NotebookName
)
SELECT 
    n.*
FROM CTE
INNER JOIN transform.Notebooks AS n
    ON CTE.NotebookName = n.NotebookName 
    AND CTE.VersionNumber = n.VersionNumber
GO