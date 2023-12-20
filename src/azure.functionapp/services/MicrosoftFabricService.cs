using Azure.ResourceManager.DataFactory;
using cloudformations.cumulus.helpers;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Media.Protection.PlayReady;

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
