CREATE PROCEDURE [procfwkHelpers].[DeleteMetadataWithIntegrity]
AS
BEGIN
	/*
	DELETE ORDER IMPORTANT FOR REFERENTIAL INTEGRITY
	*/

	--BatchExecution
	IF OBJECT_ID(N'[cumulus.control].[BatchExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [cumulus.control].[BatchExecution];
		END;

	--CurrentExecution
	IF OBJECT_ID(N'[cumulus.control].[CurrentExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [cumulus.control].[CurrentExecution];
		END;

	--ExecutionLog
	IF OBJECT_ID(N'[cumulus.control].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [cumulus.control].[ExecutionLog];
		END

	--ErrorLog
	IF OBJECT_ID(N'[cumulus.control].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [cumulus.control].[ErrorLog];
		END

	--BatchStageLink
	IF OBJECT_ID(N'[cumulus.control].[BatchStageLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[BatchStageLink];
		END;

	--Batches
	IF OBJECT_ID(N'[cumulus.control].[Batches]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Batches];
		END;

	--PipelineDependencies
	IF OBJECT_ID(N'[cumulus.control].[PipelineDependencies]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[PipelineDependencies];
			DBCC CHECKIDENT ('[cumulus.control].[PipelineDependencies]', RESEED, 0);
		END;

	--PipelineAlertLink
	IF OBJECT_ID(N'[cumulus.control].[PipelineAlertLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[PipelineAlertLink];
			DBCC CHECKIDENT ('[cumulus.control].[PipelineAlertLink]', RESEED, 0);
		END;

	--Recipients
	IF OBJECT_ID(N'[cumulus.control].[Recipients]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Recipients];
			DBCC CHECKIDENT ('[cumulus.control].[Recipients]', RESEED, 0);
		END;

	--AlertOutcomes
	IF OBJECT_ID(N'[cumulus.control].[AlertOutcomes]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [cumulus.control].[AlertOutcomes];
		END;

	--PipelineAuthLink
	IF OBJECT_ID(N'[cumulus.control].[PipelineAuthLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[PipelineAuthLink];
			DBCC CHECKIDENT ('[cumulus.control].[PipelineAuthLink]', RESEED, 0);
		END;

	--ServicePrincipals
	IF OBJECT_ID(N'[dbo].[ServicePrincipals]') IS NOT NULL 
		BEGIN
			DELETE FROM [dbo].[ServicePrincipals];
			DBCC CHECKIDENT ('[dbo].[ServicePrincipals]', RESEED, 0);
		END;

	--Properties
	IF OBJECT_ID(N'[cumulus.control].[Properties]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Properties];
			DBCC CHECKIDENT ('[cumulus.control].[Properties]', RESEED, 0);
		END;

	--PipelineParameters
	IF OBJECT_ID(N'[cumulus.control].[PipelineParameters]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[PipelineParameters];
			DBCC CHECKIDENT ('[cumulus.control].[PipelineParameters]', RESEED, 0);
		END;

	--Pipelines
	IF OBJECT_ID(N'[cumulus.control].[Pipelines]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Pipelines];
			DBCC CHECKIDENT ('[cumulus.control].[Pipelines]', RESEED, 0);
		END;

	--Orchestrators
	IF OBJECT_ID(N'[cumulus.control].[Orchestrators]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Orchestrators];
			DBCC CHECKIDENT ('[cumulus.control].[Orchestrators]', RESEED, 0);
		END;

	--Stages
	IF OBJECT_ID(N'[cumulus.control].[Stages]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Stages];
			DBCC CHECKIDENT ('[cumulus.control].[Stages]', RESEED, 0);
		END;

	--Subscriptions
	IF OBJECT_ID(N'[cumulus.control].[Subscriptions]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Subscriptions];
		END;
	
	--Tenants
	IF OBJECT_ID(N'[cumulus.control].[Tenants]') IS NOT NULL 
		BEGIN
			DELETE FROM [cumulus.control].[Tenants];
		END;
END;