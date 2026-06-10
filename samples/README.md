# CF.Cumulus — Samples

This directory contains sample deployments that demonstrate CF.Cumulus functionality. Each sample is self-contained and can be deployed independently on top of an existing CF.Cumulus installation.

> **Pre-requisite:** A working CF.Cumulus core deployment is required before running any sample. Follow the [Getting Started guide](../README.md) first.

---

## Available Samples

### [AdventureWorks](adventureworks/README.md)
An end-to-end ingest and transform demonstration using **AdventureWorks** as a source database. Provisions a sample Azure SQL Server and database via Bicep, then seeds the metadata database with three incremental ingest pipelines and three Databricks transform pipelines to produce a curated dimensional model (products, dates, sales).

### [Control Waits](controlwaits/README.md)
A control framework demonstration using lightweight **wait pipelines** as stand-in workloads. Seeds the metadata database with a four-stage batch of eleven pipelines with explicit cross-stage dependencies, showing how CF.Cumulus manages parallelism, sequencing, and error handling without requiring any source databases or storage.
