CREATE PROCEDURE [transform].[AddTransformDatasets]
(
	@ComputeConnectionDisplayName NVARCHAR(50),
	@CreateNotebookName NVARCHAR(100),
	@BusinessLogicName NVARCHAR(100),
	@SchemaName NVARCHAR(100),
	@DatasetName NVARCHAR(100),
	@VersionNumber INT,
	@VersionValidFrom DATETIME2(7),
	@VersionValidTo DATETIME2(7),
	@LoadType CHAR(1),
	@LoadStatus INT,
	@LastLoadDate DATETIME2(7),
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TransformDatasets TABLE (
		ComputeConnectionDisplayName NVARCHAR(50),
		ComputeConnectionFK INT,
		CreateNotebookName NVARCHAR(100),
		CreateNotebookFK INT,
		BusinessLogicName NVARCHAR(100),
		BusinessLogicNotebookFK INT,
		SchemaName NVARCHAR(100),
		DatasetName NVARCHAR(100),
		VersionNumber INT,
		VersionValidFrom DATETIME2(7),
		VersionValidTo DATETIME2(7),
		LoadType CHAR(1),
		LoadStatus INT,
		LastLoadDate DATETIME2(7),
		Enabled BIT
	)

	INSERT INTO @TransformDatasets(ComputeConnectionDisplayName, ComputeConnectionFK, CreateNotebookName, CreateNotebookFK, BusinessLogicName, BusinessLogicNotebookFK, SchemaName, DatasetName, VersionNumber, VersionValidFrom, VersionValidTo, LoadType, LoadStatus, LastLoadDate, Enabled)
	VALUES (@ComputeConnectionDisplayName, -1, @CreateNotebookName, -1, @BusinessLogicName, -1, @SchemaName, @DatasetName, @VersionNumber, @VersionValidFrom, @VersionValidTo, @LoadType, @LoadStatus, @LastLoadDate, @Enabled)

	UPDATE td
	SET td.ComputeConnectionFK = c.ComputeConnectionId
	FROM @TransformDatasets AS td
	INNER JOIN common.ComputeConnections AS c
	ON td.ComputeConnectionDisplayName = c.ConnectionDisplayName

	IF (SELECT ComputeConnectionFK FROM @TransformDatasets) = -1
	BEGIN
		RAISERROR('ComputeConnectionFK not updated as the ComputeConnectionDisplayName does not exist within common.ComputeConnections.',16,1)
		RETURN 0;
	END

	UPDATE td
	SET td.CreateNotebookFK = n.NotebookId
	FROM @TransformDatasets AS td
	INNER JOIN transform.Notebooks AS n
	ON td.CreateNotebookName = n.NotebookName

	IF (SELECT CreateNotebookFK FROM @TransformDatasets) = -1
	BEGIN
		RAISERROR('CreateNotebookFK not updated as the CreateNotebookName does not exist within transform.notebooks.',16,1)
		RETURN 0;
	END

	UPDATE td
	SET td.BusinessLogicNotebookFK = n.NotebookId
	FROM @TransformDatasets AS td
	INNER JOIN transform.Notebooks AS n
	ON td.BusinessLogicName = n.NotebookName

	IF (SELECT BusinessLogicNotebookFK FROM @TransformDatasets) = -1
	BEGIN
		RAISERROR('BusinessLogicNotebookFK not updated as the BusinessLogicName does not exist within transform.notebooks.',16,1)
		RETURN 0;
	END

	MERGE INTO transform.Datasets AS Target
	USING @TransformDatasets AS Source
	ON Source.DatasetName = Target.DatasetName
	AND Source.SchemaName = Target.SchemaName

	WHEN NOT MATCHED THEN
		INSERT (ComputeConnectionFK, CreateNotebookFK, BusinessLogicNotebookFK, SchemaName, DatasetName, VersionNumber, VersionValidFrom, VersionValidTo, LoadType, LoadStatus, LastLoadDate, Enabled)
		VALUES (Source.ComputeConnectionFK, 
				Source.CreateNotebookFK, 
				Source.BusinessLogicNotebookFK, 
				Source.SchemaName, 
				Source.DatasetName,  
				Source.VersionNumber, 
				Source.VersionValidFrom, 
				Source.VersionValidTo, 
				Source.LoadType, 
				0, 
				NULL, 
				Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.ComputeConnectionFK = Source.ComputeConnectionFK,
		Target.CreateNotebookFK = Source.CreateNotebookFK,
		Target.BusinessLogicNotebookFK = Source.BusinessLogicNotebookFK,
		Target.VersionNumber = Source.VersionNumber,
		Target.VersionValidFrom = Source.VersionValidFrom,
		Target.VersionValidTo = Source.VersionValidTo,
		Target.LoadType = Source.LoadType,
		Target.Enabled = Source.Enabled
	;
END
GO