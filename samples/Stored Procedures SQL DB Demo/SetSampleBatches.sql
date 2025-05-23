CREATE PROCEDURE [samples].[SetSampleBatches]
AS
BEGIN
	DECLARE @Batches TABLE
		(
		[BatchName] [VARCHAR](225) NOT NULL,
		[BatchDescription] [VARCHAR](4000) NULL,
		[Enabled] [BIT] NOT NULL
		)
	
	INSERT @Batches
		(
		[BatchName], 
		[BatchDescription], 
		[Enabled]
		) 
	VALUES 
		('Daily', N'Daily Worker Pipelines.', 1),
		('Hourly', N'Hourly Worker Pipelines.', 1),	
		('ControlDemoDaily', N'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1),	
		('ControlDemoHourly', N'Ad-hoc Demo Batch for Control Wait pipeline executions.', 1);	

	MERGE INTO [control].[Batches] AS tgt
	USING 
		@Batches AS src
			ON tgt.[BatchName] = src.[BatchName]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[BatchDescription] = src.[BatchDescription],
			tgt.[Enabled] = src.[Enabled]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[BatchName],
			[BatchDescription],
			[Enabled]
			)
		VALUES
			(
			src.[BatchName],
			src.[BatchDescription],
			src.[Enabled]
			)
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE;	
END;