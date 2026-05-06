using Azure.Analytics.Synapse.Artifacts.Models;
using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;


namespace cloudformations.cumulus.services
{
    public class MicrosoftFabricService : PipelineService
    {
        private readonly ILogger _logger;
        private FabricClient fabricClient;
        private HttpClient pbiApiClient;
        private Task<HttpClient> fabApiClient;
        private readonly HttpClient generalClient;
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

            //Get bearer for all requests
            bearerToken = fabricClient.GetBearerToken();
            _logger.LogDebug(bearerToken);

            // create a reusable client for generic Fabric REST calls (authorization header set once)
            generalClient = new HttpClient();
            generalClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

            if (!String.IsNullOrEmpty(request.OrchestratorName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
            {
                // Resolve workspace Id (synchronous caller - use GetAwaiter().GetResult to preserve constructor signature)
                workspaceId = ResolveWorkspaceIdAsync(request.OrchestratorName, CancellationToken.None).GetAwaiter().GetResult();
                
                _logger.LogInformation("Resolved workspace Id: " + workspaceId);
            }
        }
        
        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            if (!String.IsNullOrEmpty(request.PipelineName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
            {
                // Resolve pipeline id using the common async helper (kept synchronous for API compatibility)
                pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                .GetAwaiter().GetResult();

                _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
            }

            string jobUrl = String.Empty;
            HttpResponseMessage? postResponse = null; //Declared here to support IF condition wrap for pipeline params.
            FabricJobInstance? pipelineRunResponse; //Declared here to support IF condition wrap for pipeline params.

            // Use the reusable _generalClient helper to GET and deserialize the job instance
            jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}/cancel";

            var postTask = pbiApiClient.PostAsync(jobUrl, null);
            postTask.Wait();
            postResponse = postTask.Result;

            Thread.Sleep(3000); //give the job instance handler a chance to excute the cancel request before checking

            //Check status after cancel request
            if (postResponse.IsSuccessStatusCode)
            {
                _logger.LogInformation("Data pipeline run instance response status: " + postResponse.StatusCode);

                // Use the reusable _generalClient helper to GET and deserialize the job instance
                jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";

                pipelineRunResponse = SendGetAndDeserializeAsync<FabricJobInstance>(jobUrl, CancellationToken.None)
                    .GetAwaiter().GetResult();
            }
            else
            {
                var error = postResponse.Content.ReadAsStringAsync().Result;
                _logger.LogError("Pipeline run creation failed: " + error);
                throw new Exception($"Pipeline run creation failed: {postResponse.StatusCode}");
            }

            return new PipelineRunStatus
            {
                PipelineName = request.PipelineName,
                ActualStatus = pipelineRunResponse.JobStatus,
                RunId = request.RunId
            };
        }

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {
            // Keep method synchronous by using Task.GetAwaiter().GetResult() around async helpers
            try
            {
                if (!String.IsNullOrEmpty(request.PipelineName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
                {
                    pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None).GetAwaiter().GetResult();
                    _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                }

                StringContent content;
                string pipelineRunId = String.Empty;
                string postUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances?jobType=Pipeline";

                _logger.LogDebug(postUrl);

                Task<HttpResponseMessage>? postTask = null; //Declared here to support IF condition wrap for pipeline params.
                HttpResponseMessage? postResponse = null; //Declared here to support IF condition wrap for pipeline params.

                if (request.PipelineParameters == null)
                {
                    _logger.LogInformation("Creating data pipeline run instance request without parameters.");

                    postTask = pbiApiClient.PostAsync(postUrl, null);
                    postTask.Wait();
                    postResponse = postTask.Result;
                }
                else
                {
                    _logger.LogInformation("Creating data pipeline run instance request with parameters.");

                    //Build dictionary to house pipeline parameters
                    Dictionary<string, string> pipeParameters;
                    pipeParameters = [];

                    foreach (var key in request.PipelineParameters.Keys) //pipeline parameters can be null and not used
                    {
                        if (String.IsNullOrEmpty(request.PipelineParameters[key])) continue;

                        _logger.LogInformation($"Adding parameter key: {key} value: {request.PipelineParameters[key]} to pipeline call.");

                        pipeParameters.Add(key, request.PipelineParameters[key]);
                    }

                    //Convert dictionary of pipeline parameters for API content call

                    var json = JsonConvert.SerializeObject(pipeParameters);
                    string wrapperBody = $" {{\r\n  \"executionData\": {{\r\n    \"pipelineName\": \"{request.PipelineName}\",\r\n    \"parameters\": {{\r\n {json.Replace("{","").Replace("}","")} }}\r\n  }}\r\n}} "; //bit of a hack, tech debt, make a class for it
                    content = new StringContent(wrapperBody, Encoding.UTF8, "application/json");

                    _logger.LogDebug(wrapperBody.ToString());

                    postTask = pbiApiClient.PostAsync(postUrl, content);
                    postTask.Wait();
                    postResponse = postTask.Result;
                }
                
                //Parse response
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
                if (!String.IsNullOrEmpty(request.PipelineName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
                {
                    // Resolve pipeline id using shared async helper (kept synchronous for API compatibility)
                    pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                        .GetAwaiter().GetResult();

                    _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                }

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
                if (!String.IsNullOrEmpty(request.PipelineName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
                {
                    // Resolve pipeline id using the common async helper (kept synchronous for API compatibility)
                    pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                    .GetAwaiter().GetResult();

                    _logger.LogInformation("Resolved pipeline Id: " + pipelineId + " for pipeline Name: " + request.PipelineName);
                }

                // Use the reusable _generalClient helper to GET and deserialize the job instance
                var jobUrl = $"https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{pipelineId}/jobs/instances/{request.RunId}";

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
                if (!String.IsNullOrEmpty(request.PipelineName)) //Null ref handling, although already validated Nulls in PipelineRequest.cs input
                {
                    // Resolve pipeline id using shared async helper (kept synchronous for API compatibility)
                    pipelineId = ResolvePipelineIdAsync(workspaceId, request.PipelineName, CancellationToken.None)
                    .GetAwaiter().GetResult();

                    _logger.LogInformation("Resolved pipeline Id: " + pipelineId);
                }

                return new PipelineDescription()
                {
                    PipelineExists = "True",
                    PipelineName = request.PipelineName,
                    PipelineId = pipelineId,
                    PipelineType = "Unknown",
                    ActivityCount = 0 //technical debt
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
                    ActivityCount = 0 //technical debt
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
            var resp = await generalClient.GetAsync(url, ct).ConfigureAwait(false);
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
                generalClient?.Dispose();
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
