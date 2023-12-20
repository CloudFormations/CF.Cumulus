using Microsoft.Extensions.Logging;

namespace cloudformations.cumulus.helpers
{
    public class PipelineRequest
    {
        public string TenantId { get; set; }
        public string SubscriptionId { get; set; }
        public string ResourceGroupName { get; set; }
        public string OrchestratorName { get; set; }
        public string PipelineName { get; set; }
        public PipelineServiceType? OrchestratorType { get; set; }

        public Dictionary<string, string> PipelineParameters;

        public virtual void Validate(ILogger logger)
        {
            // ensure properties not null
            if (
                //TenantId == null || //future feature support
                SubscriptionId == null ||
                ResourceGroupName == null ||
                OrchestratorType == null ||
                OrchestratorName == null ||
                PipelineName == null
                )
            {
                ReportInvalidBody(logger);
            };

            //other validation
            //if (!CheckGuid(TenantId)) ReportInvalidBody(logger, "Expected Tenant Id to be a GUID."); //future feature support
            if (TenantId != null) ReportInvalidBody(logger, "The use of an explicit Tenant Id is not currently supported.");
            if (!CheckGuid(SubscriptionId)) ReportInvalidBody(logger, "Expected Subscription Id to be a GUID.");
        }

        private bool CheckUri(string uriValue)
        {
            bool result = Uri.TryCreate(uriValue, UriKind.Absolute, out Uri uriResult)
                && (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps);

            return result;
        }

        public bool CheckGuid(string idValue)
        {
            bool result = Guid.TryParse(idValue, out _);

            return result;
        }

        protected void ReportInvalidBody(ILogger logger)
        {
            var msg = "Invalid body.";
            logger.LogError(msg);
            throw new InvalidRequestException(msg);
        }

        protected void ReportInvalidBody(ILogger logger, string additions)
        {
            var msg = "Invalid body. " + additions;
            logger.LogError(msg);
            throw new InvalidRequestException(msg);
        }

        public Dictionary<string, object> ParametersAsObjects
        {
            get
            {
                if (PipelineParameters == null)
                    return null;
                var dictionary = new Dictionary<string, object>();
                foreach (var key in PipelineParameters.Keys)
                    dictionary.Add(key, PipelineParameters[key]);
                return dictionary;
            }
        }
    }
}