using System;
using System.Threading;
using Newtonsoft.Json;
using Microsoft.Extensions.Logging;
using Azure.ResourceManager.DataFactory;
using cloudformations.cumulus.helpers;

using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.Compute;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.DataFactory.Models;
using System.Text;
using Azure;
using Microsoft.Rest.Azure;
using Azure.Analytics.Synapse.Artifacts.Models;
using System.Linq;
using System.Diagnostics;

//https://github.com/Azure/azure-sdk-for-net/blob/Azure.ResourceManager.DataFactory_1.0.0-beta.5/sdk/datafactory/Azure.ResourceManager.DataFactory/README.md
//https://github.com/Azure/azure-sdk-for-net/blob/Azure.ResourceManager.DataFactory_1.0.0-beta.5/sdk/datafactory/Azure.ResourceManager.DataFactory/samples/Generated/Samples/Sample_DataFactoryPipelineResource.cs#L256
//https://learn.microsoft.com/en-us/dotnet/api/azure.resourcemanager.datafactory.datafactoryextensions.getdatafactorypipelineresource?view=azure-dotnet-preview


namespace cloudformations.cumulus.services
{
    public class AzureDataFactoryService : PipelineService
    {
        private ArmClient client = new ArmClient(new DefaultAzureCredential());
        private ResourceIdentifier resourceId;
        private DataFactoryResource dataFactory;
        private DataFactoryPipelineResource dataFactoryPipeline;
        
        private readonly ILogger _logger;

        public AzureDataFactoryService(PipelineRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating ADF connectivity clients.");

            resourceId = DataFactoryResource.CreateResourceIdentifier
                (
                request.SubscriptionId, 
                request.ResourceGroupName, 
                request.OrchestratorName
                );

            dataFactory = client.GetDataFactoryResource(resourceId);
            dataFactoryPipeline = client.GetDataFactoryPipelineResource(resourceId);
        }

        public override PipelineDescription ValidatePipeline(PipelineRequest request)
        {
            _logger.LogInformation("Validating ADF pipeline.");

            try
            {
                DataFactoryPipelineCollection collection = dataFactory.GetDataFactoryPipelines();

                NullableResponse<DataFactoryPipelineResource> response = collection.GetIfExists(request.PipelineName);
                DataFactoryPipelineResource result = response.HasValue ? response.Value : null;

                if (result == null)
                {
                    throw new InvalidRequestException("Failed to validate pipeline. ");
                }
                else
                {
                    _logger.LogInformation("Validated ADF pipeline.");

                    return new PipelineDescription()
                    {
                        PipelineExists = "True",
                        PipelineName = response.Value.Data.Name,
                        PipelineId = response.Value.Data.Id,
                        PipelineType = response.Value.Data.ResourceType,
                        ActivityCount = response.Value.Data.Activities.Count
                    };
                }
            }
            catch (CloudException) //expected exception when pipeline doesnt exist
            {
                return new PipelineDescription()
                {
                    PipelineExists = "False",
                    PipelineName = request.PipelineName,
                    PipelineId = "Unknown",
                    PipelineType = "Unknown",
                    ActivityCount = 0
                };
            }
            catch (Exception ex) //other unknown issue
            {
                _logger.LogInformation(ex.Message);
                _logger.LogInformation(ex.GetType().ToString());
                throw new InvalidRequestException("Failed to validate pipeline. ", ex);
            }
        }

        public override PipelineRunStatus ExecutePipeline(PipelineRequest request)
        {
            if (request.PipelineParameters == null)
                _logger.LogInformation("Calling pipeline without parameters.");
            else
                _logger.LogInformation("Calling pipeline with parameters.");

            string runId = null;
            PipelineCreateRunResult pipelineRunResult;

            pipelineRunResult = dataFactoryPipeline.CreateRun(referencePipelineRunId: runId);
             
            _logger.LogInformation("Pipeline run ID: " + runId);

            DataFactoryPipelineRunInfo runInfo;

            //Wait and check for pipeline to start...
            _logger.LogInformation("Checking ADF pipeline status.");
            while (true)
            {
                runInfo = dataFactory.GetPipelineRun(runId);         

                _logger.LogInformation("Waiting for pipeline to start, current status: " + runInfo.Status);

                if (runInfo.Status != "Queued")
                    break;
                Thread.Sleep(internalWaitDuration);
            }

            return new PipelineRunStatus()
            {
                PipelineName = request.PipelineName,
                RunId = runId,
                ActualStatus = runInfo.Status
            };
        }

