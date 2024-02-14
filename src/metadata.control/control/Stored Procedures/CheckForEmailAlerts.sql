CREATE PROCEDURE [control].[CheckForEmailAlerts]
	(
	@PipelineId INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SendAlerts BIT
	DECLARE @AlertingEnabled BIT

	--get property
	SELECT
		@AlertingEnabled = [control].[GetPropertyValueInternal]('UseFrameworkEmailAlerting');

	--based on global property
	IF (@AlertingEnabled = 1)
		BEGIN
			--based on piplines to recipients link
			IF EXISTS
				(
				SELECT 
					pal.AlertId
				FROM 
					[control].CurrentExecution AS ce
					INNER JOIN [control].AlertOutcomes AS ao
						ON ao.PipelineOutcomeStatus = ce.PipelineStatus
					INNER JOIN [control].PipelineAlertLink AS pal
						ON pal.PipelineId = ce.PipelineId
					INNER JOIN [control].Recipients AS r
						ON r.RecipientId = pal.RecipientId
				WHERE 
					ce.PipelineId = @PipelineId
					   AND (
						ao.BitValue & pal.OutcomesBitValue <> 0
						OR pal.OutcomesBitValue & 1 <> 0 --all
						)
					  AND pal.[Enabled] = 1
					  AND r.[Enabled] = 1
				)
				BEGIN
					SET @SendAlerts = 1;
				END;
			ELSE
				BEGIN
					SET @SendAlerts = 0;
				END;
		END
	ELSE
		BEGIN
			SET @SendAlerts = 0;
		END;

	SELECT @SendAlerts AS SendAlerts
END;