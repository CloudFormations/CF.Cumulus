﻿CREATE PROCEDURE [procfwkHelpers].[AddServicePrincipalWrapper]
	(
	@OrchestratorName NVARCHAR(200),
	@OrchestratorType CHAR(3),
	@PrincipalIdValue NVARCHAR(MAX),
	@PrincipalSecretValue NVARCHAR(MAX),
	@SpecificPipelineName NVARCHAR(200) = NULL,
	@PrincipalName NVARCHAR(256) = NULL
	)
AS
BEGIN
	
	IF ([control].[GetPropertyValueInternal]('SPNHandlingMethod')) = 'StoreInDatabase'
		BEGIN
			EXEC [control].[AddServicePrincipal]
				@OrchestratorName = @OrchestratorName,
				@OrchestratorType = @OrchestratorType,
				@PrincipalId = @PrincipalIdValue,
				@PrincipalSecret = @PrincipalSecretValue,
				@PrincipalName = @PrincipalName,
				@SpecificPipelineName = @SpecificPipelineName			
		END
	ELSE IF ([control].[GetPropertyValueInternal]('SPNHandlingMethod')) = 'StoreInKeyVault'
		BEGIN
			EXEC [control].[AddServicePrincipalUrls]
				@OrchestratorName = @OrchestratorName,
				@OrchestratorType = @OrchestratorType,
				@PrincipalIdUrl = @PrincipalIdValue,
				@PrincipalSecretUrl = @PrincipalSecretValue,
				@PrincipalName = @PrincipalName,
				@SpecificPipelineName = @SpecificPipelineName		
		END
	ELSE
		BEGIN
			RAISERROR('Unknown SPN insert method.',16,1);
			RETURN 0;
		END
END;
