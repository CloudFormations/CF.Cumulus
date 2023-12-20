using framework.testing.Helpers;
using System;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;
using System.Xml;

namespace framework.testing.Pipelines.Utilities
{
    class UtilitiesHelper : CoverageHelper<UtilitiesHelper>
    {
        public UtilitiesHelper WithBasicMetadata()
        {
            AddBasicMetadata();
            return this;
        }

        public UtilitiesHelper WithTenantAndSubscriptionIds()
        {
            AddTenantAndSubscription();
            return this;
        }

        public override void TearDown()
        {
            base.TearDown();
        }
    }
}
