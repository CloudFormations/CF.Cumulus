# Read Me - Cloud Formations CF.Cumulus Community Edition

[![GitHub Release](https://img.shields.io/github/v/release/CloudFormations/CF.Cumulus?label=release)](https://github.com/CloudFormations/CF.Cumulus/releases)
[![GitHub Stars](https://img.shields.io/github/stars/CloudFormations/CF.Cumulus?style=flat)](https://github.com/CloudFormations/CF.Cumulus/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/CloudFormations/CF.Cumulus?style=flat)](https://github.com/CloudFormations/CF.Cumulus/network/members)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/CloudFormations/CF.Cumulus)](https://github.com/CloudFormations/CF.Cumulus/commits/main)

<!--[![GitHub License](https://img.shields.io/github/license/CloudFormations/CF.Cumulus)](https://github.com/CloudFormations/CF.Cumulus/blob/main/LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/CloudFormations/CF.Cumulus)](https://github.com/CloudFormations/CF.Cumulus/issues)
[![GitHub Contributors](https://img.shields.io/github/contributors/CloudFormations/CF.Cumulus)](https://github.com/CloudFormations/CF.Cumulus/graphs/contributors) -->

[ ![](https://static.wixstatic.com/media/fb2e49_ee1fa91f1ad049d2a4b151f3d8caeb9e~mv2.png) ](https://static.wixstatic.com/media/fb2e49_ee1fa91f1ad049d2a4b151f3d8caeb9e~mv2.png)

CF.Cumulus is an Open-Source Metadata-driven Lakehouse Accelerator designed for Data Teams to quickly deploy and use a Lakehouse in Azure. Key features include:
* Deployment of a Lakehouse to Azure within minutes. 
* Pre-built connectors to minimise development overhead of ingesting data from variety of data sources.
* Easy-to-use Metadata configuration tables simplifying the onboarding of new data sources to your data lake.
* Robust Data Orchestration Pipelines. 

## Release Details
### Latest Release Notes
V25.1.1.0

https://github.com/CloudFormations/CF.Cumulus/releases

## Choosing the Right Product Edition For You
We offer a variety of different ways to get started with CF.Cumulus, which can be accessed through the Azure MarketPlace [here](https://azuremarketplace.microsoft.com/en-gb/marketplace/apps?search=cf.cumulus&page=1). This includes a variety of deployment and support options for you to use as per your organisation's requirements.

* **Community** - Self-service deployment to try out and use all CF.Cumulus’ core capabilities.
* **Supported** - Ideal for early-stage exploration with light touch support.
* **Professional** - For teams in production who need onboarding, SLA-backed response times and managed upgrade support.
* **Premium** - A strategic engagement with product roadmap input, defect resolution, and access to engineering expertise.
* **Assisted Deployment** - Collaborate with our professional services team to provision CF.Cumulus tailored to your requirements and platform.


[![](https://static.wixstatic.com/media/fb2e49_c6c533ad89cd40a7a342c4b2b65a3c70~mv2.png)](https://static.wixstatic.com/media/fb2e49_c6c533ad89cd40a7a342c4b2b65a3c70~mv2.png)

We also have the Community Edition for Developers who want to run with CF.Cumulus for themselves, available here on our Open-Source Repo!

## Pre-requisites
To ensure a seamless deployment of CF.Cumulus in the Azure MarketPlace or via the Community Edition, we recommend registering the following Namespaces in your target subscription:

- Microsoft.AlertsManagement
- Microsoft.Compute
- Microsoft.Consumption 
- Microsoft.DataFactory
- Microsoft.Databricks
- Microsoft.Features
- Microsoft.KeyVault
- Microsoft.Maintenance
- Microsoft.ManagedIdentity
- Microsoft.MarketplaceOrdering
- Microsoft.Networking
- Microsoft.OperationalInsights
- Microsoft.Portal
- Microsoft.ResourceGraph
- Microsoft.ResourceNotifications
- Microsoft.Resources
- Microsoft.SerialConsole
- Microsoft.Solutions
- Microsoft.Sql
- Microsoft.Storage
- Microsoft.Web
- Microsoft.Insights
- Microsoft.Support 

> In the event any of these missing, please complete the following URL and enable as suggested: <https://portal.azure.com/#@organisation.org/resource/subscriptions/subscription-id/resourceproviders>

If you would like following information on the topic before doing so, please follow this link from the [Microsoft Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)

## Getting Started with the Community Edition of CF.Cumulus
For further information on how to get started using the Community Edition of CF.Cumulus can be found in the members area of our website [here](https://www.cloudformations.org/cf-cumulus-deployment-guide/). It's free to become a member and gives you access to other great content from Cloud Formations. 

Below is our Getting Started guide for installing CF.Cumulus in your Azure Subscription. The installation gives you a complete deployment of the Azure Resources required for a Lakehouse, with resource dependencies and objects all included at the click of a button.

[![](https://static.wixstatic.com/media/fb2e49_7e111fe8b804491fa087490e9353f58c~mv2.png)](https://static.wixstatic.com/media/fb2e49_7e111fe8b804491fa087490e9353f58c~mv2.png)

### What's Included
The deployment demonstrated in this guide includes the following:
* Resource Deployment
* Role Assignments
* Azure Function Middleware Published
* Ready-to-Go Data Factory Objects
* Spark Compute Clusters
* Spark Notebooks
* Core Metadata Configurations in your Azure SQL Metadata Database
* **Coming Soon!** Sample Metadata 


### Pre-Requisites
* Visual Studio Code with Bicep extension
* PowerShell (Module install/imports handled as part of scripts)
* Azure Entra Account
* Deployment Privileges in Azure
* Subscription Level Contributor Role Assignment


### User Configuration
As a user, you're only requirement is to get some details regarding your Azure Tenant and Subscription and specify your resource naming convention. This is achieved through setting a few parameters in the infrastructure/configuration/_installation/main.bicepparam file.


### The Process
[![](https://static.wixstatic.com/media/fb2e49_55a9415aeb6e4ee69776a80e90ac73ab~mv2.png)](https://static.wixstatic.com/media/fb2e49_55a9415aeb6e4ee69776a80e90ac73ab~mv2.png)

1. Navigate to our CF.Cumulus GitHub repository.
2. Clone the repo to your local computer and open in Visual Studio Code.
3. Open the infrastructure/configuration/_installation/main.bicepparam file and provide your values for the following parameters:

```
param orgName = 'cf' // Abbreviation of your Organisation's name
param domainName = 'cumulus' // Domain for installation of Cumulus
param envName = 'dev' // Environment name
param location = 'uksouth' // Azure region you are deploying to
param uniqueIdentifier = '01' // Identifier to ensure unique naming
```

4. Specify any additional configuration in the same file. For a "getting started" environment, the additional change we'd recommend is to add your IP for SQL Server connectivity:
```
// SQL Server: Optional Parameters
param myIPAddress = '1.1.1.1' // For SQL Server Firewall rule
```
5. Save the file!
6. Open the infrastructure/deployment/deploy_wrapper.ps1 file to view the PowerShell executor module. Review the parameters listed here and get these from your Azure tenant.
7. For ease of use, and confidence you've recorded the right values, input them in to the following PowerShell command:
```
. 'C:\Users\MyUser\Repos\CF.Cumulus\infrastructure\deployment\deploy_wrapper.ps1' -tenantId 'My Tenant GUID' -subscriptionName 'My Subscription Name' -location 'uksouth'
```
> Note: The deploy_wrapper.ps1 PowerShell script allows you to input these parameters at execution time, but it is also easy to specify them as part of a declarative statement, as above. This allows users to verify the command, path of file and parameters before executing.

8. Copy and Paste your command into a PowerShell terminal (such as the integrated terminal in VSCode) and execute.
9. Follow the process on screen and in 5-10 minutes you will have a deployment of Cumulus ready to explore.
