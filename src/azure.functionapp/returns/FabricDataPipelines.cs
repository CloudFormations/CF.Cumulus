using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace cloudformations.cumulus.returns
{
    public class FabricDataPipelines
    {
        [JsonProperty("value")]
        public required List<FabricDataPipelineDetails> Value { get; set; }
    }

    public class FabricDataPipelineDetails
    {
        [JsonProperty("id")]
        public required string Id { get; set; }

        [JsonProperty("type")]
        public required string Type { get; set; }

        [JsonProperty("displayName")]
        public required string DisplayName { get; set; }

        [JsonProperty("description")]
        public required string Description { get; set; }

        [JsonProperty("workspaceId")]
        public required string WorkspaceId { get; set; }

        [JsonProperty("folderId")]
        public required string FolderId { get; set; }
    }
}
