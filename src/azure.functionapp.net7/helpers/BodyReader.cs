using Microsoft.Azure.Functions.Worker.Http;
using Newtonsoft.Json;

namespace cloudformations.cumulus.helpers
{
    public class BodyReader
    {
        public string Body;
        public BodyReader(HttpRequestData httpRequest)
        {
            Body = new StreamReader(httpRequest.Body).ReadToEnd();
        }

        public Task<PipelineRequest> GetRequestBody()
        {
            PipelineRequest request = JsonConvert.DeserializeObject<PipelineRequest>(Body);
            return Task.FromResult(request);
        }

        public async Task<PipelineRequest> GetRequestBodyAsync()
        {
            PipelineRequest request = await GetRequestBody();
            return request;
        }

        public Task<PipelineRunRequest> GetRunRequestBody()
        {
            PipelineRunRequest request = JsonConvert.DeserializeObject<PipelineRunRequest>(Body);
            return Task.FromResult(request);
        }

        public async Task<PipelineRunRequest> GetRunRequestBodyAsync()
        {
            PipelineRunRequest request = await GetRunRequestBody();
            return request;
        }
    }
}
