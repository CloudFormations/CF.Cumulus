CREATE PROCEDURE ##AddNotebooks
(
	@NotebookTypeName NVARCHAR(100),
	@NotebookName NVARCHAR(100),
	@NotebookPath NVARCHAR(500),
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Notebooks TABLE (
		NotebookTypeName NVARCHAR(100),
		NotebookTypeFK INT,
		NotebookName NVARCHAR(100),
		NotebookPath NVARCHAR(500),
		Enabled BIT
	)

	INSERT INTO @Notebooks(NotebookTypeName, NotebookTypeFK, NotebookName, NotebookPath, Enabled)
	VALUES(@NotebookTypeName, -1, @NotebookName, @NotebookPath, @Enabled)

	UPDATE n
	SET n.NotebookTypeFK = nt.NotebookTypeId
	FROM @Notebooks AS n
	INNER JOIN transform.NotebookTypes AS nt
	ON n.NotebookTypeName = nt.NotebookTypeName

	IF (SELECT NotebookTypeFK FROM @Notebooks) = -1
	BEGIN
		RAISERROR('NotebookTypeFK not updated as the NotebookTypeName does not exist within Transform.NotebookTypes.',16,1)
		RETURN 0;
	END

	MERGE INTO transform.Notebooks AS Target
	USING @Notebooks AS Source
	ON Source.NotebookName = Target.NotebookName 
	AND Source.NotebookPath = Target.NotebookPath

	WHEN NOT MATCHED BY Target THEN
		INSERT (NotebookTypeFK, NotebookName, NotebookPath, Enabled) 
		VALUES (Source.NotebookTypeFK, Source.NotebookName, Source.NotebookPath, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.NotebookTypeFK = Source.NotebookTypeFK,
		Target.Enabled = Source.Enabled
	;
END
GO