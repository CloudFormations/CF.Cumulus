CREATE VIEW [control].[CurrentProperties]
AS

SELECT
	[PropertyName],
	[PropertyValue]
FROM
	[control].[Properties]
WHERE
	[ValidTo] IS NULL;