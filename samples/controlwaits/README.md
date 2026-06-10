# CF.Cumulus — Control Waits Sample

This sample demonstrates CF.Cumulus's orchestration and control framework using lightweight **wait pipelines** as stand-in workloads. It deploys a pre-configured set of pipelines across four stages with explicit cross-stage dependencies, making it easy to observe how the framework manages parallelism, sequencing, and error handling without requiring any source databases or storage.

> **Pre-requisite:** A working CF.Cumulus core deployment is required before running this sample. Follow the [Getting Started guide](../../README.md) first.

---

## What's Included

### Metadata Configuration (DACPAC)
The `src/metadata.samples` project seeds the CF.Cumulus metadata database with a ready-to-run batch and pipeline configuration via the framework's stored procedure API. No manual SQL required.

### Batch & Stages
One batch (`Control`) with four sequential stages:

| Stage | Pipelines | Notes |
|---|---|---|
| Stage 1 | Wait1, Wait2, Wait3, IntentionalError | Runs in parallel; includes an error pipeline for testing |
| Stage 2 | Wait4, Wait5, Wait6 | Dependencies on stage 1 |
| Stage 3 | Wait7, Wait8 | Dependencies on stage 2 |
| Stage 4 | Wait9, Wait10, Wait10 | Dependencies on stage 3. Includes a "duplicate" pipeline |

Each wait pipeline accepts a `WaitTime` parameter (in seconds) that controls how long the ADF Wait activity runs, simulating variable workload durations.

---

## Deployment

### Step 1 — Run the wrapper script

Execute the deployment wrapper from a PowerShell terminal at the repository root:

```powershell
. 'samples/controlwaits/infrastructure/deployment/_wrapper_sample.ps1' `
    -tenantId         '<your-tenant-id>' `
    -subscriptionName '<your-subscription-name>' `
    -keyVaultName '<key-vault-name>' `
    -sqlServerName '<sql-server-name>' `
    -sqlDatabaseName '<sql-database-name>' `
    -dataFactoryName '<data-factory-name>'
```

The wrapper will:
1. Authenticate with Azure CLI
2. Retrieve SQL credentials from Azure Key Vault
3. Build and publish the `metadata.samples` DACPAC to seed batch and pipeline configuration

### Step 2 — Run the pipelines

Once deployed, trigger the CF.Cumulus orchestration pipeline from Azure Data Factory. The framework will execute the configured stages automatically, respecting all cross-stage dependencies.

---

## Sample output workload

::: mermaid
graph
subgraph Control
style Control fill:#DEEBF7,stroke:#DEEBF7
subgraph cfmaydevadfuks28
style cfmaydevadfuks28 fill:#F5F5F5,stroke:#F5F5F5
subgraph Stage1
style Stage1 fill:#E0E0E0,stroke:#E0E0E0
p40(Intentional Error - RaiseErrors: true)
style p40 fill:#ECECFF,stroke:#ECECFF
p50(Wait 1 - WaitTime: 3)
style p50 fill:#ECECFF,stroke:#ECECFF
p60(Wait 2 - WaitTime: 6)
style p60 fill:#ECECFF,stroke:#ECECFF
p70(Wait 3 - WaitTime: 5)
style p70 fill:#ECECFF,stroke:#ECECFF
end
subgraph Stage2
style Stage2 fill:#E0E0E0,stroke:#E0E0E0
p80(Wait 4 - WaitTime: 1)
style p80 fill:#ECECFF,stroke:#ECECFF
p90(Wait 5 - WaitTime: 3)
style p90 fill:#ECECFF,stroke:#ECECFF
p100(Wait 6 - WaitTime: 2)
style p100 fill:#ECECFF,stroke:#ECECFF
end
subgraph Stage3
style Stage3 fill:#E0E0E0,stroke:#E0E0E0
p110(Wait 7 - WaitTime: 6)
style p110 fill:#ECECFF,stroke:#ECECFF
p120(Wait 8 - WaitTime: 10)
style p120 fill:#ECECFF,stroke:#ECECFF
end
subgraph Stage4
style Stage4 fill:#E0E0E0,stroke:#E0E0E0
p130(Wait 10 - WaitTime: 2)
style p130 fill:#ECECFF,stroke:#ECECFF
p140(Wait 9 - WaitTime: 1)
style p140 fill:#ECECFF,stroke:#ECECFF
end
end
s900[Stage1]
style s900 fill:#ECECFF,stroke:#ECECFF
s1000[Stage2]
style s1000 fill:#ECECFF,stroke:#ECECFF
s1100[Stage3]
style s1100 fill:#ECECFF,stroke:#ECECFF
s1200[Stage4]
style s1200 fill:#ECECFF,stroke:#ECECFF
s1000 --> Stage2
s1100 --> Stage3
s1200 --> Stage4
s900 --> Stage1
s1000 ==> s1100
s1100 ==> s1200
s900 ==> s1000
p100 -.-> p120
p110 -.-> p130
p110 -.-> p140
p120 -.-> p130
p40 -.-> p100
p50 -.-> p80
p60 -.-> p90
p70 -.-> p100
p80 -.-> p110
p80 -.-> p120
p90 -.-> p110
end
:::

---

## Repository Structure

```
samples/controlwaits/
├── infrastructure/
│   └── deployment/
│       ├── _wrapper_sample.ps1              # End-to-end deployment entry point
│       └── deploy_sample_sql_dacpacs.ps1    # Builds and publishes the DACPAC
└── src/
    └── metadata.samples/                    # DACPAC — seeds metadata configuration
        ├── samples/Stored Procedures/
        │   ├── AddWaitPipeline.sql          # Upserts a wait pipeline with its WaitTime parameter
        │   └── AddPipelineDependency.sql    # Registers a cross-stage pipeline dependency
        └── Scripts/
            ├── BatchControl.sql             # Defines the batch and four stages
            ├── Script.PostDeployment.sql    # Entry point — includes all stage scripts
            ├── Stage1/                      # Wait1, Wait2, Wait3, IntentionalError
            ├── Stage2/                      # Wait4, Wait5, Wait6
            ├── Stage3/                      # Wait7, Wait5, Wait8
            └── Stage4/                      # Wait9, Wait10, Wait10_2
```
