using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using Newtonsoft.Json;

namespace cloudformations.cumulus.functions
{
    public class PipelineValidate
    {      
        [Function("PipelineValidate")]
        public static async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData, ILogger logger)
        {
            logger.LogInformation("Pipeline Validate Function triggered by HTTP request.");

            logger.LogInformation("Parsing body from request.");
            PipelineRequest request = await new BodyReader(requestData).GetRequestBodyAsync();
            request.Validate(logger);

            using (var service = PipelineService.GetServiceForRequest(request, logger))
            {
                PipelineDescription result = service.PipelineValidate(request);

                var response = requestData.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                response.WriteString(JsonConvert.SerializeObject(result));

                logger.LogInformation("Pipeline Validate Function complete.");

                return response;
            }
        }
    }
}
