﻿CREATE PROCEDURE [procfwkHelpers].[DeleteMetadataWithIntegrity]
AS
BEGIN
	/*
	DELETE ORDER IMPORTANT FOR REFERENTIAL INTEGRITY
	*/

	--BatchExecution
	IF OBJECT_ID(N'[procfwk].[BatchExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [procfwk].[BatchExecution];
		END;

	--CurrentExecution
	IF OBJECT_ID(N'[procfwk].[CurrentExecution]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [procfwk].[CurrentExecution];
		END;

	--ExecutionLog
	IF OBJECT_ID(N'[procfwk].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [procfwk].[ExecutionLog];
		END

	--ErrorLog
	IF OBJECT_ID(N'[procfwk].[ExecutionLog]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [procfwk].[ErrorLog];
		END

	--BatchStageLink
	IF OBJECT_ID(N'[procfwk].[BatchStageLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[BatchStageLink];
		END;

	--Batches
	IF OBJECT_ID(N'[procfwk].[Batches]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Batches];
		END;

	--PipelineDependencies
	IF OBJECT_ID(N'[procfwk].[PipelineDependencies]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[PipelineDependencies];
			DBCC CHECKIDENT ('[procfwk].[PipelineDependencies]', RESEED, 0);
		END;

	--PipelineAlertLink
	IF OBJECT_ID(N'[procfwk].[PipelineAlertLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[PipelineAlertLink];
			DBCC CHECKIDENT ('[procfwk].[PipelineAlertLink]', RESEED, 0);
		END;

	--Recipients
	IF OBJECT_ID(N'[procfwk].[Recipients]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Recipients];
			DBCC CHECKIDENT ('[procfwk].[Recipients]', RESEED, 0);
		END;

	--AlertOutcomes
	IF OBJECT_ID(N'[procfwk].[AlertOutcomes]') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [procfwk].[AlertOutcomes];
		END;

	--PipelineAuthLink
	IF OBJECT_ID(N'[procfwk].[PipelineAuthLink]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[PipelineAuthLink];
			DBCC CHECKIDENT ('[procfwk].[PipelineAuthLink]', RESEED, 0);
		END;

	--ServicePrincipals
	IF OBJECT_ID(N'[dbo].[ServicePrincipals]') IS NOT NULL 
		BEGIN
			DELETE FROM [dbo].[ServicePrincipals];
			DBCC CHECKIDENT ('[dbo].[ServicePrincipals]', RESEED, 0);
		END;

	--Properties
	IF OBJECT_ID(N'[procfwk].[Properties]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Properties];
			DBCC CHECKIDENT ('[procfwk].[Properties]', RESEED, 0);
		END;

	--PipelineParameters
	IF OBJECT_ID(N'[procfwk].[PipelineParameters]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[PipelineParameters];
			DBCC CHECKIDENT ('[procfwk].[PipelineParameters]', RESEED, 0);
		END;

	--Pipelines
	IF OBJECT_ID(N'[procfwk].[Pipelines]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Pipelines];
			DBCC CHECKIDENT ('[procfwk].[Pipelines]', RESEED, 0);
		END;

	--Orchestrators
	IF OBJECT_ID(N'[procfwk].[Orchestrators]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Orchestrators];
			DBCC CHECKIDENT ('[procfwk].[Orchestrators]', RESEED, 0);
		END;

	--Stages
	IF OBJECT_ID(N'[procfwk].[Stages]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Stages];
			DBCC CHECKIDENT ('[procfwk].[Stages]', RESEED, 0);
		END;

	--Subscriptions
	IF OBJECT_ID(N'[procfwk].[Subscriptions]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Subscriptions];
		END;
	
	--Tenants
	IF OBJECT_ID(N'[procfwk].[Tenants]') IS NOT NULL 
		BEGIN
			DELETE FROM [procfwk].[Tenants];
		END;
END;