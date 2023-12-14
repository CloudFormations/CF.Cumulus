using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using Newtonsoft.Json;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace cloudformations.cumulus.functions
{
    public class PipelineExecute
    {
        private readonly ILogger logger;

        public PipelineExecute(ILoggerFactory loggerFactory)
        {
            logger = loggerFactory.CreateLogger<PipelineExecute>();
        }

        [Function("PipelineExecute")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData)
        {
            logger.LogInformation("Pipeline Execute Function triggered by HTTP request.");

            logger.LogInformation("Parsing body from request.");
            PipelineRequest request = await new BodyReader(requestData).GetRequestBodyAsync();
            request.Validate(logger);

            using (var service = PipelineService.GetServiceForRequest(request, logger))
            {
                PipelineRunStatus result = service.PipelineExecute(request);

                var response = requestData.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                response.WriteString(JsonConvert.SerializeObject(result));

                logger.LogInformation("Pipeline Execute Function complete.");

                return response;
            }
        }
    }
}
