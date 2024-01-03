IF EXISTS 
	(
	SELECT
		* 
	FROM
		sys.objects o
		INNER JOIN sys.schemas s
			ON o.[schema_id] = s.[schema_id]
	WHERE
		o.[name] = 'DataFactorys'
		AND s.[name] = 'procfwk'
		AND o.[type] = 'U' --Check for tables as created synonyms to support backwards compatability
	)
	BEGIN
		DROP TABLE [cumulus.control].[DataFactorys];

		EXEC('CREATE VIEW [cumulus.control].[DataFactorys]
AS
SELECT
	[OrchestratorId] AS DataFactoryId,
	[OrchestratorName] AS DataFactoryName,
	[ResourceGroupName],
	[SubscriptionId],
	[Description]
FROM
	[cumulus.control].[Orchestrators]
WHERE
	[OrchestratorType] = ''ADF'';')
	END;