CREATE PROCEDURE [procfwkHelpers].[SetDefaultAlertOutcomes]
AS
BEGIN
	TRUNCATE TABLE [control].[AlertOutcomes];

	INSERT INTO [control].[AlertOutcomes] 
		(
		[PipelineOutcomeStatus]
		)
	VALUES 
		('All'),
		('Success'),
		('Failed'),
		('Unknown'),
		('Cancelled');
END;