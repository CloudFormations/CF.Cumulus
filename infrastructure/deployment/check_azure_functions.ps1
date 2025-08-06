param(    
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string] $dataFactoryName,

    [Parameter(Mandatory=$true)]
    [string] $functionAppName
)

# get the function app key
$functionKey = az functionapp keys list --resource-group $resourceGroupName --name $functionAppName --query functionKeys.default -o tsv

#create the body and uri for the function app call
$body = @{subscriptionId=$subscriptionId;
    resourceGroupName=$resourceGroupName;
    orchestratorName=$dataFactoryName;
    orchestratorType="ADF";
    pipelineName="Ingest_PL_RESTAPI"} | ConvertTo-Json

$functionUri = "https://$functionAppName.azurewebsites.net/api/PipelineValidate?code=$functionKey"

# call the function app to validate the pipeline
try {
    $functionResponse = Invoke-WebRequest -Uri $functionUri -Method Post -Body $body -ContentType "application/json"

    if ($functionResponse.StatusCode -eq 200) {
        Write-Output "Function App is working correctly."
    } else {
        Write-Output "Function App returned an error: $($functionResponse.StatusCode)"
    }
}
catch {
    Write-Output "An error occurred while calling the Function App: $_"
}
