using Microsoft.AspNetCore.Http;
using Microsoft.Azure.Functions.Worker.Http;
using Newtonsoft.Json;

namespace cloudformations.cumulus.helpers
{
    public class BodyReader(HttpRequestData httpRequest)
    {
        public string Body = new StreamReader(httpRequest.Body).ReadToEndAsync().Result;

        public Task<PipelineRequest> GetRequestBody()
        {
            PipelineRequest request = JsonConvert.DeserializeObject<PipelineRequest>(Body) ?? throw new ArgumentNullException();
            return Task.FromResult(request);
        }

        public async Task<PipelineRequest> GetRequestBodyAsync()
        {
            PipelineRequest request = await GetRequestBody();
            return request;
        }

        public Task<PipelineRunRequest> GetRunRequestBody()
        {
            PipelineRunRequest request = JsonConvert.DeserializeObject<PipelineRunRequest>(Body) ?? throw new ArgumentNullException();
            return Task.FromResult(request);
        }

        public async Task<PipelineRunRequest> GetRunRequestBodyAsync()
        {
            PipelineRunRequest request = await GetRunRequestBody();
            return request;
        }
    }
}
