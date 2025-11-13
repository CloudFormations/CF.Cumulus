using Azure;
using Azure.Analytics.Synapse.Artifacts.Models;
using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.DataFactory;
using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Client;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Policy;
using System.Text;
using Windows.Media.Protection.PlayReady;

namespace cloudformations.cumulus.services
{
    public class MicrosoftFabricService : PipelineService
    {
        private readonly ILogger _logger;
        private FabricClient fabricClient;
        private HttpClient pbiApiClient;
        private Task<HttpClient> fabApiClient;
        private string workspaceId;
        private string pipelineId;
        private string bearerToken;

        public MicrosoftFabricService(PipelineRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating FAB connectivity clientGeneral.");

            fabricClient = new FabricClient(true);
            pbiApiClient = fabricClient.CreatePowerBIAPIClient();
            fabApiClient = fabricClient.CreateFabricAPIClient();

            workspaceId = String.Empty;
            pipelineId = String.Empty;

            Task<HttpResponseMessage> wsResponse;

            bearerToken = fabricClient.GetBearerToken();
            _logger.LogDebug(bearerToken);

            //Resolve workspace Id regardless of service calls
            using (var clientGeneral = new HttpClient())
            {
                clientGeneral.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                //resolve workspace id
                _logger.LogInformation("Getting workspace Id.");

                HttpRequestMessage wsRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces");
                wsResponse = clientGeneral.SendAsync(wsRequest);
                wsResponse.Wait();

                _logger.LogInformation("Getting workspace response status: " + wsResponse.Result.StatusCode);

                if (wsResponse.IsCompleted)
                {
                    FabricWorkspaces? workspaceResponse = JsonConvert.DeserializeObject<FabricWorkspaces>(wsResponse.Result.Content.ReadAsStringAsync().Result);

                    if (workspaceResponse is null)
                    {
                        throw new Exception("Fabric Workspaces workspaceResponse is null. Check content response values from clientGeneral request.");
                    }
                    else
                    {
                        workspaceId = workspaceResponse.Value
                            .AsQueryable()
                            .Where(workspace => workspace.DisplayName.Equals(request.OrchestratorName, StringComparison.OrdinalIgnoreCase))
                            .Select(workspace => workspace.Id)
                            .First();

                        _logger.LogInformation("Resolved workspace Id: " + workspaceId);
                    }
                }
            }
        }
        
        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {         
            Task<HttpResponseMessage> pipeResponse;
            Task<HttpResponseMessage> pipeRunResponse;

            //Resolve pipeline Id
            using (var clientExecute = new HttpClient())
            {
                
                clientExecute.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                _logger.LogInformation("Getting pipeline Id for workspace Id: " + workspaceId);

                HttpRequestMessage pipeRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline");
                pipeResponse = clientExecute.SendAsync(pipeRequest);
                pipeResponse.Wait();

                _logger.LogInformation("Getting pipeline Id response status: " + pipeResponse.Result.StatusCode);

                if (pipeResponse.IsCompleted)
                { 
                    FabricDataPipelines? pipelineResponse = JsonConvert.DeserializeObject<FabricDataPipelines>(pipeResponse.Result.Content.ReadAsStringAsync().Result);

                    if (pipelineResponse is null)
                    {
                        throw new Exception("FabricDataPipelines pipelineResponse is null. Check content response values from clientGeneral request.");
                    }
                    else
                    {
                        pipelineId = pipelineResponse.Value
                            .AsQueryable()
                            .Where(workspace => workspace.DisplayName.Equals(request.PipelineName, StringComparison.OrdinalIgnoreCase))
                            .Select(workspace => workspace.Id)
                            .First();

                        _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                    }
                }
            }

            //Using resolved Ids to create a job instance
            _logger.LogInformation("Creating data pipeline run instance request.");

            //Build dictionary to house pipeline parameters
            Dictionary<string, BinaryData> pipeParameters;
            pipeParameters = [];

            foreach (var key in request.PipelineParameters.Keys)
            {
                if (String.IsNullOrEmpty(request.PipelineParameters[key])) continue;

                _logger.LogInformation($"Adding parameter key: {key} value: {request.PipelineParameters[key]} to pipeline call.");

                pipeParameters.Add(key, BinaryData.FromString('"' + request.PipelineParameters[key] + '"')); 
            }

            //Convert dictionary of pipeline parameters for API content call
            var json = JsonConvert.SerializeObject(pipeParameters);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            //Post job instance for pipeline and parameters
            pipeRunResponse = pbiApiClient.PostAsync($"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances?jobType=Pipeline", content);
            pipeRunResponse.Wait();

            List<string> parts;
            String pipelineRunId = String.Empty;
            string pipelineRunLocation;

            //Check run instance details
            if (pipeRunResponse.IsCompletedSuccessfully) 
            {
                _logger.LogInformation("Data pipeline run instance response status: " + pipeRunResponse.Result.StatusCode);
                _logger.LogDebug(pipeRunResponse.Result.ToString());

                pipelineRunLocation = pipeRunResponse.Result.Headers.Location.OriginalString;
                parts = pipelineRunLocation.Split('/').ToList();
                pipelineRunId = parts.Last();
            }

            _logger.LogInformation("Data pipeline run instance creating return details.");

            return new PipelineRunStatus()
            {
                PipelineName = request.PipelineName,
                RunId = pipelineRunId,
                ActualStatus = "Not Started"
            };
        }

