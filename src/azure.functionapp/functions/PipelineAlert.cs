using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

using cloudformations.cumulus.helpers;
using cloudformations.cumulus.services;
using Newtonsoft.Json;
using cloudformations.cumulus.returns;
namespace cloudformations.cumulus.functions;

public class PipelineAlert
{
    private readonly ILogger logger;

    public PipelineAlert(ILoggerFactory loggerFactory)
    {
        logger = loggerFactory.CreateLogger<PipelineAlert>();
    }

    [Function("PipelineAlert")]
    public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData requestData)
    {
        logger.LogInformation("Pipeline Alert Function triggered by HTTP request.");
        logger.LogInformation("Parsing body from request.");

        ArgumentNullException.ThrowIfNull(requestData);

        PipelineAlertRequest request = await new BodyReader(requestData).GetAlertRequestBody();
        request.Validate(logger);

        using (var service = AlertService.GetServiceForRequest(request, logger))
        {
            PipelineAlertDetail result = service.PipelineSendAlert(request);

            var response = requestData.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
            await response.WriteStringAsync(JsonConvert.SerializeObject(result));

            logger.LogInformation("Pipeline Alert Function complete.");

            return response;
        }
    }
}