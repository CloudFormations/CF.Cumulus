CREATE PROCEDURE ##AddBatches
(
	@BatchName VARCHAR(255),
	@BatchDescription VARCHAR(4000),
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS 
	(
		SELECT
		@BatchName AS BatchName,
		@BatchDescription AS BatchDescription,
		@Enabled AS Enabled
	)
	MERGE INTO control.Batches AS Target
	USING cte AS Source
	ON Source.BatchName = Target.BatchName

	WHEN NOT MATCHED THEN
		INSERT (BatchName, BatchDescription, Enabled) 
		VALUES (Source.BatchName, Source.BatchDescription, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.BatchDescription	= Source.BatchDescription,
		Target.Enabled			= Source.Enabled
	;
END
GO