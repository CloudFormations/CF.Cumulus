# Azure Marketplace Offering

This project contains the necessary files to deploy an Azure Marketplace offering using Bicep and Azure Resource Manager (ARM) templates.

[![Deploy To Azure](./deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCloudFormations%2FCF.Cumulus%2Frefs%2Fheads%2Fdevelop_marketplace%2Finfrastructure%2Fmain.json)

### Compiling the BiCep

```
bicep build ".\infrastructure\main.bicep"
```
```
pid-c7c02b4c-2b89-4086-a4fc-a436ef37c78f-partnercenter

Package acceptance validation error: AzureAppCannotAddTrackingId The package you have uploaded utilizes resources of type Microsoft.Resources/deployments for purposes other than customer usage attribution. Partner Center will be unable to add a customer usage attribution id on your behalf in this case. Please add a new resource of type Microsoft.Resources/deployments and add the tracking ID visible in Partner Center on your plan's Technical Configuration page. To learn more about tracking customer usage attribution please see https://aka.ms/aboutinfluencedrevenuetracking. Error code: PAC-AzureAppCannotAddTrackingId
```

## Project Structure

- **main.bicep**: Contains the main infrastructure deployment logic for the Azure Marketplace offering. It defines parameters, variables, and modules for deploying various Azure resources such as Key Vault, Storage, Data Factory, and more.

- **mainTemplate.json**: Serves as the entry point for the ARM template. It includes the parameters that will be passed to the `main.bicep` file and defines the resources to be deployed.