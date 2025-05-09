CREATE PROCEDURE ##AddOrchestrators
(
	@OrchestratorName NVARCHAR(200),
	@OrchestratorType CHAR(3),
	@IsFrameworkOrchestrator BIT,
	@ResourceGroupName NVARCHAR(200),
	@subscriptionId	UNIQUEIDENTIFIER,
	@Description NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS
	(
		SELECT
		@OrchestratorName AS OrchestratorName,
		@OrchestratorType AS OrchestratorType,
		@IsFrameworkOrchestrator AS IsFrameworkOrchestrator,
		@ResourceGroupName AS ResourceGroupName,
		@subscriptionId	AS SubscriptionId,
		@Description AS Description
	)

	MERGE INTO control.Orchestrators AS Target
	USING cte AS Source
	ON Source.OrchestratorName = Target.OrchestratorName

	WHEN NOT MATCHED THEN
		INSERT (OrchestratorName, OrchestratorType, IsFrameworkOrchestrator, ResourceGroupName, SubscriptionId, Description) 
		VALUES (source.OrchestratorName, source.OrchestratorType, source.IsFrameworkOrchestrator, source.ResourceGroupName, source.SubscriptionId, source.Description)

	WHEN MATCHED THEN UPDATE SET
		Target.OrchestratorType			= Source.OrchestratorType,
		Target.IsFrameworkOrchestrator	= Source.IsFrameworkOrchestrator,
		Target.ResourceGroupName		= Source.ResourceGroupName,
		Target.SubscriptionId			= Source.SubscriptionId,
		Target.Description				= Source.Description
	;
END
GO