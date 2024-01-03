CREATE PROCEDURE [procfwkHelpers].[SetDefaultAlertOutcomes]
AS
BEGIN
	TRUNCATE TABLE [cumulus.control].[AlertOutcomes];

	INSERT INTO [cumulus.control].[AlertOutcomes] 
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