CREATE PROCEDURE [control].[AddSubscriptions]
(
	@SubscriptionId UNIQUEIDENTIFIER,
	@Name NVARCHAR(200),
	@Description NVARCHAR(MAX),
	@TenantId UNIQUEIDENTIFIER
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS
	(
		SELECT
		@SubscriptionId AS SubscriptionId,
		@Name AS Name,
		@Description AS Description,
		@TenantId AS TenantId
	)
	MERGE INTO control.Subscriptions AS Target
	USING cte AS Source
	ON Source.SubscriptionId = Target.SubscriptionId

	WHEN NOT MATCHED THEN
		INSERT (SubscriptionId, Name, Description, TenantId) 
		VALUES (Source.SubscriptionId, Source.Name, Source.Description, Source.TenantId)

	WHEN MATCHED THEN UPDATE SET
		Target.Name			= Source.Name,
		Target.Description	= Source.Description,
		Target.TenantID		= Source.TenantId
	;
END
GO