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
    [bool]
    $clearTables,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $migrationScript,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $filesToExecuteDeletes,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $filesToExecuteAdds,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $filesToExecuteSets
)


# Uncomment the below commands for independent executions of the script.
# Import-Module SQLServer
# Import-Module Az.Accounts -MinimumVersion 2.2.0
# Connect-AzAccount -SubscriptionId $subscriptionID

# Assuming the relative path is from the script's directory
$scriptRoot = (Resolve-Path -Path ".\").Path
# $directory = Join-Path -Path $scriptRoot -ChildPath "src\samples.metadata\Stored Procedures"
$targetDirectory = Join-Path -Path $scriptRoot -ChildPath "ExecutableCopies"

$files = Get-ChildItem $targetDirectory

$commonScriptRoot = (Resolve-Path -Path ".\..\").Path
$inputScriptPath = "$commonScriptRoot\common\DeploymentInputScript.ps1"
$queryPath = "$commonScriptRoot\common\DeploymentQuery.ps1"

$migrationScriptPath  = "$targetDirectory\$migrationScript.sql"

# & $inputScriptPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -inputFile $migrationScriptPath

# TODO: Check all files exist in ExecutableCopies before running
# $files.Name
# foreach ($f in $files.Name){
#     Write-Host "$f"
# }

$createSchemaQuery = "
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'samples')
    BEGIN
        EXEC('CREATE SCHEMA samples')
    END
"

& $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $createSchemaQuery 
Write-Output "Created the schema"

# If clearing down previous executions, including reseeding the tables, create, run and drop the samples.DeleteMetadataWithIntegrity stored proc. 
if ($clearTables) {
    foreach ($f in $filesToExecuteDeletes) {
        $deleteSP = $f
        # Initialise executes
        $deleteInputFile = "$targetDirectory\$deleteSP.sql"
        $deleteExecQuery = "EXEC samples.$deleteSP"
        $deleteDropQuery = "DROP PROCEDURE samples.$deleteSP"

        & $inputScriptPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -inputFile $deleteInputFile
        Write-Host "Created the Stored Proc $deleteSP"
        & $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $deleteExecQuery
        Write-Host "Executed the Stored Proc $deleteSP"
        & $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $deleteDropQuery
        Write-Host "Dropped the Stored Proc $deleteSP"
    }
}

foreach ($f in $filesToExecuteAdds){
    Write-Host "$f"
    $InputFile = "$targetDirectory\$f.sql"
    & $inputScriptPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -inputFile $InputFile
    Write-Host "Created the Stored Proc $f"
}

# Loop through samples stored procedures in order of Primary/Foreign Key dependencies.
foreach ($f in $filesToExecuteSets){
    Write-Host "$f"
    
    # Initialise executes
    $inputFile = "$targetDirectory\$f.sql"
    $execQuery = "EXEC samples.$f"
    $dropQuery = "DROP PROCEDURE samples.$f"

    & $inputScriptPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -inputFile $inputFile
    Write-Host "Created the Stored Proc $f"
    & $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $execQuery 
    Write-Host "Executed the Stored Proc $f"
    & $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $dropQuery 
    Write-Host "Dropped the Stored Proc $f"
}

foreach ($f in $filesToExecuteAdds){
    Write-Host "$f"
    $DropQuery = "DROP PROCEDURE samples.$f"
    & $queryPath -subscriptionID $subscriptionID -instanceName $instanceName -databaseName $databaseName -query $DropQuery
    Write-Host "Dropped the Stored Proc $f"
}