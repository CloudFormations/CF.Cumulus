using Newtonsoft.Json;

namespace cloudformations.cumulus.returns
{
    //See:
    //https://learn.microsoft.com/en-us/rest/api/fabric/core/job-scheduler/get-item-job-instance?tabs=HTTP#itemjobstatus

    public class FabricJobInstance
    {
        [JsonProperty("id")]
        public Guid Id { get; set; }

        [JsonProperty("itemId")]
        public Guid ItemId { get; set; }

        [JsonProperty("jobType")]
        public string JobType { get; set; }

        [JsonProperty("invokeType")]
        public string InvokeType { get; set; }

        [JsonProperty("status")]
        public string JobStatus { get; set; }

        [JsonProperty("failureReason")]
        public ErrorResponse? FailureReason { get; set; }

        [JsonProperty("rootActivityId")]
        public Guid RootActivityId { get; set; }

        [JsonProperty("startTimeUtc")]
        public DateTime? StartTimeUtc { get; set; }

        [JsonProperty("endTimeUtc")]
        public DateTime? EndTimeUtc { get; set; }
    }

    public class ErrorResponse
    {
        [JsonProperty("errorCode")]
        public string? ErrorCode { get; set; }        // A short error code (e.g., "BadRequest", "NotFound")

        [JsonProperty("message")]
        public string? Message { get; set; }     // A human-readable error message

        [JsonProperty("requestId")]
        public Guid RequestId { get; set; }

        [JsonProperty("moreDetails")]
        public ErrorResponseDetails? MoreDetails { get; set; }     // Optional detailed description

        [JsonProperty("relatedResource")]
        public ErrorRelatedResource? RelatedResource { get; set; }  
    }

    public class ErrorResponseDetails
    {
        [JsonProperty("errorCode")]
        public string? ErrorCode { get; set; }       

        [JsonProperty("message")]
        public string? Message { get; set; }  

        [JsonProperty("relatedResource")]
        public ErrorRelatedResource? RelatedResource { get; set; }
    }

    public class ErrorRelatedResource
    {
        [JsonProperty("resourceId")]
        public string? ResourceId { get; set; }

        [JsonProperty("resourceType")]
        public string? ResourceType { get; set; }
    }

}
