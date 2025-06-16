CREATE PROCEDURE [ingest].[AddAttributes]
(
	@ConnectionDisplayName NVARCHAR(50),
	@DatasetDisplayName NVARCHAR(50),
	@VersionNumber INT,
	@AttributeName NVARCHAR(50),
	@AttributeSourceDataType NVARCHAR(50),
	@AttributeTargetDataType NVARCHAR(50),
	@AttributeTargetDataFormat NVARCHAR(500),
	@AttributeDescription NVARCHAR(500),
	@PKAttribute BIT,
	@PartitionByAttribute BIT,
	@Enabled BIT

)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Attributes TABLE (
		ConnectionFK INT NOT NULL,
		ConnectionDisplayName NVARCHAR(50) NOT NULL,
		DatasetFK INT NOT NULL,
		DatasetDisplayName NVARCHAR(50) NOT NULL,
		VersionNumber INT,
		AttributeName NVARCHAR(50) NOT NULL,
		AttributeSourceDataType NVARCHAR(50) NOT NULL,
		AttributeTargetDataType NVARCHAR(50) NOT NULL,
		AttributeTargetDataFormat NVARCHAR(500) NOT NULL,
		AttributeDescription NVARCHAR(500) NULL,
		PKAttribute BIT NOT NULL,
		PartitionByAttribute BIT NOT NULL,
		Enabled BIT NOT NULL
	)

	INSERT INTO @Attributes(ConnectionFK,ConnectionDisplayName,DatasetFK,DatasetDisplayName,VersionNumber,AttributeName,AttributeSourceDataType,AttributeTargetDataType,AttributeTargetDataFormat,AttributeDescription,PKAttribute,PartitionByAttribute,Enabled)
	VALUES (-1,@ConnectionDisplayName,-1,@DatasetDisplayName,@VersionNumber,@AttributeName,@AttributeSourceDataType,@AttributeTargetDataType,@AttributeTargetDataFormat,@AttributeDescription,@PKAttribute,@PartitionByAttribute,@Enabled)

	UPDATE a
	SET a.DatasetFK = d.DatasetId
	FROM @Attributes AS a
	INNER JOIN ingest.Datasets AS d
	ON d.DatasetDisplayName = a.DatasetDisplayName
	AND d.VersionNumber = a.VersionNumber

	IF (SELECT DatasetFK FROM @Attributes) = -1
	BEGIN
		RAISERROR('DatasetFK not updated as the DatasetDisplayName does not exist within ingest.Datasets.',16,1)
		RETURN 0;
	END

	UPDATE a
	SET a.ConnectionFK = c.ConnectionId
	FROM @Attributes AS a
	INNER JOIN common.Connections AS c 
	ON c.ConnectionDisplayName = a.ConnectionDisplayName

	IF (SELECT ConnectionFK FROM @Attributes) = -1
	BEGIN
		RAISERROR('ConnectionFK not updated as the ConnectionDisplayName does not exist within common.Connections.',16,1)
		RETURN 0;
	END
 
	MERGE INTO ingest.Attributes AS Target
	USING @Attributes AS Source
	ON Source.DatasetFK = Target.DatasetFK
	AND Source.AttributeName = Target.AttributeName

	WHEN NOT MATCHED THEN
		INSERT (DatasetFK,AttributeName,AttributeSourceDataType,AttributeTargetDataType,AttributeTargetDataFormat,AttributeDescription,PKAttribute,PartitionByAttribute,Enabled)
		VALUES (
			Source.DatasetFK,
			Source.AttributeName,
			Source.AttributeSourceDataType,
			Source.AttributeTargetDataType,
			Source.AttributeTargetDataFormat,
			Source.AttributeDescription,
			Source.PKAttribute,
			Source.PartitionByAttribute,
			Source.Enabled
			)

	WHEN MATCHED THEN UPDATE SET
		Target.AttributeSourceDataType = Source.AttributeSourceDataType,
		Target.AttributeTargetDataType = Source.AttributeTargetDataType,
		Target.AttributeTargetDataFormat = Source.AttributeTargetDataFormat,
		Target.AttributeDescription = Source.AttributeDescription,
		Target.PKAttribute = Source.PKAttribute,
		Target.PartitionByAttribute = Source.PartitionByAttribute,
		Target.Enabled = Source.Enabled
	;
END