        public override PipelineErrorDetail PipelineGetErrorDetails(PipelineRunRequest request)
        {
            HttpRequestMessage pipeRequest;
            HttpRequestMessage pipeRunRequest;
            Task<HttpResponseMessage> pipeResponse;
            Task<HttpResponseMessage> pipeRunResponse;
            FabricJobInstance? pipelineRunResponse;

            //Resolve pipeline Id & get job instance status
            using (var clientError = new HttpClient())
            {
                clientError.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                _logger.LogInformation("Getting pipeline Id for workspace Id: " + workspaceId);

                pipeRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline");
                pipeResponse = clientError.SendAsync(pipeRequest);
                pipeResponse.Wait();

                _logger.LogInformation("Getting pipeline Id response status: " + pipeResponse.Result.StatusCode);

                if (pipeResponse.IsCompleted)
                {
                    FabricDataPipelines? pipelineResponse = JsonConvert.DeserializeObject<FabricDataPipelines>(pipeResponse.Result.Content.ReadAsStringAsync().Result);

                    if (pipelineResponse is null)
                    {
                        throw new Exception("FabricDataPipelines pipelineResponse is null. Check content response values from clientGeneral request.");
                    }
                    else
                    {
                        pipelineId = pipelineResponse.Value
                            .AsQueryable()
                            .Where(workspace => workspace.DisplayName.Equals(request.PipelineName, StringComparison.OrdinalIgnoreCase))
                            .Select(workspace => workspace.Id)
                            .First();

                        _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                    }
                }

                string jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";

                pipeRunRequest = new HttpRequestMessage(HttpMethod.Get, jobUrl);
                pipeRunResponse = clientError.SendAsync(pipeRunRequest);
                pipeRunResponse.Wait();

                _logger.LogDebug(pipeRunResponse.Result.Content.ReadAsStringAsync().Result.ToString());

                pipelineRunResponse = JsonConvert.DeserializeObject<FabricJobInstance>(pipeRunResponse.Result.Content.ReadAsStringAsync().Result);
            }

            PipelineErrorDetail output = new PipelineErrorDetail()
            {
                PipelineName = request.PipelineName,
                ActualStatus = pipelineRunResponse.JobStatus,
                RunId = request.RunId,
                ResponseCount = 1
            };

            output.Errors.Add(new FailedActivity()
            {
                ActivityRunId = pipelineRunResponse.RootActivityId.ToString(),
                ActivityName = "Unknown",
                ActivityType = "Unknown",
                ErrorCode = pipelineRunResponse.FailureReason.ErrorCode,
                ErrorType = pipelineRunResponse.JobType,
                ErrorMessage = pipelineRunResponse.FailureReason.Message
            });

            return output;
        }

