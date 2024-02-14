CREATE PROCEDURE [procfwkHelpers].[DeleteMetadataWithIntegrity]
AS
BEGIN
	/*
	DELETE ORDER IMPORTANT FOR REFERENTIAL INTEGRITY
	*/

	--BatchExecution
	IF OBJECT_ID(N'[control].[BatchExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [control].[BatchExecution];
		END;

	--CurrentExecution
	IF OBJECT_ID(N'[control].[CurrentExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [control].[CurrentExecution];
		END;

	--ExecutionLog
	IF OBJECT_ID(N'[control].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [control].[ExecutionLog];
		END

	--ErrorLog
	IF OBJECT_ID(N'[control].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [control].[ErrorLog];
		END

	--BatchStageLink
	IF OBJECT_ID(N'[control].[BatchStageLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[BatchStageLink];
		END;

	--Batches
	IF OBJECT_ID(N'[control].[Batches]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Batches];
		END;

	--PipelineDependencies
	IF OBJECT_ID(N'[control].[PipelineDependencies]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[PipelineDependencies];
			DBCC CHECKIDENT ('[control].[PipelineDependencies]', RESEED, 0);
		END;

	--PipelineAlertLink
	IF OBJECT_ID(N'[control].[PipelineAlertLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[PipelineAlertLink];
			DBCC CHECKIDENT ('[control].[PipelineAlertLink]', RESEED, 0);
		END;

	--Recipients
	IF OBJECT_ID(N'[control].[Recipients]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Recipients];
			DBCC CHECKIDENT ('[control].[Recipients]', RESEED, 0);
		END;

	--AlertOutcomes
	IF OBJECT_ID(N'[control].[AlertOutcomes]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [control].[AlertOutcomes];
		END;

	--PipelineAuthLink
	IF OBJECT_ID(N'[control].[PipelineAuthLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[PipelineAuthLink];
			DBCC CHECKIDENT ('[control].[PipelineAuthLink]', RESEED, 0);
		END;

	--ServicePrincipals
	IF OBJECT_ID(N'[dbo].[ServicePrincipals]') IS NOT NULL 
		BEGIN
			DELETE FROM [dbo].[ServicePrincipals];
			DBCC CHECKIDENT ('[dbo].[ServicePrincipals]', RESEED, 0);
		END;

	--Properties
	IF OBJECT_ID(N'[control].[Properties]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Properties];
			DBCC CHECKIDENT ('[control].[Properties]', RESEED, 0);
		END;

	--PipelineParameters
	IF OBJECT_ID(N'[control].[PipelineParameters]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[PipelineParameters];
			DBCC CHECKIDENT ('[control].[PipelineParameters]', RESEED, 0);
		END;

	--Pipelines
	IF OBJECT_ID(N'[control].[Pipelines]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Pipelines];
			DBCC CHECKIDENT ('[control].[Pipelines]', RESEED, 0);
		END;

	--Orchestrators
	IF OBJECT_ID(N'[control].[Orchestrators]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Orchestrators];
			DBCC CHECKIDENT ('[control].[Orchestrators]', RESEED, 0);
		END;

	--Stages
	IF OBJECT_ID(N'[control].[Stages]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Stages];
			DBCC CHECKIDENT ('[control].[Stages]', RESEED, 0);
		END;

	--Subscriptions
	IF OBJECT_ID(N'[control].[Subscriptions]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Subscriptions];
		END;
	
	--Tenants
	IF OBJECT_ID(N'[control].[Tenants]') IS NOT NULL 
		BEGIN
			DELETE FROM [control].[Tenants];
		END;
END;