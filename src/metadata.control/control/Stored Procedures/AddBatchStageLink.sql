CREATE PROCEDURE ##AddBatchStageLink
(
	@BatchName VARCHAR(255),
	@StageName VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @BatchStageLink TABLE (
		BatchId UNIQUEIDENTIFIER NOT NULL,
		StageId INT NOT NULL
	)

	DECLARE @BatchId UNIQUEIDENTIFIER;
	DECLARE @StageId INT;

	SELECT 
		@BatchId = b.BatchId
	FROM control.Batches AS b
	WHERE b.BatchName = @BatchName;

	SELECT
		@StageId = s.StageId
	FROM control.Stages AS s
	WHERE s.StageName = @StageName;

	INSERT INTO @BatchStageLink (BatchId, StageId)
	VALUES (@BatchId,@StageId)

	MERGE INTO control.BatchStageLink AS Target
	USING @BatchStageLink AS Source
	ON Source.BatchId = Target.BatchId 
	AND Source.StageId = Target.StageId

	WHEN NOT MATCHED BY Target THEN
		INSERT (BatchId, StageId) 
		VALUES (Source.BatchId, Source.StageId)
	;
END
GO