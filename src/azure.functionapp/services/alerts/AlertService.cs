using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;
using System;

namespace cloudformations.cumulus.services
{
    public abstract class AlertService : IDisposable
    {
        public static AlertService GetServiceForRequest(PipelineAlertRequest ar, ILogger logger)
        {
            switch (ar.AlertType)
            {
                case AlertServiceType.O365:
                    return new O365AlertService(ar, logger);

                case AlertServiceType.SGrid:
                    return new SendGridAlertService(ar, logger);

                default:
                    throw new InvalidRequestException("Unsupported orchestrator type: " + (ar.AlertType?.ToString() ?? "<null>"));
            }
        }

        public abstract PipelineAlertDetail PipelineSendAlert(PipelineAlertRequest request);

        public abstract void Dispose();
    }
}