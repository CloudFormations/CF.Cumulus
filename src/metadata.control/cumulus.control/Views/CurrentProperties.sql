CREATE VIEW [cumulus.control].[CurrentProperties]
AS

SELECT
	[PropertyName],
	[PropertyValue]
FROM
	[cumulus.control].[Properties]
WHERE
	[ValidTo] IS NULL;