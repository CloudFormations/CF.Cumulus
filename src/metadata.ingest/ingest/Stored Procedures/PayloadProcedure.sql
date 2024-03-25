CREATE   PROCEDURE [ingest].[PayloadProcedure]  
@DatasetId NVARCHAR(20), 
@Incremental BIT 
AS  
BEGIN; 
	SET NOCOUNT ON; 
 
    DECLARE @FilterColumn DATETIME2 
    SET @FilterColumn = '2024-09-09' -- TODO: THIS IS AN ARBITRARY PLACEHOLDER VALUE FOR INCREMENTAL LOADING 
     
    DECLARE @RowCountDatasetIds INT 
 
    SET @RowCountDatasetIds = (SELECT COUNT(*)  
    FROM ingest.DatasetsLatestVersion AS d
    WHERE d.DatasetId = @DatasetId); 
    IF @RowCountDatasetIds = 0 
        BEGIN; 
        RAISERROR('No rows returned in the ingest Datasets table for this Dataset Id. Please review the details provided', 16, 1) 
        END; 
    ELSE IF @RowCountDatasetIds > 1 
        BEGIN; 
        RAISERROR('More than 1 row returned in the ingest Datasets table for this Dataset Id. Please review the details provided', 16, 1) 
        END; 
    ELSE 
        BEGIN; 
 
        WITH CTE AS ( 
        SELECT 
            CASE 
                WHEN (@Incremental = 1 AND p.FullLoad = 0 AND a.DeltaFilterColumn = 1) THEN 'WHERE ' + a.AttributeName + ' > ''' + CAST(@FilterColumn AS VARCHAR) + '''' 
                ELSE '' 
            END AS FilterContext 
            , ( 
                SELECT ',' + a.AttributeName  
                FROM ingest.Attributes AS a 
                WHERE p.DatasetId = a.DatasetFK 
                FOR XML PATH('')) AS [Attributes] 
            , p.* 
        FROM ingest.Payload AS p 
        INNER JOIN ingest.Attributes AS a 
            ON p.DatasetId = a.DatasetFK 
        WHERE  
                p.DatasetId = @DatasetId 
            AND ( 
                -- FULL LOAD PIPELINE EXECUTION 
                    @Incremental = 0  
                OR  
                -- FULL LOAD ONLY DATASET 
                    p.FullLoad = 1  
                OR ( 
                -- INCREMENTAL LOAD PIPELINE EXECUTION 
                        p.FullLoad = 0  
                    AND  
                        a.DeltaFilterColumn = 1 -- THIS CONDITION RETURNS ONLY ROWS WITH FILTER CONTEXT AGAINST COL USED FOR INCREMENTAL LOADING 
                    ) 
            ) 
        ) 
        SELECT DISTINCT 
            CASE  
                WHEN CTE.ConnectionTypeDisplayName = 'SQL Server' THEN 'SELECT ' + STUFF(CTE.Attributes,1,1,'') + ' FROM ' + CTE.CompleteSource + ' ' + CTE.FilterContext 
                ELSE '' 
            END AS SelectQuery 
            , * 
        FROM CTE 
    END; 
END; 
GO
