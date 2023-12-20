using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;

namespace cloudformations.cumulus.services
{
    public class MicrosoftFabricService : PipelineService
    {

        private readonly ILogger _logger;

        public MicrosoftFabricService(PipelineRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating FAB connectivity clients.");
        }

        public override PipelineRunStatus PipelineCancel(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineExecute(PipelineRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineErrorDetail PipelineGetErrorDetails(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineRunStatus PipelineGetStatus(PipelineRunRequest request)
        {
            throw new NotImplementedException();
        }

        public override PipelineDescription PipelineValidate(PipelineRequest request)
        {
            throw new NotImplementedException();
        }
        public override void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
