CREATE PROCEDURE ##AddTenants
(
	@TenantId UNIQUEIDENTIFIER,
	@Name NVARCHAR(200),
	@Description NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	WITH cte AS
	(
		SELECT
		@TenantId AS TenantId,
		@Name AS Name,
		@Description AS Description
	)
	MERGE INTO control.Tenants AS Target
	USING cte AS Source
	ON Source.TenantId = Target.TenantId

	WHEN NOT MATCHED THEN
		INSERT (TenantId, Name, Description) 
		VALUES (Source.TenantId, Source.Name, Source.Description)

	WHEN MATCHED THEN UPDATE SET
		Target.Name			= Source.Name,
		Target.Description	= Source.Description
	;
END
GO