using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace cloudformations.cumulus.returns
{
    public class TokenDetail
    {

        [JsonProperty("token_type")]
        public required string TokenType { get; set; }

        [JsonProperty("expires_in")]
        public required int ExpiresIn { get; set; }

        [JsonProperty("ext_expires_in")]
        public required int ExtExpiresIn { get; set; }

        [JsonProperty("expires_on")]
        public required long ExpiresOn { get; set; }

        [JsonProperty("not_before")]
        public required long NotBefore { get; set; }

        [JsonProperty("resource")]
        public required string Resource { get; set; }

        [JsonProperty("access_token")]
        public required string AccessToken { get; set; }

    }
}
