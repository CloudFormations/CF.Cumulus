using System.Net;
using Newtonsoft.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using cloudformations.cumulus.returns;

namespace cloudformations.cumulus.functions
{
    public class PipelineCancel
    {
        private readonly ILogger logger;

        public PipelineCancel(ILoggerFactory loggerFactory)
        {
            logger = loggerFactory.CreateLogger<PipelineCancel>();
        }

        [Function("PipelineCancel")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData)
        {
            logger.LogInformation("Pipeline Cancel Function triggered by HTTP request.");
            logger.LogInformation("Parsing body from request.");

            ArgumentNullException.ThrowIfNull(requestData);

            PipelineRunRequest request = await new BodyReader(requestData).GetRunRequestBodyAsync();
            request.Validate(logger);

            using (var service = PipelineService.GetServiceForRequest(request, logger))
            {
                PipelineRunStatus result = service.PipelineCancel(request);

                var response = requestData.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                await response.WriteStringAsync(JsonConvert.SerializeObject(result));

                logger.LogInformation("Pipeline Cancel Function complete.");

                return response;
            }
        }
    }
}
