using cloudformations.cumulus.services;
using Microsoft.Extensions.Logging;
using System.Collections;
using System.Collections.Generic;
using System.Text;

namespace cloudformations.cumulus.helpers
{
    public class PipelineAlertRequest
    {
        public AlertServiceType? AlertType { get; set; }
        public string? FromUsername { get; set; }
        public string? ToRecipients { get; set; }
        public string? CcRecipients { get; set; }
        public string? BccRecipients { get; set; }
        public string? Subject { get; set; }
        public string? Message { get; set; }

        public string? PassedImportance { get; set; }

        public virtual void Validate(ILogger logger)
        {
            // ensure properties not null
            if (
                AlertType == null ||
                FromUsername == null ||
                ToRecipients == null ||
                Subject == null ||
                Message == null
                )
            {
                ReportInvalidBody(logger);
            }
            ;
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
    }
}