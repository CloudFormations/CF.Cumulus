CREATE PROCEDURE [transform].[AddTransformAttributes]
(
	@DatasetName NVARCHAR(100),
	@DatasetSchema NVARCHAR(100),
	@AttributeName NVARCHAR(100),
	@AttributeTargetDataType NVARCHAR(50),
	@AttributeDescription NVARCHAR(200),
	@BKAttribute BIT,
	@SurrogateKeyAttribute BIT,
	@PartitionByAttribute BIT,
	@Enabled BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Attributes TABLE (
		DatasetName NVARCHAR(100),
		DatasetSchema NVARCHAR(100),
		DatasetFK INT,
		AttributeName NVARCHAR(100),
		AttributeTargetDataType NVARCHAR(50),
		AttributeDescription NVARCHAR(200),
		BKAttribute BIT,
		SurrogateKeyAttribute BIT,
		PartitionByAttribute BIT,
		Enabled BIT
	)

	INSERT INTO @Attributes(DatasetName, DatasetSchema, DatasetFK, AttributeName, AttributeTargetDataType, AttributeDescription, BKAttribute, SurrogateKeyAttribute, PartitionByAttribute, Enabled)
	VALUES (@DatasetName, @DatasetSchema, -1, @AttributeName, @AttributeTargetDataType, @AttributeDescription, @BKAttribute, @SurrogateKeyAttribute, @PartitionByAttribute, @Enabled)

	UPDATE a
	SET a.DatasetFK = d.DatasetId
	FROM @Attributes AS a
	INNER JOIN transform.Datasets AS d
	ON a.DatasetName = d.DatasetName
	AND a.DatasetSchema = d.SchemaName

	IF (SELECT DatasetFK FROM @Attributes) = -1
	BEGIN
		RAISERROR('DatasetFK not updated as a DatasetName with the SchemaName does not exist within transform.Datasets.',16,1)
		RETURN 0;
	END

	MERGE INTO transform.Attributes AS Target
	USING @Attributes AS Source
	ON Source.AttributeName = Target.AttributeName
	AND Source.DatasetFK = Target.DatasetFK

	WHEN NOT MATCHED THEN
		INSERT (DatasetFK, AttributeName, AttributeTargetDataType, AttributeDescription, BKAttribute, SurrogateKeyAttribute, PartitionByAttribute, Enabled)
		VALUES (Source.DatasetFK,
				Source.AttributeName,
				Source.AttributeTargetDataType,
				Source.AttributeDescription,
				Source.BKAttribute,
				Source.SurrogateKeyAttribute,
				Source.PartitionByAttribute,
				Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.DatasetFK = Source.DatasetFK,
		Target.AttributeTargetDataType = Source.AttributeTargetDataType,
		Target.AttributeDescription = Source.AttributeDescription,
		Target.BKAttribute = Source.BKAttribute,
		Target.SurrogateKeyAttribute = Source.SurrogateKeyAttribute,
		Target.PartitionByAttribute = Source.PartitionByAttribute,
		Target.Enabled = Source.Enabled
	;
END
GO
