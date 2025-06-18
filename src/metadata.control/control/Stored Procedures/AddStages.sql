CREATE PROCEDURE [control].[AddStages]
(
	@StageName VARCHAR(255),
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
		@StageDescription AS StageDescription,
		@Enabled AS Enabled
	)
	MERGE INTO control.Stages AS Target
	USING cte AS Source
	ON Source.StageName = Target.StageName

	WHEN NOT MATCHED THEN
		INSERT (StageName, StageDescription, Enabled) 
		VALUES (Source.StageName, Source.StageDescription, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.StageDescription	= Source.StageDescription,
		Target.Enabled			= Source.Enabled
	;
END
GO