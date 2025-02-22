param(

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionID,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantID,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $instanceName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $databaseName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $resourceGroup, 

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $factoryDataFactory,

    [Parameter(Mandatory=$false)]
    [string]
    $workersDataFactory,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [bool]
    $clearTables,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sourceInstanceName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sourceDatabaseName
)

Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0
# Connect-AzAccount -SubscriptionId $subscriptionID -TenantId $tenantID

$scriptRoot = (Resolve-Path -Path ".\").Path
$commonFilesDirectory = Join-Path -Path $scriptRoot -ChildPath "..\common"

$migrationScript = 'MigrationScript'

$filesToExecuteDeletes = @('DeleteMetadataWithIntegrity','DeleteSQLDBMetadataWithIntegrity')

$filesToExecuteAdds = @('AddProperty', 'AddPipelineDependant')
$filesToExecuteSets = @('SetSampleTenant', 'SetSampleSubscription', 'SetSampleOrchestrators', 'SetSampleBatches', 'SetSampleStages', 'SetSampleBatchStageLink', 'SetDefaultProperties','SetSampleConnections','SetSampleComputeConnections','SetSampleDatasets', 'SetSampleAttributes')

# Files, including Adding Datasets to Control Pipelines with Parameters and Dependencies
$filesToExecuteSets = @('SetSampleTenant', 'SetSampleSubscription', 'SetSampleOrchestrators', 'SetSampleBatches', 'SetSampleStages', 'SetSampleBatchStageLink', 'SetSamplePipelines','SetSamplePipelineParameters', 'SetSamplePipelineDependants', 'SetDefaultProperties')

# Create the database user and role for data factory to use 
& "$PSScriptRoot\GrantADFAccess" -ADFResource $factoryDataFactory -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName

# Create the database user and role for data factory to query the Source Database
& "$PSScriptRoot\GrantADFAccessSourceDB" -ADFResource $factoryDataFactory -subscriptionID $subscriptionID -instanceName $sourceInstanceName -databaseName $sourceDatabaseName

# Create the parameterised SQL Scripts to execute
$directoryPath = "..\..\Stored Procedures SQL DB Demo"
& "$commonFilesDirectory\CreateTemporaryScriptCopies" -subscriptionID $subscriptionID -tenantID $tenantID -resourceGroup $resourceGroup -factoryDataFactory $factoryDataFactory -workersDataFactory $workersDataFactory -directoryPath $directoryPath -databricksWorkspaceURL $databricksWorkspaceURL -databricksClusterId $databricksClusterId -databricksWorkspaceName $databricksWorkspaceName

# Execute the parameterised scripts
& "$commonFilesDirectory\ExecuteTemporaryScriptCopies" -subscriptionID $subscriptionID -tenantID $tenantID -instanceName $instanceName -databaseName $databaseName -clearTables $clearTables -migrationScript $migrationScript -filesToExecuteDeletes $filesToExecuteDeletes -filesToExecuteAdds $filesToExecuteAdds -filesToExecuteSets $filesToExecuteSets 

# Delete the parameterised scripts
& "$commonFilesDirectory\DeleteTemporaryScriptCopies"