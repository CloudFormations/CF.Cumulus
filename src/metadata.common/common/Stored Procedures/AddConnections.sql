CREATE PROCEDURE ##AddConnections
(
	@ConnectionTypeDisplayName NVARCHAR(50),
	@ConnectionDisplayName NVARCHAR(50),
	@ConnectionLocation NVARCHAR(200),
	@ConnectionPort NVARCHAR(50),
	@SourceLocation NVARCHAR(200),
	@ResourceName NVARCHAR(100),
	@LinkedServiceName NVARCHAR(200),
	@Username NVARCHAR(150),
	@KeyVaultSecret NVARCHAR(150),
	@Enabled BIT

)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Connections TABLE (
		ConnectionTypeFK INT NOT NULL,
		ConnectionTypeDisplayName NVARCHAR(50) NOT NULL,
		ConnectionDisplayName NVARCHAR(50) NOT NULL,
		ConnectionLocation NVARCHAR(200),
		ConnectionPort NVARCHAR(50),
		SourceLocation NVARCHAR(200) NOT NULL,
		ResourceName NVARCHAR(100),
		LinkedServiceName NVARCHAR(200) NOT NULL,
		Username NVARCHAR(150) NOT NULL,
		KeyVaultSecret NVARCHAR(150) NOT NULL,
		Enabled BIT NOT NULL
	)

	INSERT INTO @Connections(ConnectionTypeFK, ConnectiontypeDisplayName, ConnectionDisplayName, ConnectionLocation, ConnectionPort, SourceLocation, ResourceName, LinkedServiceName, Username, KeyVaultSecret, Enabled)
	VALUES (-1, @ConnectionTypeDisplayName, @ConnectionDisplayName, @ConnectionLocation, @ConnectionPort, @SourceLocation, @ResourceName, @LinkedServiceName, @Username, @KeyVaultSecret, @Enabled)

	UPDATE c
	SET c.ConnectionTypeFK = ct.ConnectionTypeId
	FROM @Connections AS c
	INNER JOIN common.ConnectionTypes AS ct
	ON ct.ConnectionTypeDisplayName = c.ConnectionTypeDisplayName

	IF (SELECT ConnectionTypeFK FROM @Connections) = -1
	BEGIN
		RAISERROR('ConnectionTypeFK not updated as the ConnectionTypeDisplayName does not exist within common.ConnectionTypes.',16,1)
		RETURN 0;
	END

	MERGE INTO common.Connections AS Target
	USING @Connections AS Source
	ON Source.ConnectionDisplayName = Target.ConnectionDisplayName
	AND Source.ConnectionLocation = Target.ConnectionLocation
	AND Source.LinkedServiceName = Target.LinkedServiceName
	AND Source.SourceLocation = Target.SourceLocation

	WHEN NOT MATCHED THEN
		INSERT (ConnectionTypeFK, ConnectionDisplayName, ConnectionLocation, ConnectionPort, SourceLocation, ResourceName, LinkedServiceName, Username, KeyVaultSecret, Enabled)
		VALUES (Source.ConnectionTypeFK, Source.ConnectionDisplayName, Source.ConnectionLocation, Source.ConnectionPort, Source.SourceLocation, Source.ResourceName, Source.LinkedServiceName, Source.Username, Source.KeyVaultSecret, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.ConnectionTypeFK = Source.ConnectionTypeFK,
		Target.ConnectionPort = Source.ConnectionPort,
		Target.ResourceName = Source.ResourceName,
		Target.Username = Source.Username,
		Target.KeyVaultSecret = Source.KeyVaultSecret,
		Target.Enabled = Source.Enabled
	;
END
GO