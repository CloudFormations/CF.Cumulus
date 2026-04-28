CREATE PROCEDURE [transform].[AddNotebooks]
(
	@ComputeConnectionDisplayName NVARCHAR(50),
	@NotebookTypeName NVARCHAR(100),
	@NotebookName NVARCHAR(100),
	@NotebookPath NVARCHAR(500),
	@Enabled BIT = 1
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Notebooks TABLE (
		[ComputeConnectionDisplayName] NVARCHAR(50),
		[ComputeConnectionFK] INT,
		[NotebookTypeName] NVARCHAR(100),
		[NotebookTypeFK] INT,
		[NotebookName] NVARCHAR(100),
		[NotebookPath] NVARCHAR(500),
		[Enabled] BIT
	)

	INSERT INTO @Notebooks(ComputeConnectionDisplayName, ComputeConnectionFK, NotebookTypeName, NotebookTypeFK, NotebookName, NotebookPath, Enabled)
	VALUES(@ComputeConnectionDisplayName, -1, @NotebookTypeName, -1, @NotebookName, @NotebookPath, @Enabled)

	UPDATE n
	SET n.ComputeConnectionFK = c.ComputeConnectionId
	FROM @Notebooks AS n
	INNER JOIN common.ComputeConnections AS c
	ON n.ComputeConnectionDisplayName = c.ConnectionDisplayName

	IF (SELECT ComputeConnectionFK FROM @Notebooks) = -1
	BEGIN
		RAISERROR('ComputeConnectionFK not updated as the ComputeConnectionDisplayName does not exist within common.ComputeConnections.',16,1)
		RETURN 0;
	END

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

	WHEN NOT MATCHED BY Target THEN
		INSERT (NotebookTypeFK, ComputeConnectionFK, NotebookName, NotebookPath, Enabled) 
		VALUES (Source.NotebookTypeFK, Source.ComputeConnectionFK, Source.NotebookName, Source.NotebookPath, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.NotebookTypeFK = Source.NotebookTypeFK,
		Target.ComputeConnectionFK = Source.ComputeConnectionFK,
		Target.NotebookPath = Source.NotebookPath,
		Target.Enabled = Source.Enabled
	;
END
GO