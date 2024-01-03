CREATE PROCEDURE [procfwkHelpers].[DeleteRecipientAlerts]
	(
	@EmailAddress NVARCHAR(500),
	@SoftDeleteOnly BIT = 1
	)
AS
BEGIN
	SET NOCOUNT ON;

	--defensive check
	IF NOT EXISTS
		(
		SELECT [RecipientId] FROM [cumulus.control].[Recipients] WHERE [EmailAddress] = @EmailAddress
		)
		BEGIN
			RAISERROR('Recipient email address does not exists in [cumulus.control].[Recipients] table.',16,1);
			RETURN 0;
		END;

	--update/delete
	IF @SoftDeleteOnly = 1
		BEGIN
			--disable links
			UPDATE
				al
			SET
				al.[Enabled] = 0
			FROM
				[cumulus.control].[PipelineAlertLink] al
				INNER JOIN [cumulus.control].[Recipients] r
					ON al.[RecipientId] = r.[RecipientId]
			WHERE
				r.[EmailAddress] = @EmailAddress;
	
			--disable recipient(s)
			UPDATE
				[cumulus.control].[Recipients]
			SET
				[Enabled] = 0
			WHERE
				[EmailAddress] = @EmailAddress;

		END
	ELSE
		BEGIN
			--delete links
			DELETE		
				al
			FROM
				[cumulus.control].[PipelineAlertLink] al
				INNER JOIN [cumulus.control].[Recipients] r
					ON al.[RecipientId] = r.[RecipientId]
			WHERE
				r.[EmailAddress] = @EmailAddress;

			--delete recipient(s)
			DELETE FROM
				[cumulus.control].[Recipients]
			WHERE
				[EmailAddress] = @EmailAddress;
		END;
END;