        public override PipelineRunStatus PipelineGetStatus(PipelineRunRequest request)
        {
            HttpRequestMessage pipeRequest;
            HttpRequestMessage pipeRunRequest;
            Task<HttpResponseMessage> pipeResponse;
            Task<HttpResponseMessage> pipeRunResponse;
            FabricJobInstance? pipelineRunResponse;

            //Resolve pipeline Id & get job instance status
            using (var clientStatus = new HttpClient())
            {
                clientStatus.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                _logger.LogInformation("Getting pipeline Id for workspace Id: " + workspaceId);

                pipeRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline");
                pipeResponse = clientStatus.SendAsync(pipeRequest);
                pipeResponse.Wait();

                _logger.LogInformation("Getting pipeline Id response status: " + pipeResponse.Result.StatusCode);

                if (pipeResponse.IsCompleted)
                {
                    FabricDataPipelines? pipelineResponse = JsonConvert.DeserializeObject<FabricDataPipelines>(pipeResponse.Result.Content.ReadAsStringAsync().Result);

                    if (pipelineResponse is null)
                    {
                        throw new Exception("FabricDataPipelines pipelineResponse is null. Check content response values from clientGeneral request.");
                    }
                    else
                    {
                        pipelineId = pipelineResponse.Value
                            .AsQueryable()
                            .Where(workspace => workspace.DisplayName.Equals(request.PipelineName, StringComparison.OrdinalIgnoreCase))
                            .Select(workspace => workspace.Id)
                            .First();

                        _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                    }
                }

                string jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";

                pipeRunRequest = new HttpRequestMessage(HttpMethod.Get, jobUrl);
                pipeRunResponse = clientStatus.SendAsync(pipeRunRequest);            
                pipeRunResponse.Wait();

                _logger.LogInformation(pipeRunResponse.Result.Content.ReadAsStringAsync().Result.ToString());

                pipelineRunResponse = JsonConvert.DeserializeObject<FabricJobInstance>(pipeRunResponse.Result.Content.ReadAsStringAsync().Result);
            }

            return new PipelineRunStatus
            {
                PipelineName = request.PipelineName,
                ActualStatus = pipelineRunResponse.JobStatus,
                RunId = request.RunId
            };
        }

        public override PipelineDescription PipelineValidate(PipelineRequest request)
        {
            _logger.LogInformation("Checking pipeline Id.");

            Task<HttpResponseMessage> pipeResponse;

            try
            {
                using (var clientValidate = new HttpClient())
                {
                    clientValidate.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                    _logger.LogInformation("Getting pipeline Id for workspace Id: " + workspaceId);
                    HttpRequestMessage pipeRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline");
                    pipeResponse = clientValidate.SendAsync(pipeRequest);
                    pipeResponse.Wait();
                }

                if (pipeResponse.IsCompleted)
                {
                    FabricDataPipelines? pipelineResponse = JsonConvert.DeserializeObject<FabricDataPipelines>(pipeResponse.Result.Content.ReadAsStringAsync().Result);

                    if (pipelineResponse is null)
                    {
                        throw new InvalidRequestException("FabricDataPipelines pipelineResponse is null. Check content response values from clientValidate request.");
                    }
                    else
                    {
                        pipelineId = pipelineResponse.Value
                            .AsQueryable()
                            .Where(workspace => workspace.DisplayName.Equals(request.PipelineName, StringComparison.OrdinalIgnoreCase))
                            .Select(workspace => workspace.Id)
                            .First();

                        _logger.LogInformation("Resolved pipeline Id: " + pipelineId);
                    }
                }

                return new PipelineDescription()
                {
                    PipelineExists = "True",
                    PipelineName = request.PipelineName,
                    PipelineId = pipelineId,
                    PipelineType = "Unknown",
                    ActivityCount = 0
                };
            }
            catch (System.InvalidOperationException)
            {
                _logger.LogInformation("Validated FAB pipeline does not exist.");

                return new PipelineDescription()
                {
                    PipelineExists = "False",
                    PipelineName = request.PipelineName,
                    PipelineId = "Unknown",
                    PipelineType = "Unknown",
                    ActivityCount = 0
                };
            }
            catch (Exception ex)
            {
                _logger.LogInformation(ex.Message);
                _logger.LogInformation(ex.GetType().ToString());
                throw new InvalidRequestException("Failed to validate pipeline. ", ex);
            }

        }
        public override void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
