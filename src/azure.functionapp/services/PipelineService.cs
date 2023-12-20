using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;
using System;

namespace cloudformations.cumulus.services
{
    public abstract class PipelineService : IDisposable
    {
        public const int internalWaitDuration = 5000; //ms

        public static PipelineService GetServiceForRequest(PipelineRequest pr, ILogger logger)
        {
            if (pr.OrchestratorType == PipelineServiceType.ADF)
                return new AzureDataFactoryService(pr, logger);
            
            if (pr.OrchestratorType == PipelineServiceType.SYN)
                return new AzureSynapseService(pr, logger);
            
            if (pr.OrchestratorType == PipelineServiceType.FAB)
                return new MicrosoftFabricService(pr, logger);

            throw new InvalidRequestException ("Unsupported orchestrator type: " + (pr.OrchestratorType?.ToString() ?? "<null>"));
        }

        public abstract PipelineDescription PipelineValidate(PipelineRequest request);

        public abstract PipelineRunStatus PipelineExecute(PipelineRequest request);

        public abstract PipelineRunStatus PipelineCancel(PipelineRunRequest request);

        public abstract PipelineRunStatus PipelineGetStatus(PipelineRunRequest request);

        public abstract PipelineErrorDetail PipelineGetErrorDetails(PipelineRunRequest request);

        protected void PipelineNameCheck(string requestName, string foundName)
        {
            if (requestName.ToUpper() != foundName.ToUpper())
            {
                throw new InvalidRequestException($"Pipeline name mismatch. Provided pipeline name does not match the provided Run Id. Expected name: {foundName}");
            }
        }

        public abstract void Dispose();
    }
}