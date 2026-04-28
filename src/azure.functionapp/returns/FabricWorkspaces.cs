using Newtonsoft.Json;

namespace cloudformations.cumulus.returns
{
    public class FabricWorkspaces
    {
        public required List<FabricWorkspaceDetails> Value { get; set; }
    }
    public class FabricWorkspaceDetails
    {
        [JsonProperty("id")]
        public required string Id { get; set; }

        [JsonProperty("displayName")]
        public required string DisplayName { get; set; }

        [JsonProperty("description")]
        public required string Description { get; set; }

        [JsonProperty("type")]
        public required string Type { get; set; }

        [JsonProperty("capacityId")]
        public required string CapacityId { get; set; }
    }
}
