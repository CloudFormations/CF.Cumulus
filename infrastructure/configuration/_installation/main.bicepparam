using '../../main.bicep'

//Parameters for environment configuration
// * These parameters control resource naming and deployment options
// * Recommended for consistent resource naming across environments
param orgName = 'cfc'
param domainName = 'demo'
param envName = 'dev'
param location = 'uksouth'
param uniqueIdentifier = '01'

//Parameters for optional deployments
param deployADF = true
param deployWorkers = false      // if worker pipelines are to live in a separate data factory instance to the bootstrap pipelines
param deploySQL = true           // assumes SQL database is required to house metadata
param deployFunction = true      // exclude function app if already created or manual config is preferred later
param deployADBWorkspace = true  // exclude databricks if already created or manual config is preferred later
param setRoleAssignments = true

// Resoure Group Level: Optional Settings
param deployNetworking = false    // if custom VNet and specific IP address space is to be used
param deployVM = false           // if self hosted IR is required for data factory

//Parameters for configuration settings
param aspSKU = 'consumption'   // ASP SKU for function app
param configureGitHub = false    // if GitHub repo configuration is required for ADF deployment

// SQL Server: Optional Parameters
param myIPAddress = '1.1.1.1' // For SQL Server Firewall rule
param allowAzureServices = true // For allowing Azure services access to Azure SQL Server

// Storage: Optional naming configurations
param datalakeName = 'dls' //Storage account name prefix
param functionStorageName = 'st' //Function app storage name prefix
