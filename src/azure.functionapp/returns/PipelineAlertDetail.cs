using System.Collections.Generic;

namespace cloudformations.cumulus.returns
{
    public class PipelineAlertDetail
    {
        public string? AlertStatus { get; set; }
        public int? StatusCode { get; set; }
        public string? ResponseBody { get; set; }
    }
}