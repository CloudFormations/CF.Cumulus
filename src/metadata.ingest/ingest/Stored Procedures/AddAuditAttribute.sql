
CREATE PROCEDURE [ingest].[AddAuditAttribute]
	(
	@AttributeName NVARCHAR(50),
    @LayerName NVARCHAR(50),
    @AttributeDataType NVARCHAR(50),
    @AttributeDataFormat NVARCHAR(50),
    @AttributeDescription NVARCHAR(200),
	@Enabled BIT
	)
AS
BEGIN
	MERGE INTO  [ingest].[AuditAttributes] AS target
		USING 
			(SELECT
				@AttributeName AS AttributeName
                ,@LayerName AS LayerName
                ,@AttributeDataType AS AttributeDataType
                ,@AttributeDataFormat AS AttributeDataFormat
                ,@AttributeDescription AS AttributeDescription
                ,@Enabled AS Enabled
            ) AS source (AttributeName,LayerName,AttributeDataType,AttributeDataFormat,AttributeDescription,Enabled)
		ON ( target.AttributeName = source.AttributeName AND target.LayerName = source.LayerName)
		WHEN MATCHED
			THEN UPDATE
				SET 
                    AttributeName = source.AttributeName
                    ,LayerName = source.LayerName
                    ,AttributeDataType = source.AttributeDataType
                    ,AttributeDataFormat = source.AttributeDataFormat
                    ,AttributeDescription = source.AttributeDescription
                    ,Enabled = source.Enabled
		WHEN NOT MATCHED
			THEN INSERT
				(
					AttributeName
                    ,LayerName
                    ,AttributeDataType
                    ,AttributeDataFormat
                    ,AttributeDescription
                    ,Enabled
				)
			VALUES
				(   
                    source.AttributeName
                    ,source.LayerName
                    ,source.AttributeDataType
                    ,source.AttributeDataFormat
                    ,source.AttributeDescription
                    ,source.Enabled
				);
END;
GO
