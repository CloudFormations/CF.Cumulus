
	CREATE PROCEDURE [ingest].[getlatestrefreshtoken]
	(
	@DatasetId INT
	)
	AS
	BEGIN

		DECLARE @ConnectionId INT

		SELECT @ConnectionID = ConnectionFK
		FROM [ingest].[Datasets]
		WHERE DatasetId = @DatasetId

		-- Defensive Programming Check - Ensure record exists for ConnectionFK in [ingest].[APITokens] table
		DECLARE @Counter INT

		SELECT @Counter = COUNT(*)
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId

		IF @COUNTER = 0
		BEGIN
			RAISERROR('No results returned for the provided Connection Id. Confirm Refresh Token logic is required for this API, and populate initial values as required.',16,1)
			RETURN 0;
		END

		-- Defensive Programming Check - Ensure Refresh Token Expiry Date is in the future
		DECLARE @RefreshTokenValid BIT
		SELECT TOP 1
			@RefreshTokenValid = CASE 
				WHEN RefreshTokenExpiryDateTime > GETDATE() THEN 1
				ELSE 0
			END
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId
		ORDER BY APITokenId DESC
	
		IF @RefreshTokenValid = 0
		BEGIN
			RAISERROR('Latest Refresh Token has expired, Please review and update metadata accordingly.',16,1)
			RETURN 0;
		END

		-- SELECT Statement
		SELECT TOP 1
			IdentityToken,
			IdentityTokenExpiryDateTime,
			RefreshToken,
			RefreshTokenExpiryDateTime
		FROM [ingest].[APITokens]
		WHERE ConnectionFK = @ConnectionId
		ORDER BY APITokenId DESC


	END

GO

