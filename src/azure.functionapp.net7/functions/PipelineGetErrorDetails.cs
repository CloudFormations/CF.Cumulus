using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using Newtonsoft.Json;

namespace cloudformations.cumulus.functions
{
    public class PipelineGetErrorDetails
    {
        private readonly ILogger logger;

        public PipelineGetErrorDetails(ILoggerFactory loggerFactory)
        {
            logger = loggerFactory.CreateLogger<PipelineGetErrorDetails>();
        }

        [Function("PipelineGetErrorDetails")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData)
        {
            logger.LogInformation("Pipeline Get Error Details Function triggered by HTTP request.");

            logger.LogInformation("Parsing body from request.");
            PipelineRunRequest request = await new BodyReader(requestData).GetRunRequestBodyAsync();
            request.Validate(logger);

            using (var service = PipelineService.GetServiceForRequest(request, logger))
            {
                PipelineErrorDetail result = service.PipelineGetErrorDetails(request);

                var response = requestData.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                response.WriteString(JsonConvert.SerializeObject(result));

                logger.LogInformation("Pipeline Get Error Details Function complete.");

                return response;
            }
        }
    }
}
