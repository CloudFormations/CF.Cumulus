using System;
using Newtonsoft.Json;

using Azure;
using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.DataFactory;
using Azure.ResourceManager.DataFactory.Models;

using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using System.Web;

namespace cloudformations.cumulus.services
{
    public class AzureDataFactoryService : PipelineService
    {
        private ArmClient client;
        private ResourceIdentifier factoryResourceId;
        private ResourceIdentifier pipelineResourceId;
        private DataFactoryResource dataFactory;
        private DataFactoryPipelineResource dataFactoryPipeline;
        private ILogger _logger;

        public AzureDataFactoryService(PipelineRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating ADF connectivity clients.");

            client = new ArmClient(new DefaultAzureCredential());

            factoryResourceId = DataFactoryResource.CreateResourceIdentifier
                (
                request.SubscriptionId,
                request.ResourceGroupName,
                request.OrchestratorName
                );

            pipelineResourceId = DataFactoryPipelineResource.CreateResourceIdentifier
                (
                request.SubscriptionId,
                request.ResourceGroupName,
                request.OrchestratorName,
                request.PipelineName
                );

            dataFactory = client.GetDataFactoryResource(factoryResourceId);
            dataFactoryPipeline = client.GetDataFactoryPipelineResource(pipelineResourceId);
        }

        public override PipelineDescription PipelineValidate(PipelineRequest request)
        {
            _logger.LogInformation("Validating ADF pipeline.");

            DataFactoryPipelineCollection collection = dataFactory.GetDataFactoryPipelines();

            NullableResponse<DataFactoryPipelineResource> response = collection.GetIfExists(request.PipelineName);
            DataFactoryPipelineResource? result = response.HasValue ? response.Value : null;

            ArgumentNullException.ThrowIfNull(request.PipelineName);

            if (result == null)
            {
                _logger.LogInformation("Validated ADF pipeline does not exist.");

                return new PipelineDescription()
                {
                    PipelineExists = "False",
                    PipelineName = request.PipelineName,
                    PipelineId = "Unknown",
                    PipelineType = "Unknown",
                    ActivityCount = 0
                };
            }
            else
            {
                _logger.LogInformation("Validated ADF pipeline exists.");

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

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {
            PipelineCreateRunResult pipelineRunResult;
            Dictionary<string, BinaryData> adfParameters;
            string? runId;

            if (request.PipelineParameters == null)
            {
                _logger.LogInformation("Calling pipeline without parameters.");
                pipelineRunResult = dataFactoryPipeline.CreateRun();
                
                runId = pipelineRunResult.RunId.ToString();
            }
            else
            {
                _logger.LogInformation("Calling pipeline with parameters.");
                
                adfParameters = [];
                foreach (var key in request.PipelineParameters.Keys)
                {
                    if (String.IsNullOrEmpty(request.PipelineParameters[key])) continue;

                    _logger.LogInformation($"Adding parameter key: {key} value: {request.PipelineParameters[key]} to pipeline call.");

                    adfParameters.Add(key, BinaryData.FromString('"' + request.PipelineParameters[key] + '"')); //adding " marks feels like a hack, but because parameters are passed from JSON call to a JSON call via a dictionary seems to be needed in BinaryData.FromString conversion!
                }
                
                pipelineRunResult = dataFactoryPipeline.CreateRun(parameterValueSpecification: adfParameters);
                
                runId = pipelineRunResult.RunId.ToString();
            }

            _logger.LogInformation("Pipeline run ID: " + runId);

            DataFactoryPipelineRunInfo runInfo;
            ArgumentNullException.ThrowIfNull(request.PipelineName);

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

        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineGetStatus(PipelineRunRequest request)
        {
            _logger.LogInformation("Checking ADF pipeline status.");

            //Get pipeline status with provided run id
            DataFactoryPipelineRunInfo runInfo;
            runInfo = dataFactory.GetPipelineRun(request.RunId);

            //Defensive check
            ArgumentNullException.ThrowIfNull(request.RunId);
            ArgumentNullException.ThrowIfNull(request.PipelineName);
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

        public override PipelineErrorDetail PipelineGetErrorDetails(PipelineRunRequest request)
        {
            //Get pipeline status with provided run id
            DataFactoryPipelineRunInfo runInfo;
            runInfo = dataFactory.GetPipelineRun(request.RunId);

            _logger.LogInformation("ADF pipeline status: " + runInfo.Status);

            //Defensive check
            ArgumentNullException.ThrowIfNull(request.RunId);
            ArgumentNullException.ThrowIfNull(request.PipelineName);
            PipelineNameCheck(request.PipelineName, runInfo.PipelineName);

            _logger.LogInformation("Create pipeline Activity Runs query filters.");

            RunFilterContent filterParams = new RunFilterContent
                (
                request.ActivityQueryStart, 
                request.ActivityQueryEnd
                );

            //PipelineActivityRunInformation queryResponse;
            Pageable<PipelineActivityRunInformation> queryResponses = dataFactory.GetActivityRun(request.RunId, filterParams);

            int responseCount = queryResponses.Count();
            int responsePage = 0;

            //Create initial output content
            PipelineErrorDetail output = new PipelineErrorDetail()
            {
                PipelineName = request.PipelineName,
                ActualStatus = runInfo.Status,
                RunId = request.RunId,
                ResponseCount = responseCount
            };

            _logger.LogInformation("Pipeline status: " + runInfo.Status);
            _logger.LogInformation("Activities found in pipeline response: " + responseCount.ToString());

            foreach (PipelineActivityRunInformation queryResponse in queryResponses)
            {
                responsePage = responsePage + 1;
                //Parse output to customise error content
                _logger.LogInformation($"Parsing activity response page {responsePage} of {responseCount} information.");

                dynamic? outputBlockInner = JsonConvert.DeserializeObject(queryResponse.Error.ToString());
                string? errorCode = outputBlockInner?.errorCode;
                string? errorType = outputBlockInner?.failureType;
                string? errorMessage = outputBlockInner?.message;

                if (String.IsNullOrWhiteSpace(errorCode))
                {
                    _logger.LogInformation($"Skipping activity information for '{queryResponse.ActivityName}' as not errored.");
                    continue; //only want to return errors
                }

                Guid runId = (Guid)queryResponse.ActivityRunId;

                _logger.LogInformation("Errored activity found in result. Capturing details.");
                _logger.LogInformation("Errored activity run id: " + runId.ToString());

                ArgumentNullException.ThrowIfNull(errorType);
                ArgumentNullException.ThrowIfNull(errorMessage);

                output.Errors.Add(new FailedActivity()
                {
                    ActivityRunId = runId.ToString(),
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
            GC.SuppressFinalize(this);
        }
    }
}