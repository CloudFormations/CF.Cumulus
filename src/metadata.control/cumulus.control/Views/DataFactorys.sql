CREATE VIEW [cumulus.control].[DataFactorys]
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
	[OrchestratorType] = 'ADF';