# CF.Cumulus.Samples

A repository of scripts and sample data to demonstrate the functionality of the CF.Cumulus framework. CF.Cumulus.Samples allows users to rapidly see CF.Cumulus metadata, pipelines and notebooks in action as both a visual and educational tool on how to configure the product.

PowerShell scripts are used to deploy various Sample demonstrations to your environment in one click.

Bicep scripts include the ability to deploy your own Azure SQL DB with sample data to your environment, that the CF.Cumulus framework can then ingest and transform in an end-to-end demonstration of the functionality.

## Release Details

| Version | Overview | Version Details & Release Notes |
|:----:|--------------|--------|
| 0.1 |Product early release for automated Control Pipeline deployments. | Samples to populate Control Pipeline executions in your CF.Cumulus metadata database. The artifacts included are detailed below. |

## Self-Serve Instructions

Please note that the CF.Cumulus.Samples repository is a supplementary repository to the CF.Cumulus repository. To use any functionality described here, please get started with your CF.Cumulus implementation by downloading from [here.](https://github.com/CloudFormations/CF.Cumulus/)

### Requirements

* An installation of CF.Cumulus in your Azure environment.
* Entra AD permissions to the CF.Cumulus resources. This will generally be Contributor access to the Resource Group.
* PowerShell Installation. Version used, 5.1.0.0
* PowerShell Modules
    * SqlServer, 22.3.0
    * Az.Accounts, 3.0.4      
* The appropriate schemas and related objects created in your metadata database. This will be detailed in the 'Required Metadata Schemas' section of each Sample description below.
* A firewall rule to allow communication between your Metadata Database Instance and the IP address you are running any scripts from.
* Azure SQL user for your Entra Account on the Metadata Database. T-SQL script provided below for the SQL Server Administrator to run if your are not the Database Administrator.

```TSQL
CREATE USER [user@company.com] FROM EXTERNAL PROVIDER;
```

To get started with the CF.Cumulus.Samples repository, please clone the repository to your local machine, or to a Virtual Machine with networking access to your CF.Cumulus implementation. We recommend using Visual Studio Code for ease of reproducibility.

We offer several different sample implementations, so please follow the step-by-step guides as needed.

## Control Orchestration Sample
This Sample demonstrates the Control Orchestration functionality by running some simple worker pipelines with 'Wait' activities.

All deployment PowerShell scripts are found in the following folder:

`src\samplecodedeployments\controlorchestration\metadatadb`

Required Metadata Schemas:
* control

Users can deploy simple Wait pipelines to your CF.Cumulus Orchestration Data Factory from the JSON scripts provided at the following path:

`\src\azure.datafactory\pipeline`

Once deployed (and published in the event you are using Source Control in your Data Factory implementation), users can run the `DeployControlOrchestratorDemo.ps1` PowerShell script and input their environment parameters as follows:

* Tenant ID 
* Subscription ID
* Resource Group Name
* Factory Data Factory Name
* Workers Data Factory Name
* Metadata Database Instance Name (.database.windows.net path)
* Metadata Database Name

This request includes the additional boolean parameter 'ClearTables'. This truncates all affected [control] schema tables to provide a fresh set of the tables. Set to $False if you wish to keep other information, such as other sample or custom pipelines within your metadata database.

Note: This implementation only uses a single Factory, rather than Factory and Workers for the executions. This sample demonstration will be included in a future release.

First the `GrantADFAccess.ps1` script is executed to ensure your Orchestration Data Factory has access to the metadata database and the control schema. This is simple a SQL Query executed via PowerShell.

The PowerShell Script will then automatically populate your environment details in copies of the SQL scripts to be run against the database as part of the `CreateTemporaryScriptCopies.ps1` module. 

Please note that these files can be found at `src\samples.metadata\control\Stored Procedure\ExecutableCopies` should you wish to run this script manually and inspect the files created.

The `ExecuteTemporaryScriptCopies.ps1` module is then run to login to Azure as your Entra account, and run the scripts against the metadata-db.

The `DeleteTemporaryScriptCopies.ps1` then drops the copies of the SQL scripts from the local `src\samples.metadata\control\Stored Procedure\ExecutableCopies` folder.

The output of this is all control tables in your metadata database for you to run Wait pipelines that demonstrate the Orchestration Framework functionality.

### Running the Pipeline
Once the samples have been deployed and you've copied the Wait Pipelines to the Data Factory, you can verify that the required metadata is good to be run in your Data Factory:

```TSQL
EXEC [control].[CheckMetadataIntegrity]  @DebugMode = 1, @BatchName = 'ControlDemoDaily';
>>> No data integrity issues found in metadata.
```
If any errors occur, please review the results returned in the table and review your deployment scripts and amend as required.

You're now ready to run your first pipeline. Execute 02-BatchExecutor via a Trigger Execution, through the `"Add Trigger" > "Trigger Now"` buttons in the UI.

For the 'BatchName' parameter, supply a value of 'ControlDemoDaily'.

You will then be able to explore the executions of the following pipelines within the Data Factory Monitor tab:
* 02-BatchExecutor
* CheckForRunningPipeline
* 03-StageExecutor
* 04-PipelineExecutor
* Wait 1
* Wait 2

You can also track the progress of worker pipelines called by the orchestration framework through the metadata table:
```TSQL
SELECT * FROM [control].[CurrentExecutions];
```

## End-to-End Ingest and Transform Sample
Coming soon!


