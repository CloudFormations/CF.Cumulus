# Read Me - Cloud Formations (CF).Cumulus Community Edition

[ ![](https://static.wixstatic.com/media/e66568_635e25cb91f44be580ef08cd83e68c6f~mv2.jpg/v1/crop/x_480,y_506,w_5433,h_2414/fill/w_2221,h_987,al_c,q_90,usm_0.66_1.00_0.01,enc_auto/Cumulus%20Diagram.jpg) ](https://static.wixstatic.com/media/e66568_635e25cb91f44be580ef08cd83e68c6f~mv2.jpg/v1/crop/x_480,y_506,w_5433,h_2414/fill/w_2221,h_987,al_c,q_90,usm_0.66_1.00_0.01,enc_auto/Cumulus%20Diagram.jpg)

CF.Cumulus is an Open-Source Metadata-driven Lakehouse Accelerator designed for Data Teams to quickly deploy and use a Lakehouse in Azure. Key features include:
* Deployment of a Lakehouse to Azure within minutes.
* Pre-built connectors to minimise development overhead of ingesting data from variety of data sources.
* Easy-to-use Metadata configuration tables simplifying the onboarding of new data sources to your data lake.
* Robust Data Orchestration Pipelines. 

## Release Details
### Latest Release Notes
V25.1.0.0

https://github.com/CloudFormations/CF.Cumulus/releases

## Choosing the Right Plan for You
[![](https://static.wixstatic.com/media/bacfcb_1c2739eec5e743428df967a8a9ed051a~mv2.png)](https://static.wixstatic.com/media/bacfcb_1c2739eec5e743428df967a8a9ed051a~mv2.png)

We offer a variety of different ways to get started with CF.Cumulus, which can be accessed through the Azure MarketPlace [here](https://azuremarketplace.microsoft.com/en-gb/marketplace/apps?search=cf.cumulus&page=1). This includes a variety of deployment and support options for you to use as per your organisation's requirements.

[![](https://static.wixstatic.com/media/bacfcb_acf5aabad1284e7ba49e83f639ee5e91~mv2.png)](https://static.wixstatic.com/media/bacfcb_acf5aabad1284e7ba49e83f639ee5e91~mv2.png)

We also have the Community Edition for Developers who want to run with Cumulus for themselves, available here on our Open-Source Repo!

## Getting Started with the Community Edition of CF.Cumulus
For further information on how to get started using the Community Edition of CF.Cumulus can be found in the members area of our website [here](https://www.cloudformations.org/cf-cumulus-deployment-guide/). It's free to become a member and gives you access to other great content from Cloud Formations. 

Below is our Getting Started guide for installing CF.Cumulus in your Azure Subscription. The installation gives you a complete deployment of the Azure Resources required for a Lakehouse, with resource dependencies and objects all included at the click of a button.

[![](https://static.wixstatic.com/media/bacfcb_381bbf27373f4ea99dc919d8af47ff56~mv2.png)](https://static.wixstatic.com/media/bacfcb_381bbf27373f4ea99dc919d8af47ff56~mv2.png)

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
[![](https://static.wixstatic.com/media/bacfcb_4c93b531a1264bd4a71ceefce9ac4061~mv2.png)](https://static.wixstatic.com/media/bacfcb_4c93b531a1264bd4a71ceefce9ac4061~mv2.png)

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
. 'C:\Users\MyUser\Repos\CF.Cumulus\infrastructure\deployment\deploy_wrapper.ps1' -tenantId 'My Tenant GUID' -subscriptionId 'My Subscription Name' -location 'uksouth'
```
> Note: The deploy_wrapper.ps1 PowerShell script allows you to input these parameters at execution time, but it is also easy to specify them as part of a declarative statement, as above. This allows users to verify the command, path of file and parameters before executing.

8. Copy and Paste your command into a PowerShell terminal (such as the integrated terminal in VSCode) and execute.
9. Follow the process on screen and in 5-10 minutes you will have a deployment of Cumulus ready to explore.