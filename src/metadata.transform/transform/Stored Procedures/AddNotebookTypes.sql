CREATE PROCEDURE ##AddNotebookTypes
(
	@NotebookTypeName NVARCHAR(100),
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS 
	(
		SELECT
		@NotebookTypeName AS NotebookTypeName,
		@Enabled AS Enabled
	)
	MERGE INTO transform.NotebookTypes AS Target
	USING cte AS Source
	ON Source.NotebookTypeName = Target.NotebookTypeName

	WHEN NOT MATCHED THEN
		INSERT (NotebookTypeName, Enabled) 
		VALUES (Source.NotebookTypeName, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.Enabled			= Source.Enabled
	;
END
GO