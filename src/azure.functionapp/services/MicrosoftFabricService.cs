using Azure;
using Azure.Identity;
using Azure.ResourceManager;
using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Client;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;
using System.Net.Http.Headers;
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

        public MicrosoftFabricService(PipelineRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating FAB connectivity client.");

            fabricClient = new FabricClient(true);
            pbiApiClient = fabricClient.CreatePowerBIAPIClient();
            fabApiClient = fabricClient.CreateFabricAPIClient();
            workspaceId = String.Empty;
            pipelineId = String.Empty;
        }

        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {
            Console.WriteLine("Getting Fabric API bearer token.");

            string bearerToken = fabricClient.GetBearerToken();

            _logger.LogDebug(bearerToken);

            Task<HttpResponseMessage> wsResponse;
            Task<HttpResponseMessage> pipeResponse;
            Task<HttpResponseMessage> pipeRunResponse;

            //use Fabric API to resolve guid values from reference names before making instance call
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                //resolve workspace id
                _logger.LogInformation("Getting workspace Id.");

                HttpRequestMessage wsRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces");
                wsResponse = client.SendAsync(wsRequest);
                wsResponse.Wait();

                _logger.LogInformation("Getting workspace response status: " + wsResponse.Result.StatusCode);

                if (wsResponse.IsCompleted) 
                {
                    FabricWorkspaces? workspaceResponse = JsonConvert.DeserializeObject<FabricWorkspaces>(wsResponse.Result.Content.ReadAsStringAsync().Result);

                    if(workspaceResponse is null)
                    {
                        throw new Exception("FabricWorkspaces workspaceResponse is null. Check content response values from client request.");
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

                //resolve pipeline id
                _logger.LogInformation("Getting pipeline Id.");

                HttpRequestMessage pipeRequest = new HttpRequestMessage(HttpMethod.Get, $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline");
                pipeResponse = client.SendAsync(pipeRequest);
                pipeResponse.Wait();

                _logger.LogInformation("Getting workspace response status: " + pipeResponse.Result.StatusCode);

                if (pipeResponse.IsCompleted)
                { 
                    FabricDataPipelines? pipelineResponse = JsonConvert.DeserializeObject<FabricDataPipelines>(pipeResponse.Result.Content.ReadAsStringAsync().Result);

                    if (pipelineResponse is null)
                    {
                        throw new Exception("FabricDataPipelines pipelineResponse is null. Check content response values from client request.");
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
            }

            _logger.LogInformation("Data pipeline run instance request.");

            pipeRunResponse = pbiApiClient.PostAsync($"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances?jobType=Pipeline",null);
            pipeRunResponse.Wait();

            List<string> parts;
            String pipelineRunId = String.Empty;
            string pipelineRunLocation;

            if (pipeRunResponse.IsCompleted) 
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
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineGetStatus(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineDescription PipelineValidate(PipelineRequest request)
        {
            throw new NotImplementedException();
        }
        public override void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
