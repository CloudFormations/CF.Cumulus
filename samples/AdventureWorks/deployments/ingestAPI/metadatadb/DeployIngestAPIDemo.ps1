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
    $clearTables
)

Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0
Connect-AzAccount -SubscriptionId $subscriptionID

$scriptRoot = (Resolve-Path -Path ".\..\..\").Path
$commonFilesDirectory = Join-Path -Path $scriptRoot -ChildPath "common"

$filesToExecuteAdds = @('AddProperty', 'AddPipelineDependant')
$filesToExecuteSets = @('SetSampleTenant', 'SetSampleSubscription', 'SetSampleOrchestrators', 'SetSampleBatches', 'SetSampleStages', 'SetSampleBatchStageLink', 'SetSamplePipelines','SetSamplePipelineParameters', 'SetDefaultProperties')
# $filesToExecuteSets = @('SetSampleTenant', 'SetSampleSubscription', 'SetSampleOrchestrators', 'SetSampleBatches', 'SetSampleStages', 'SetSampleBatchStageLink', 'SetSamplePipelines','SetSamplePipelineParameters', 'SetSamplePipelineDependants', 'SetDefaultProperties')

# Create the database user and role for data factory to use 
& "$PSScriptRoot\GrantADFAccess" -ADFResource $factoryDataFactory -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName

# Create the parameterised SQL Scripts to execute
$directoryPath = "src\samples.metadata\control\Stored Procedures API Demo"
& "$commonFilesDirectory\CreateTemporaryScriptCopies" -subscriptionID $subscriptionID -tenantID $tenantID -resourceGroup $resourceGroup -factoryDataFactory $factoryDataFactory -workersDataFactory $workersDataFactory - directoryPath $directoryPath

# Execute the parameterised scripts
& "$commonFilesDirectory\ExecuteTemporaryScriptCopies" -subscriptionID $subscriptionID -tenantID $tenantID -instanceName $instanceName -databaseName $databaseName -clearTables $clearTables -filesToExecuteAdds $filesToExecuteAdds -filesToExecuteSets $filesToExecuteSets

# Delete the parameterised scripts
& "$commonFilesDirectory\DeleteTemporaryScriptCopies"