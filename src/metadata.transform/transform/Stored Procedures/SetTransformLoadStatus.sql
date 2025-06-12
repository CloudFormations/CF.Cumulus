CREATE PROCEDURE [transform].[SetTransformLoadStatus]
(
    @DatasetId INT,
    @FileLoadDateTime DATETIME2
)
AS
BEGIN

-- Defensive check for DatasetId parameter
DECLARE @ResultRowCount INT

SELECT 
    @ResultRowCount = COUNT(*)
FROM
[transform].[Datasets] ds
WHERE
ds.[DatasetId] = @DatasetId
AND 
    ds.[Enabled] = 1

IF @ResultRowCount = 0
BEGIN
    RAISERROR('No results returned for the provided Dataset Id. Confirm Dataset is enabled, and related Connections are enabled.',16,1)
	RETURN 0;
END

UPDATE [transform].[Datasets]
SET LoadStatus = 1,
    LastLoadDate = @FileLoadDateTime
WHERE DatasetId = @DatasetId

END