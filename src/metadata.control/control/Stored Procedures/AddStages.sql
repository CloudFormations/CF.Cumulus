CREATE PROCEDURE [control].[AddStages]
(
	@StageName VARCHAR(255),
	@ExecutionOrderId INT,
	@StageDescription VARCHAR(4000),
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS
	(
		SELECT
		@StageName AS StageName,
		@ExecutionOrderId AS ExecutionOrderId,
		@StageDescription AS StageDescription,
		@Enabled AS Enabled
	)
	MERGE INTO control.Stages AS Target
	USING cte AS Source
	ON Source.StageName = Target.StageName

	WHEN NOT MATCHED THEN
		INSERT (StageName, ExecutionOrderId, StageDescription, Enabled) 
		VALUES (Source.StageName, Source.ExecutionOrderId, Source.StageDescription, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.ExecutionOrderId = Source.ExecutionOrderId,
		Target.StageDescription	= Source.StageDescription,
		Target.Enabled			= Source.Enabled
	;
END
GO