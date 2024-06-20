CREATE PROCEDURE [transform].[SetTransformLoadStatus]
(
    @DatasetId INT,
    @FileLoadDateTime DATETIME2
)
AS
BEGIN

UPDATE [transform].[Datasets]
SET LoadStatus = 1,
    LastLoadDate = @FileLoadDateTime
WHERE DatasetId = @DatasetId

END