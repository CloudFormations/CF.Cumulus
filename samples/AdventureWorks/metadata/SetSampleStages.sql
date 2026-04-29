CREATE PROCEDURE [samples].[SetSampleStages]
AS
BEGIN
	DECLARE @Stages TABLE
		(
		[StageName] [VARCHAR](225) NOT NULL,
		[StageDescription] [VARCHAR](4000) NULL,
		[Enabled] [BIT] NOT NULL
		)
	
	INSERT @Stages
		(
		[StageName], 
		[StageDescription], 
		[Enabled]
		) 
	VALUES 
		('Raw', N'Ingest all data from source systems.', 1),
		('Cleansed', N'Merge Raw data into Delta Tables.', 1),
		('Curated', N'Transform cleansed data and apply business logic.', 1),
		('Serve', N'Load Curated data into semantic layer.', 0),
		('Speed', N'Regular loading of frequently used data.', 0),
		('ControlRaw', N'Demo of wait pipelines representing Raw load .', 0),
		('ControlCleansed', N'Demo of wait pipelines representing cleansed load.', 0),
		('ControlSpeed', N'Demo of wait pipelines loading of frequently used data.', 0);

	MERGE INTO [control].[Stages] AS tgt
	USING 
		@Stages AS src
			ON tgt.[StageName] = src.[StageName]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[StageDescription] = src.[StageDescription],
			tgt.[Enabled] = src.[Enabled]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[StageName],
			[StageDescription],
			[Enabled]
			)
		VALUES
			(
			src.[StageName],
			src.[StageDescription],
			src.[Enabled]
			)
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE;	
END;