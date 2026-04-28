CREATE PROCEDURE [ingest].[SetLatestRefreshToken]
(
@Input NVARCHAR(MAX),
@DatasetId INT
) AS
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

	
	-- INSERT Statement
	INSERT INTO [ingest].[APITokens] (ConnectionFK, IdentityToken, IdentityTokenExpiryDateTime, RefreshToken, RefreshTokenExpiryDateTime)
	SELECT @ConnectionId, IdentityToken, IdentityTokenExpiryDateTime, RefreshToken, RefreshTokenExpiryDateTime
	FROM OPENJSON(@input)
	WITH (
		IdentityToken NVARCHAR(MAX) '$.identityToken',
		IdentityTokenExpiryDateTime NVARCHAR(MAX) '$.identityTokenExpires',
		RefreshToken NVARCHAR(MAX) '$.refreshToken',
		RefreshTokenExpiryDateTime NVARCHAR(MAX) '$.refreshTokenExpires'
	);

END