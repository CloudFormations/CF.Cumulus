﻿CREATE PROCEDURE [procfwkHelpers].[AddRecipientPipelineAlerts]
	(
	@RecipientName VARCHAR(255),
	@PipelineName NVARCHAR(200) = NULL,
	@AlertForStatus NVARCHAR(500) = 'All'
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ActualBitValue INT
	DECLARE @SQL NVARCHAR(MAX) = ''
	DECLARE @BitValue TABLE ([TotalBitValue] INT NOT NULL);

	--get alert status bit value
	SET @AlertForStatus = LTRIM(RTRIM(@AlertForStatus))
	SET @AlertForStatus = REPLACE(@AlertForStatus,' ','')
	SET @AlertForStatus = '''' + REPLACE(@AlertForStatus,',',''',''') + ''''

	SET @SQL = 
		'
		SELECT
			SUM([BitValue]) AS ''TotalBitValue''
		FROM
			[control].[AlertOutcomes]
		WHERE
			[PipelineOutcomeStatus] IN (' + @AlertForStatus + ')
		'

	INSERT INTO @BitValue ([TotalBitValue]) EXECUTE(@SQL)
	SELECT @ActualBitValue = [TotalBitValue] FROM @BitValue
	
	--set link table
	IF @PipelineName IS NOT NULL
		BEGIN
			--add alert for specific pipeline if doesn't exist
			INSERT INTO [control].[PipelineAlertLink]
				(
				[PipelineId],
				[RecipientId],
				[OutcomesBitValue]
				)			
			SELECT
				p.[PipelineId],
				r.[RecipientId],
				@ActualBitValue
			FROM
				[control].[Pipelines] p
				INNER JOIN [control].[Recipients] r
					ON r.[Name] = @RecipientName
				LEFT OUTER JOIN [control].[PipelineAlertLink] al
					ON p.[PipelineId] = al.[PipelineId]
						AND r.[RecipientId] = al.[RecipientId]
			WHERE
				p.[PipelineName] = @PipelineName
				AND al.[PipelineId] IS NULL
				AND al.[RecipientId] IS NULL;
		END
	ELSE IF @PipelineName IS NULL
		BEGIN
			--remove and re-add alerts for all pipelines
			DELETE 
				al
			FROM 
				[control].[PipelineAlertLink] al
				INNER JOIN [control].[Recipients] r
					ON al.[RecipientId] = r.[RecipientId]
			WHERE
				r.[Name] = @RecipientName;
						
			INSERT INTO [control].[PipelineAlertLink]
				(
				[PipelineId],
				[RecipientId],
				[OutcomesBitValue]
				)
			SELECT
				p.[PipelineId],
				r.[RecipientId],
				@ActualBitValue
			FROM
				[control].[Recipients] r
				CROSS JOIN [control].[Pipelines] p
			WHERE
				r.[Name] = @RecipientName;
		END;
END