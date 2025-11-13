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
        private readonly HttpClient _generalClient;
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

            bearerToken = fabricClient.GetBearerToken();
            _logger.LogDebug(bearerToken);

            // create a reusable client for generic Fabric REST calls (authorization header set once)
            _generalClient = new HttpClient();
            _generalClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

            // Resolve workspace Id (synchronous caller - use GetAwaiter().GetResult to preserve constructor signature)
            workspaceId = ResolveWorkspaceIdAsync(request.OrchestratorName, CancellationToken.None).GetAwaiter().GetResult();
            _logger.LogInformation("Resolved workspace Id: " + workspaceId);
        }
        
        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {
            // Keep method synchronous by using Task.GetAwaiter().GetResult() around async helpers
            try
            {
                pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None).GetAwaiter().GetResult();
                _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);

                _logger.LogInformation("Creating data pipeline run instance request.");

                // Build parameters payload
                var parameters = new JObject();
                foreach (var kv in request.PipelineParameters)
                {
                    if (string.IsNullOrEmpty(kv.Value)) continue;
                    _logger.LogInformation($"Adding parameter key: {kv.Key} value: {kv.Value} to pipeline call.");
                    // Fabric often expects parameter values wrapped as JSON strings or typed objects. Using raw value here.
                    parameters[kv.Key] = JToken.FromObject(kv.Value);
                }

                var payload = new JObject
                {
                    ["parameters"] = parameters
                };

                var content = new StringContent(payload.ToString(), Encoding.UTF8, "application/json");

                // Post job instance for pipeline and parameters (pbiApiClient expected to be HttpClient)
                var postUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances?jobType=Pipeline";
                var postTask = pbiApiClient.PostAsync(postUrl, content);
                postTask.Wait();
                var postResponse = postTask.Result;

                string pipelineRunId = String.Empty;
                if (postResponse.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Data pipeline run instance response status: " + postResponse.StatusCode);
                    var location = postResponse.Headers.Location?.OriginalString;
                    if (!string.IsNullOrEmpty(location))
                    {
                        var parts = location.Split('/').ToList();
                        pipelineRunId = parts.Last();
                    }
                }
                else
                {
                    var error = postResponse.Content.ReadAsStringAsync().Result;
                    _logger.LogError("Pipeline run creation failed: " + error);
                    throw new Exception($"Pipeline run creation failed: {postResponse.StatusCode}");
                }

                return new PipelineRunStatus()
                {
                    PipelineName = request.PipelineName,
                    RunId = pipelineRunId,
                    ActualStatus = "Not Started"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "PipelineExecute failed.");
                throw;
            }
        }

        public override PipelineErrorDetail PipelineGetErrorDetails(PipelineRunRequest request)
        {
            try
            {
                // Resolve pipeline id using shared async helper (kept synchronous for API compatibility)
                pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                    .GetAwaiter().GetResult();

                _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);

                // Get job instance via reusable _generalClient helper
                var jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";
                var pipelineRunResponse = SendGetAndDeserializeAsync<FabricJobInstance>(jobUrl, CancellationToken.None)
                    .GetAwaiter().GetResult();

                if (pipelineRunResponse is null)
                    throw new Exception("FabricJobInstance response was null.");

                var output = new PipelineErrorDetail()
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
                    ActivityType = pipelineRunResponse.JobType ?? "Unknown",
                    ErrorCode = pipelineRunResponse.FailureReason?.ErrorCode,
                    ErrorType = pipelineRunResponse.JobType,
                    ErrorMessage = pipelineRunResponse.FailureReason?.Message
                });

                return output;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "PipelineGetErrorDetails failed.");
                throw;
            }
        }

        public override PipelineRunStatus PipelineGetStatus(PipelineRunRequest request)
        {
            try
            {
                // Resolve pipeline id using the common async helper (kept synchronous for API compatibility)
                pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                    .GetAwaiter().GetResult();

                _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);

                var jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";

                // Use the reusable _generalClient helper to GET and deserialize the job instance
                var pipelineRunResponse = SendGetAndDeserializeAsync<FabricJobInstance>(jobUrl, CancellationToken.None)
                    .GetAwaiter().GetResult();

                if (pipelineRunResponse is null)
                {
                    throw new Exception("FabricJobInstance response was null.");
                }

                return new PipelineRunStatus
                {
                    PipelineName = request.PipelineName,
                    ActualStatus = pipelineRunResponse.JobStatus,
                    RunId = request.RunId
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "PipelineGetStatus failed.");
                throw;
            }
        }
        
        public override PipelineDescription PipelineValidate(PipelineRequest request)
        {
            _logger.LogInformation("Checking pipeline Id.");

            try
            {
                // Resolve pipeline id using shared async helper (kept synchronous for API compatibility)
                pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                    .GetAwaiter().GetResult();

                _logger.LogInformation("Resolved pipeline Id: " + pipelineId);

                return new PipelineDescription()
                {
                    PipelineExists = "True",
                    PipelineName = request.PipelineName,
                    PipelineId = pipelineId,
                    PipelineType = "Unknown",
                    ActivityCount = 0
                };
            }
            catch (InvalidOperationException)
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

        private async Task<T?> SendGetAndDeserializeAsync<T>(string url, CancellationToken ct = default)
        {
            var resp = await _generalClient.GetAsync(url, ct).ConfigureAwait(false);
            resp.EnsureSuccessStatusCode();
            var s = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
            return JsonConvert.DeserializeObject<T>(s);
        }

        private async Task<string> ResolveWorkspaceIdAsync(string workspaceDisplayName, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(workspaceDisplayName))
                throw new ArgumentException("workspaceDisplayName is required", nameof(workspaceDisplayName));

            var url = "https://api.fabric.microsoft.com/v1/workspaces";
            var workspaceResponse = await SendGetAndDeserializeAsync<FabricWorkspaces>(url, ct).ConfigureAwait(false);

            if (workspaceResponse is null || workspaceResponse.Value == null)
                throw new Exception("Fabric Workspaces response was null.");

            var id = workspaceResponse.Value
                .AsQueryable()
                .Where(w => w.DisplayName.Equals(workspaceDisplayName, StringComparison.OrdinalIgnoreCase))
                .Select(w => w.Id)
                .FirstOrDefault();

            if (string.IsNullOrEmpty(id))
                throw new InvalidOperationException($"Workspace '{workspaceDisplayName}' not found.");

            return id;
        }

        private async Task<string> ResolvePipelineIdAsync(string workspaceId, string pipelineName, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(workspaceId)) throw new ArgumentException(nameof(workspaceId));
            if (string.IsNullOrWhiteSpace(pipelineName)) throw new ArgumentException(nameof(pipelineName));

            var url = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items?type=DataPipeline";
            var pipelineResponse = await SendGetAndDeserializeAsync<FabricDataPipelines>(url, ct).ConfigureAwait(false);

            if (pipelineResponse is null || pipelineResponse.Value == null)
                throw new Exception("FabricDataPipelines response was null.");

            var id = pipelineResponse.Value
                .AsQueryable()
                .Where(p => p.DisplayName.Equals(pipelineName, StringComparison.OrdinalIgnoreCase))
                .Select(p => p.Id)
                .FirstOrDefault();

            if (string.IsNullOrEmpty(id))
                throw new InvalidOperationException($"Pipeline '{pipelineName}' not found in workspace '{workspaceId}'.");

            return id;
        }

        public override void Dispose()
        {
            try
            {
                _generalClient?.Dispose();
                pbiApiClient?.Dispose();

                // if fabApiClient was created as Task<HttpClient> keep this defensive check
                if (fabApiClient != null && fabApiClient.IsCompletedSuccessfully)
                {
                    fabApiClient.Result?.Dispose();
                }

                // if FabricClient implements IDisposable, dispose it:
                (fabricClient as IDisposable)?.Dispose();
            }
            finally
            {
                GC.SuppressFinalize(this);
            }
        }
    }
}
