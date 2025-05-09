CREATE PROCEDURE ##AddComputeConnections
(
	@ConnectionTypeDisplayName NVARCHAR(50),
	@ConnectionDisplayName NVARCHAR(50),
	@ConnectionLocation NVARCHAR(200),
	@ComputeLocation NVARCHAR(200),
	@ComputeSize NVARCHAR(200),
	@ComputeVersion NVARCHAR(100),
	@CountNodes INT,
	@ResourceName NVARCHAR(100),
	@LinkedServiceName NVARCHAR(200),
	@EnvironmentName NVARCHAR(10),
	@Enabled BIT

)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ComputeConnections TABLE (
		ConnectionTypeFK INT NOT NULL,
		ConnectionTypeDisplayName NVARCHAR(50),
		ConnectionDisplayName NVARCHAR(50) NOT NULL,
		ConnectionLocation NVARCHAR(200),
		ComputeLocation NVARCHAR(200),
		ComputeSize NVARCHAR(200) NOT NULL,
		ComputeVersion NVARCHAR(100) NOT NULL,
		CountNodes INT NOT NULL,
		ResourceName NVARCHAR(100),
		LinkedServiceName NVARCHAR(200) NOT NULL,
		EnvironmentName NVARCHAR(10),
		Enabled BIT NOT NULL
	)

	INSERT INTO @ComputeConnections(ConnectionTypeFK, ConnectionTypeDisplayName, ConnectionDisplayName, ConnectionLocation, ComputeLocation, ComputeSize, ComputeVersion, CountNodes, ResourceName, LinkedServiceName, EnvironmentName, Enabled)
	VALUES (-1, @ConnectionTypeDisplayName, @ConnectionDisplayName, @ConnectionLocation, @ComputeLocation, @ComputeSize, @ComputeVersion, @CountNodes, @ResourceName, @LinkedServiceName, @EnvironmentName, @Enabled)

	UPDATE c
	SET c.ConnectionTypeFK = ct.ConnectionTypeId
	FROM @ComputeConnections AS c
	INNER JOIN common.ConnectionTypes AS ct
	ON ct.ConnectionTypeDisplayName = c.ConnectionTypeDisplayName

	IF (SELECT ConnectionTypeFK FROM @ComputeConnections) = -1
	BEGIN
		RAISERROR('ConnectionTypeFK not updated as the ConnectionTypeDisplayName does not exist within common.ConnectionTypes.',16,1)
		RETURN 0;
	END


	MERGE INTO common.ComputeConnections AS Target
	USING @ComputeConnections AS Source
	ON Source.ConnectionDisplayName = Target.ConnectionDisplayName
	AND Source.ConnectionLocation = Target.ConnectionLocation
	AND Source.ComputeLocation = Target.ComputeLocation

	WHEN NOT MATCHED THEN
		INSERT (ConnectionTypeFK, ConnectionDisplayName, ConnectionLocation, ComputeLocation, ComputeSize, ComputeVersion, CountNodes, ResourceName, LinkedServiceName, EnvironmentName, Enabled)
		VALUES (Source.ConnectionTypeFK, Source.ConnectionDisplayName, Source.ConnectionLocation, Source.ComputeLocation, Source.ComputeSize, Source.ComputeVersion, Source.CountNodes, Source.ResourceName, Source.LinkedServiceName, Source.EnvironmentName, Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.ConnectionTypeFK = Source.ConnectionTypeFK,
		Target.ComputeSize = Source.ComputeSize,
		Target.ComputeVersion = Source.ComputeVersion,
		Target.CountNodes = Source.CountNodes,
		Target.ResourceName = Source.ResourceName,
		Target.LinkedServiceName = Source.LinkedServiceName,
		Target.EnvironmentName = Source.EnvironmentName,
		Target.Enabled = Source.Enabled
	;
END
GO
