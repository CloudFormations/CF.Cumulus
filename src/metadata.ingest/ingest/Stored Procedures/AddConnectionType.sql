CREATE PROCEDURE [ingest].[AddConnectionType]
	(
	@ConnectionTypeDisplayName NVARCHAR(128),
	@Enabled BIT
	)
AS
BEGIN
	MERGE INTO  [ingest].[ConnectionTypes] AS target
		USING 
			(SELECT
				@ConnectionTypeDisplayName AS ConnectionTypeDisplayName
				, @Enabled AS Enabled
			) AS source (ConnectionTypeDisplayName, Enabled)
		ON ( target.ConnectionTypeDisplayName = source.ConnectionTypeDisplayName )
		WHEN MATCHED
			THEN UPDATE
				SET Enabled = source.Enabled
		WHEN NOT MATCHED
			THEN INSERT
				(
					ConnectionTypeDisplayName
					, Enabled
				)
			VALUES
				(
					source.ConnectionTypeDisplayName
					, source.Enabled
				);
END;