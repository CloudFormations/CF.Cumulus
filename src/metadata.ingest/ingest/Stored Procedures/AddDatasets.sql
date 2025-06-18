CREATE PROCEDURE [ingest].[AddDatasets]
(
	@ConnectionDisplayName NVARCHAR(50),
	@LinkedServiceName NVARCHAR(200),
	@ResourceName NVARCHAR(100),
	@ComputeConnectionDisplayName NVARCHAR(50),
	@DatasetDisplayName NVARCHAR(50),
	@SourcePath NVARCHAR(100),
	@SourceName NVARCHAR(100),
	@ExtensionType NVARCHAR(100),
	@VersionNumber INT,
	@VersionValidFrom DATETIME2(7),
	@VersionValidTo DATETIME2(7),
	@LoadType CHAR(1),
	@LoadStatus INT,
	@OverrideLoadStatus BIT,
	@LoadClause NVARCHAR(MAX),
	@CleansedPath NVARCHAR(100),
	@CleansedName NVARCHAR(100),
	@Enabled BIT

)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Datasets TABLE (
		ConnectionFK INT NOT NULL,
		ConnectionDisplayName NVARCHAR(50),
		LinkedServiceName NVARCHAR(200),
		ResourceName NVARCHAR(100),
		MergeComputeConnectionFK INT,
		ComputeConnectionDisplayName NVARCHAR(50),
		DatasetDisplayName NVARCHAR(50) NOT NULL,
		SourcePath NVARCHAR(100) NOT NULL,
		SourceName NVARCHAR(100)NOT NULL,
		ExtensionType NVARCHAR(100),
		VersionNumber INT NOT NULL,
		VersionValidFrom DATETIME2(7),
		VersionValidTo DATETIME2(7),
		LoadType CHAR(1) NOT NULL,
		LoadStatus INT NOT NULL,
		OverrideLoadStatus BIT NOT NULL,
		LoadClause NVARCHAR(MAX),
		CleansedPath NVARCHAR(100) NOT NULL,
		CleansedName NVARCHAR(100) NOT NULL,
		Enabled BIT NOT NULL
	)

	INSERT INTO @Datasets(ConnectionFK, ConnectionDisplayName, LinkedServiceName, ResourceName, MergeComputeConnectionFK, ComputeConnectionDisplayName, 
						DatasetDisplayName, SourcePath, SourceName, ExtensionType, VersionNumber, VersionValidFrom, VersionValidTo, 
						LoadType, LoadStatus, OverrideLoadStatus, LoadClause, CleansedPath, CleansedName, Enabled)
	VALUES (-1, @ConnectionDisplayName, @LinkedServiceName, @ResourceName, -1, @ComputeConnectionDisplayName, @DatasetDisplayName, @SourcePath, @SourceName, 
			@ExtensionType, @VersionNumber, @VersionValidFrom, @VersionValidTo, @LoadType, @LoadStatus, @OverrideLoadStatus, @LoadClause, 
			@CleansedPath, @CleansedName, @Enabled)

	UPDATE d
	SET d.ConnectionFK = c.ConnectionId
	FROM @Datasets AS d
	INNER JOIN common.Connections AS c
	ON c.ConnectionDisplayName = d.ConnectionDisplayName
	AND c.LinkedServiceName = d.LinkedServiceName
	AND c.ResourceName = d.ResourceName

	IF (SELECT ConnectionFK FROM @Datasets) = -1
	BEGIN
		RAISERROR('ConnectionFK not updated as the ConnectionDisplayName / LinkedServiceName combination of values does not exist within common.ConnectionTypes.',16,1)
		RETURN 0;
	END

	UPDATE d
	SET d.MergeComputeConnectionFK = c.ComputeConnectionId
	FROM @Datasets AS d
	INNER JOIN common.ComputeConnections AS c
	ON c.ConnectionDisplayName = d.ComputeConnectionDisplayName


	IF (SELECT MergeComputeConnectionFK FROM @Datasets) = -1
	BEGIN
		RAISERROR('MergeComputeConnectionFK not updated as the ComputeConnectionTypeDisplayName does not exist within common.ComputeConnections.',16,1)
		RETURN 0;
	END

	MERGE INTO ingest.Datasets AS Target
	USING @Datasets AS Source
	ON Source.DatasetDisplayName = Target.DatasetDisplayName
	AND Source.ConnectionFK = Target.ConnectionFK


	WHEN NOT MATCHED THEN
		INSERT (ConnectionFK, 
				MergeComputeConnectionFK, 
				DatasetDisplayName, 
				SourcePath, 
				SourceName, 
				ExtensionType, 
				VersionNumber, 
				VersionValidFrom, 
				VersionValidTo, 
				LoadType, 
				LoadStatus, 
				LoadClause, 
				RawLastFullLoadDate, 
				RawLastIncrementalLoadDate, 
				CleansedPath, 
				CleansedName, 
				CleansedLastFullLoadDate, 
				CleansedLastIncrementalLoadDate, 
				Enabled)
		VALUES (Source.ConnectionFK, 
				Source.MergeComputeConnectionFK, 
				Source.DatasetDisplayName, 
				Source.SourcePath, 
				Source.SourceName, 
				Source.ExtensionType, 
				Source.VersionNumber, 
				Source.VersionValidFrom, 
				Source.VersionValidTo, 
				Source.LoadType, 
				CASE WHEN Source.OverrideLoadStatus = 1 THEN Source.LoadStatus ELSE 0 END, 
				Source.LoadClause, 
				NULL, 
				NULL, 
				Source.CleansedPath, 
				Source.CleansedName,
				NULL, 
				NULL, 
				Source.Enabled)

	WHEN MATCHED THEN UPDATE SET
		Target.MergeComputeConnectionFK = Source.MergeComputeConnectionFK,
		Target.SourcePath = Source.SourcePath,
		Target.SourceName = Source.SourceName,
		Target.ExtensionType = Source.ExtensionType,
		Target.VersionNumber = Source.VersionNumber,
		Target.VersionValidFrom = Source.VersionValidFrom,
		Target.VersionValidTo = Source.VersionValidTo,
		Target.LoadType = Source.LoadType,
		Target.LoadStatus = CASE WHEN Source.OverrideLoadStatus = 1 THEN Source.LoadStatus ELSE Target.LoadStatus END,
		Target.LoadClause = Source.LoadClause,
		Target.CleansedPath = Source.CleansedPath,
		Target.CleansedName = Source.CleansedName,
		Target.Enabled = Source.Enabled
	;
END
GO