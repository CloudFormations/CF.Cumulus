# Azure Marketplace Offering

This project contains the necessary files to deploy an Azure Marketplace offering using Bicep and Azure Resource Manager (ARM) templates.

[![Deploy To Azure](./resources/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCloudFormations%2FCF.Cumulus%2Frefs%2Fheads%2Fdevelop_marketplace%2Finfrastructure%2Fazuredeploy.json)

https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCloudFormations%2FCF.Cumulus%2Frefs%2Fheads%2Fdevelop_marketplace%2Finfrastructure%2Fazuredeploy.json


## Project Structure

- **main.bicep**: Contains the main infrastructure deployment logic for the Azure Marketplace offering. It defines parameters, variables, and modules for deploying various Azure resources such as Key Vault, Storage, Data Factory, and more.

- **mainTemplate.json**: Serves as the entry point for the ARM template. It includes the parameters that will be passed to the `main.bicep` file and defines the resources to be deployed.