using Azure.Identity;
using cloudformations.cumulus.returns;
using Microsoft.AspNetCore.DataProtection;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace cloudformations.cumulus.helpers
{
    internal class FabricClient
    {
        private bool localMode;
        private string token = String.Empty;

        public FabricClient(bool localAuthMode) 
        {
            localMode = localAuthMode;
        }

        public HttpClient CreatePowerBIAPIClient()
        {
            if (localMode) // Type of a credential we want to use
            {
                string? tenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID");
                string? clientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
                string? clientSecret = Environment.GetEnvironmentVariable("AZURE_CLIENT_SECRET");

                var credential = new ClientSecretCredential(tenantId, clientId, clientSecret);
                token = credential.GetToken(new Azure.Core.TokenRequestContext(new[] { "https://analysis.windows.net/powerbi/api/.default" })).Token.ToString();
            }
            else
            { // Authenticate first: az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions or use an Azure credential
                var credential = new ChainedTokenCredential(new AzureCliCredential(), new DefaultAzureCredential());
                token = credential.GetToken(new Azure.Core.TokenRequestContext(new[] { "https://analysis.windows.net/powerbi/api/.default" })).Token.ToString();
            }

            HttpClient client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return client;
        }

        public async Task<HttpClient> CreateFabricAPIClient()
        {
            string? tenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID");
            string? clientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
            string? clientSecret = Environment.GetEnvironmentVariable("AZURE_CLIENT_SECRET");

            string tokenUrl = ($"https://login.microsoftonline.com/{tenantId}/oauth2/token");
            string resourceUrl = "https://api.fabric.microsoft.com";


            token = await GetBearerToken(clientId, clientSecret, tokenUrl, resourceUrl);

            HttpClient client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return client;
        }

        static async Task<string> GetBearerToken(string clientId, string clientSecret, string tokenEndpoint, string resourceUrl)
        {
            using (var tokenClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Post, tokenEndpoint);
                var keyValues = new[]
                {
                 new KeyValuePair<string, string>("grant_type", "client_credentials"),
                 new KeyValuePair<string, string>("client_id", clientId),
                 new KeyValuePair<string, string>("client_secret", clientSecret),
                 new KeyValuePair<string, string>("resource", resourceUrl)
                };

                request.Content = new FormUrlEncodedContent(keyValues);

                var response = await tokenClient.SendAsync(request);
                response.EnsureSuccessStatusCode();

                var responseContent = await response.Content.ReadAsStringAsync();
                var token = JObject.Parse(responseContent)["access_token"].ToString();

                return token;
            }
        }

        public string GetBearerToken()
        {
            string? tenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID");
            string? clientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
            string? clientSecret = Environment.GetEnvironmentVariable("AZURE_CLIENT_SECRET");

            string tokenUrl = ($"https://login.microsoftonline.com/{tenantId}/oauth2/token");
            string resourceUrl = "https://api.fabric.microsoft.com";

            using (var tokenClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Post, tokenUrl);
                var keyValues = new[]
                {
                    new KeyValuePair<string, string>("grant_type", "client_credentials"),
                    new KeyValuePair<string, string>("client_id", clientId),
                    new KeyValuePair<string, string>("client_secret", clientSecret),
                    new KeyValuePair<string, string>("resource", resourceUrl)
                };

                request.Content = new FormUrlEncodedContent(keyValues);

                var response = tokenClient.SendAsync(request);

                TokenDetail tokenResponse = JsonConvert.DeserializeObject<TokenDetail>(response.Result.Content.ReadAsStringAsync().Result);

                return tokenResponse.AccessToken;
            }
        }
    }
}
