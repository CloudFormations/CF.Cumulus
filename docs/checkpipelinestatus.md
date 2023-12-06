# Check Pipeline Status

___
[<< Contents](/procfwk/contents) / [Functions](/procfwk/functions)

___

## Role

Queries the target worker pipeline and [orchestrator](/procfwk/orchestrators) type for the status of the pipeline run. Returning the actual pipline status and a simplified status for internal use.

Namespace: __mrpaulandrew.azure.procfwk__.

## Method

GET, POST

## Example Input

```json
{
"tenantId": "123-123-123-123-1234567",
"applicationId": "123-123-123-123-1234567",
"authenticationKey": "Passw0rd123!",
"subscriptionId": "123-123-123-123-1234567",
"resourceGroupName": "ADF.procfwk",
"orchestratorName": "FrameworkFactory",
"orchestratorType": "ADF",
"pipelineName": "Intentional Error",
"runId": "123-123-123-123-1234567"
}
```

## Return

See [Services](/procfwk/services) return classes.

## Example Output

```json
{
"PipelineName": "Intentional Error",
"RunId": "c5c2e1e7-bdc8-4eec-b015-cd1aa498b0a4",
"ActualStatus": "Failed",
"SimpleStatus": "Complete"
}
```

___