CREATE PROCEDURE [ingest].[SetDatasetFirstLoadMetadata]
	(
	@DatasetId INT,
    @PipelineRunDateTime DATETIME2
	
	)
AS
BEGIN
	
    UPDATE [ingest].[Datasets]
    SET FirstLoad = 0,
    FirstLoadCompleteDate = @PipelineRunDateTime
    WHERE DatasetId = @DatasetId

END

GO

