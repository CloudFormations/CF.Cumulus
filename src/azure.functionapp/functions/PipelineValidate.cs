using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using Newtonsoft.Json;
using cloudformations.cumulus.returns;

namespace cloudformations.cumulus.functions
{
    public class PipelineValidate
    {
        private readonly ILogger logger;

        public PipelineValidate(ILoggerFactory loggerFactory)
        {
            logger = loggerFactory.CreateLogger<PipelineValidate>();
        }

        [Function("PipelineValidate")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData)
        {
            logger.LogInformation("Pipeline Validate Function triggered by HTTP request.");
            logger.LogInformation("Parsing body from request.");

            ArgumentNullException.ThrowIfNull(requestData);

            PipelineRequest request = await new BodyReader(requestData).GetRequestBodyAsync();
            request.Validate(logger);

            using (var service = PipelineService.GetServiceForRequest(request, logger))
            {
                PipelineDescription result = service.PipelineValidate(request);

                var response = requestData.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                await response.WriteStringAsync(JsonConvert.SerializeObject(result));

                logger.LogInformation("Pipeline Validate Function complete.");

                return response;
            }
        }
    }
}
