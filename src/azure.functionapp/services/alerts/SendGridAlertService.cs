using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;

namespace cloudformations.cumulus.services
{
    internal class SendGridAlertService : AlertService
    {
        private PipelineAlertRequest ar;
        private ILogger logger;

        public SendGridAlertService(PipelineAlertRequest ar, ILogger logger)
        {
            this.ar = ar;
            this.logger = logger;
        }

        public override PipelineAlertDetail PipelineSendAlert(PipelineAlertRequest request)
        {
            throw new NotImplementedException();
        }
        public override void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}