        public override PipelineRunStatus CancelPipeline(PipelineRunRequest request)
        {
            _logger.LogInformation("Getting ADF pipeline current status.");

            //Get pipeline status with provided run id
            DataFactoryPipelineRunInfo runInfo;
            runInfo = dataFactory.GetPipelineRun(request.RunId);

            //Defensive check
            PipelineNameCheck(request.PipelineName, runInfo.PipelineName);

            _logger.LogInformation("ADF pipeline status: " + runInfo.Status);

            throw new InvalidRequestException("Pipeline cancellation not currently supported.");
            /*
            

            if (runInfo.Status == "InProgress" || runInfo.Status == "Queued")
            {
                _logger.LogInformation("Attempting to cancel ADF pipeline.");
                _adfManagementClient.PipelineRuns.Cancel
                    (
                    request.ResourceGroupName,
                    request.OrchestratorName,
                    request.RunId,
                    isRecursive : request.RecursivePipelineCancel
                    );
            }
            else
            {
                _logger.LogInformation("ADF pipeline status: " + pipelineRun.Status);
                throw new InvalidRequestException("Target pipeline is not in a state that can be cancelled.");
            }

            //wait for cancelled state
            _logger.LogInformation("Checking ADF pipeline status after cancel request.");
            while (true)
            {
                pipelineRun = _adfManagementClient.PipelineRuns.Get
                    (
                    request.ResourceGroupName,
                    request.OrchestratorName,
                    request.RunId
                    );

                _logger.LogInformation("Waiting for pipeline to cancel, current status: " + pipelineRun.Status);

                if (pipelineRun.Status == "Cancelled")
                    break;
                Thread.Sleep(internalWaitDuration);
            }
           
            //Final return detail
            return new PipelineRunStatus()
            {
                PipelineName = request.PipelineName,
                RunId = request.RunId,
                ActualStatus = pipelineRun.Status.Replace("Canceling", "Cancelling") //microsoft typo
            };
             */
        }

        public override PipelineRunStatus GetPipelineRunStatus(PipelineRunRequest request)
        {
            _logger.LogInformation("Checking ADF pipeline status.");

            //Get pipeline status with provided run id
            DataFactoryPipelineRunInfo runInfo;
            runInfo = dataFactory.GetPipelineRun(request.RunId);

            //Defensive check
            PipelineNameCheck(request.PipelineName, runInfo.PipelineName);

            _logger.LogInformation("ADF pipeline status: " + runInfo.Status);

            //Final return detail
            return new PipelineRunStatus()
            {
                PipelineName = request.PipelineName,
                RunId = request.RunId,
                ActualStatus = runInfo.Status.Replace("Canceling", "Cancelling") //microsoft typo
            };
        }

        public override PipelineErrorDetail GetPipelineRunActivityErrors(PipelineRunRequest request)
        {
            //Get pipeline status with provided run id
            DataFactoryPipelineRunInfo runInfo;
            runInfo = dataFactory.GetPipelineRun(request.RunId);

            _logger.LogInformation("ADF pipeline status: " + runInfo.Status);
            
            //Defensive check
            PipelineNameCheck(request.PipelineName, runInfo.PipelineName);

            _logger.LogInformation("Create pipeline Activity Runs query filters.");



            RunFilterContent filterParams = new RunFilterContent
                (
                request.ActivityQueryStart, 
                request.ActivityQueryEnd
                );

            //PipelineActivityRunInformation queryResponse;
            Pageable<PipelineActivityRunInformation> queryResponses = dataFactory.GetActivityRun(request.RunId, filterParams);

            //Create initial output content
            PipelineErrorDetail output = new PipelineErrorDetail()
            {
                PipelineName = request.PipelineName,
                ActualStatus = runInfo.Status,
                RunId = request.RunId,
                ResponseCount = queryResponses.Count()
            };

            _logger.LogInformation("Pipeline status: " + runInfo.Status);
            _logger.LogInformation("Activities found in pipeline response: " + queryResponses.Count().ToString());

            foreach (PipelineActivityRunInformation queryResponse in queryResponses)
            {
                if (queryResponse.Error == null)
                {
                    continue; //only want errors
                }

                //Parse error output to customise output
                dynamic outputBlockInner = BinaryData.FromObjectAsJson(queryResponse.Error);
                string errorCode = outputBlockInner?.errorCode;
                string errorType = outputBlockInner?.failureType;
                string errorMessage = outputBlockInner?.message;

                _logger.LogInformation("Activity run id: " + queryResponse.ActivityRunId.ToString());
                _logger.LogInformation("Activity name: " + queryResponse.ActivityName);
                _logger.LogInformation("Activity type: " + queryResponse.ActivityType);
                _logger.LogInformation("Error message: " + errorMessage);

                output.Errors.Add(new FailedActivity()
                {
                    ActivityRunId = queryResponse.ActivityRunId.ToString(),
                    ActivityName = queryResponse.ActivityName,
                    ActivityType = queryResponse.ActivityType,
                    ErrorCode = errorCode,
                    ErrorType = errorType,
                    ErrorMessage = errorMessage
                });
            }
            return output;
        }

        public override void Dispose()
        {
            //nothing to dispose, handling by Microsoft
        }
    }
}