
CREATE PROCEDURE [common].[AddConnectionType]
	(
	@ConnectionTypeDisplayName NVARCHAR(128),
    @SourceLanguageType NVARCHAR(5),
	@Enabled BIT
	)
AS
BEGIN
	MERGE INTO  [common].[ConnectionTypes] AS target
		USING 
			(SELECT
				@ConnectionTypeDisplayName AS ConnectionTypeDisplayName
				, @SourceLanguageType AS SourceLanguageType
				, @Enabled AS Enabled
			) AS source (ConnectionTypeDisplayName, SourceLanguageType, Enabled)
		ON ( target.ConnectionTypeDisplayName = source.ConnectionTypeDisplayName )
		WHEN MATCHED
			THEN UPDATE
				SET 
                    SourceLanguageType = source.SourceLanguageType
                    , Enabled = source.Enabled
		WHEN NOT MATCHED
			THEN INSERT
				(
					SourceLanguageType
                    , ConnectionTypeDisplayName
					, Enabled
				)
			VALUES
				(   
                    source.SourceLanguageType
					, source.ConnectionTypeDisplayName
					, source.Enabled
				);
END;
GO
