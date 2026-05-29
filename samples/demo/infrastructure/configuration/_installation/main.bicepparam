using '../../main.bicep'

//Parameters for environment configuration
// * These parameters control resource naming and deployment options
// * Recommended for consistent resource naming across environments
param orgName = 'cf'
param domainName = 'cumulus'
param envName = 'dev'
param location = 'uksouth'
param uniqueIdentifier = '01'
param myIPAddress = '1.1.1.1' // For SQL Server Firewall rule

// SQL Server: Optional Parameters
param allowAzureServices = true // For allowing Azure services access to Azure SQL Server
