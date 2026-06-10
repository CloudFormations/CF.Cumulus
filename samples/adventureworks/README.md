# CF.Cumulus — Demo Sample

This sample provides an end-to-end demonstration of CF.Cumulus using **AdventureWorks** as a source database. It deploys a pre-configured set of ingest and transform pipelines that read from the AdventureWorks `SalesLT` schema, land data on your Data Lake, and produce curated dimensional model outputs.

> **Pre-requisite:** A working CF.Cumulus core deployment is required before running this sample. Follow the [Getting Started guide](../../README.md) first.

---

## What's Included

### Infrastructure
A supplementary Bicep template (`infrastructure/main.bicep`) that provisions a sample SQL Server and AdventureWorks database alongside your existing CF.Cumulus resources.

### Metadata Configuration (DACPAC)
The `src/metadata.samples` project seeds the CF.Cumulus metadata database with ready-to-run pipeline configuration via the framework's stored procedure API. No manual SQL required.

### Ingest Pipelines
Three datasets configured to ingest from the AdventureWorks `SalesLT` schema into your Data Lake (Raw → Cleansed):

| Dataset | Source Table | Load Type |
|---|---|---|
| SalesOrderHeader | `SalesLT.SalesOrderHeader` | Incremental |
| SalesOrderDetail | `SalesLT.SalesOrderDetail` | Incremental |
| Product | `SalesLT.Product` | Incremental |

### Transform Pipelines
Three Databricks notebooks configured to produce a curated dimensional model (Cleansed → Curated):

| Output | Notebook | Type |
|---|---|---|
| `Dim.Products` | `DimProducts` | Full load |
| `Dim.Date` | `DimDate` | Full load |
| `Fact.Sales` | `FactSales` | Full load |

---

## Deployment

### Step 1 — Configure parameters

Open `infrastructure/configuration/_installation/main.bicepparam` and set your values:

```bicep
param orgName         = 'cf'       // Abbreviation of your organisation
param domainName      = 'demo'     // Domain label for this deployment
param envName         = 'dev'      // Environment name
param location        = 'uksouth'  // Azure region
param uniqueIdentifier = '01'      // Suffix to ensure unique resource names
param myIPAddress     = '1.1.1.1'  // Your public IP for SQL Server firewall access
```

### Step 2 — Run the wrapper script

Execute the deployment wrapper from a PowerShell terminal at the repository root:

```powershell
. 'samples/demo/infrastructure/deployment/_wrapper_sample.ps1' `
    -tenantId       '<your-tenant-id>' `
    -subscriptionName '<your-subscription-name>' `
    -location       'uksouth'
```

The wrapper will:
1. Authenticate with Azure CLI
2. Deploy the Bicep template (sample SQL Server + AdventureWorks database)
3. Build and publish the `metadata.samples` DACPAC to seed pipeline configuration

### Step 3 — Run the pipelines

Once deployed, trigger the CF.Cumulus orchestration pipeline from Azure Data Factory. The framework will execute the configured ingest and transform stages automatically.

---

## Sample output workload

::: mermaid
graph
subgraph Daily
style Daily fill:#DEEBF7,stroke:#DEEBF7
subgraph cfmaydevadfuks16
style cfmaydevadfuks16 fill:#F5F5F5,stroke:#F5F5F5
subgraph Cleansed
style Cleansed fill:#E0E0E0,stroke:#E0E0E0
p20(Ingest_PL_Merge - SalesOrderDetail)
style p20 fill:#ECECFF,stroke:#ECECFF
p40(Ingest_PL_Merge - SalesOrderHeader)
style p40 fill:#ECECFF,stroke:#ECECFF
p60(Ingest_PL_Merge - Product)
style p60 fill:#ECECFF,stroke:#ECECFF
end
subgraph Dimension
style Dimension fill:#E0E0E0,stroke:#E0E0E0
p70(Transform_PL_Managed - Date)
style p70 fill:#ECECFF,stroke:#ECECFF
p80(Transform_PL_Managed - Products)
style p80 fill:#ECECFF,stroke:#ECECFF
end
subgraph Fact
style Fact fill:#E0E0E0,stroke:#E0E0E0
p90(Transform_PL_Managed - Sales)
style p90 fill:#ECECFF,stroke:#ECECFF
end
subgraph Raw
style Raw fill:#E0E0E0,stroke:#E0E0E0
p10(Ingest_PL_MSSQL - SalesOrderDetail)
style p10 fill:#ECECFF,stroke:#ECECFF
p30(Ingest_PL_MSSQL - SalesOrderHeader)
style p30 fill:#ECECFF,stroke:#ECECFF
p50(Ingest_PL_MSSQL - Product)
style p50 fill:#ECECFF,stroke:#ECECFF
end
end
s100[Raw]
style s100 fill:#ECECFF,stroke:#ECECFF
s200[Cleansed]
style s200 fill:#ECECFF,stroke:#ECECFF
s300[Dimension]
style s300 fill:#ECECFF,stroke:#ECECFF
s400[Fact]
style s400 fill:#ECECFF,stroke:#ECECFF
s100 --> Raw
s200 --> Cleansed
s300 --> Dimension
s400 --> Fact
s100 ==> s200
s200 ==> s300
s300 ==> s400
p10 -.-> p20
p30 -.-> p40
p50 -.-> p60
p60 -.-> p80
p70 -.-> p90
p80 -.-> p90
end
:::


## Repository Structure

```
samples/demo/
├── infrastructure/
│   ├── configuration/_installation/
│   │   └── main.bicepparam          # Your deployment parameters
│   ├── deployment/
│   │   ├── _wrapper_sample.ps1      # End-to-end deployment entry point
│   │   └── deploy_sample_sql_dacpacs.ps1
│   └── main.bicep                   # Sample infrastructure template
└── src/
    ├── azure.databricks/           # Databricks notebooks for the transformed business logic outputs
    │   └── python/notebooks/transform/businesslogicnotebooks/
    │       ├── DimDate.py
    │       ├── DimProducts.py
    │       └── FactSales.py
    └── metadata.samples/            # DACPAC — seeds metadata configuration
        └── Scripts/
            ├── Core/                # AdventureWorks linked service seed
            └── Data/
                ├── Ingest/          # Ingest dataset + attribute definitions
                └── Transform/       # Transform dataset + attribute definitions
```
