using Azure.Identity;
using cloudformations.cumulus.helpers;
using cloudformations.cumulus.returns;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Newtonsoft.Json;
using System.Text.RegularExpressions;


namespace cloudformations.cumulus.services
{
    public class O365AlertService : AlertService
    {
        private readonly ILogger _logger;
        private GraphServiceClient graphClient;

        public O365AlertService(PipelineAlertRequest request, ILogger logger)
        {
            _logger = logger;
            _logger.LogInformation("Creating Microsoft Graph Client.");

            graphClient = new GraphServiceClient(new DefaultAzureCredential());
        }

        public override PipelineAlertDetail PipelineSendAlert(PipelineAlertRequest request)
        {
            //Create basic message content
            var message = new Message
            {
                Subject = request.Subject,
                Body = new ItemBody
                {
                    ContentType = BodyType.Html,
                    Content = request.Message
                }
            };

            //Add To
            if (string.IsNullOrEmpty(request.ToRecipients))
            {
                _logger.LogError("ToRecipients is required for O365AlertService.");
                throw new ArgumentException("ToRecipients is required for O365AlertService.");
            }
            message.ToRecipients = BuildRecipients(request.ToRecipients);

            //Add Cc if provided
            if (!string.IsNullOrEmpty(request.CcRecipients))
            {
                message.CcRecipients = BuildRecipients(request.CcRecipients);
            }

            //Add Bcc if provided
            if (!string.IsNullOrEmpty(request.BccRecipients))
            {
                message.BccRecipients = BuildRecipients(request.BccRecipients);
            }

            //Set importance if provided
            if (!string.IsNullOrEmpty(request.PassedImportance))
            {
                message.Importance = request.PassedImportance.ToUpper() switch
                {
                    "LOW" => Importance.Low,
                    "HIGH" => Importance.High,
                    _ => Importance.Normal
                };
            }

            //Send request
            try
            {
                graphClient.Users[request.FromUsername]
                    .SendMail
                    .PostAsync(new Microsoft.Graph.Users.Item.SendMail.SendMailPostRequestBody
                    {
                        Message = message,
                        SaveToSentItems = true
                    })
                    .GetAwaiter()
                    .GetResult();

                return new PipelineAlertDetail
                {
                    AlertStatus = "Sent"
                };
            }
            catch (ServiceException ex)
            {
                // Graph SDK failed — include status and server-provided message when available
                return new PipelineAlertDetail
                {
                    AlertStatus = "Failed",
                    StatusCode = ex.ResponseStatusCode,
                    ResponseBody = ex.Message
                };
            }
            catch (Exception ex)
            {
                // Unexpected failure
                return new PipelineAlertDetail
                {
                    AlertStatus = "Failed",
                    ResponseBody = ex.Message
                };
            }
        }

        private static List<Recipient> BuildRecipients(string RecipientsString)
        {
            var addresses = (RecipientsString ?? string.Empty)
                .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(r => r.Trim())
                .Where(r => !string.IsNullOrEmpty(r))
                .ToList();

            return addresses
                .Select(address => new Recipient
                {
                    EmailAddress = new EmailAddress { Address = address }
                })
                .ToList();
        }
        public override void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}