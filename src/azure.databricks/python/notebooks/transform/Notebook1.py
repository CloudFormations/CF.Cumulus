# Databricks notebook source
# MAGIC %run /Workspace/Repos/matthew.collins@cloudformations.org/CF.Cumulus/src/azure.databricks/python/notebooks/ingest/utils/Initialise

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")

# COMMAND ----------

import json
notebookPayload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

cleansedSecret = 'cumulusframeworkdevcleansedaccesskey'
cleansedStorageName = 'cumulusframeworkdev'
cleansedContainerName = 'cleansed'

print("Setting cleansed ABFSS config...")
setAbfssSparkConfig(cleansedSecret, cleansedStorageName)

# COMMAND ----------

print("Setting cleansed ABFSS path...")
cleansedAbfssPath = setAbfssPath(cleansedStorageName, cleansedContainerName)

# COMMAND ----------



cleansedDatasets = notebookPayload['CleansedDatasets']
curatedDataset = notebookPayload['CuratedDataset']
curatedSchema = notebookPayload['CuratedSchema']


createSQL = notebookPayload['CreateSQL']
updateSQL = notebookPayload['UpdateSQL']
deleteSQL = notebookPayload['DeleteSQL']

# COMMAND ----------

def createSchemaSQL(schema: str) -> str:
    return f"CREATE SCHEMA IF NOT EXISTS {schema}"

# COMMAND ----------

# MAGIC %sql
# MAGIC with cte as (
# MAGIC   select 
# MAGIC     addressid,    addressline1,    addressline2,    city,    stateprovince,    countryregion,    postalcode,    rowguid
# MAGIC   FROM adventureworkssqlserver.salesdemo_address
# MAGIC ),
# MAGIC cte2 as (
# MAGIC   select 
# MAGIC     rowguid,    modifieddate
# MAGIC   FROM adventureworkssqlserver.salesdemo_address
# MAGIC )
# MAGIC select 
# MAGIC   cte.*,  cte2.*
# MAGIC from cte
# MAGIC inner join cte2
# MAGIC on cte.rowguid = cte2.rowguid

# COMMAND ----------

cleansedDatasets = ["adventureworkssqlserver.salesdemo_address","metadatadatabase.control_pipelines"]
curatedDataset = "dimensions.joinedtable"
curatedSchema = "dimensions"
createCuratedSchemaSQL = "CREATE SCHEMA IF NOT EXISTS dimensions"
createCuratedDatasetSQL = " CREATE TABLE dimensions.joinedtable LOCATION '[location]' [partitionFieldsSQL] AS SELECT * FROM [selectSQL] "

selectSQL = """
with cte as (
  select 
    addressid,    addressline1,    addressline2,    city,    stateprovince,    countryregion,    postalcode,    rowguid
  FROM adventureworkssqlserver.salesdemo_address
),
cte2 as (
  select 
    rowguid,    modifieddate
  FROM adventureworkssqlserver.salesdemo_address
)
select 
  cte.*,  cte2.modifieddate
from cte
inner join cte2
on cte.rowguid = cte2.rowguid
"""

updateSQL = notebookPayload["UpdateSQL"]
deleteSQL = notebookPayload["DeleteSQL"]

# COMMAND ----------

createCuratedDatasetSQL = " CREATE TABLE dimensions.joinedtable LOCATION '[location]' [partitionFieldsSQL] AS SELECT * FROM ([selectSQL]) "
createCuratedDatasetSQL = createCuratedDatasetSQL.replace('[location]', 'abfss://cleansed@cumulusframeworkdev.dfs.core.windows.net//dimensions/joinedtable')
createCuratedDatasetSQL = createCuratedDatasetSQL.replace('[partitionFieldsSQL]', '')
createCuratedDatasetSQL = createCuratedDatasetSQL.replace('[selectSQL]', selectSQL)
createCuratedDatasetSQL = createCuratedDatasetSQL.replace('\n', ' ')
spark.sql(createCuratedDatasetSQL)

# COMMAND ----------

# MAGIC %sql
# MAGIC select *
# MAGIC from dimensions.joinedtable
# MAGIC

# COMMAND ----------

createCuratedSchemaSQL = createSchemaSQL(curatedSchema)
spark.sql(createCuratedSchemaSQL)

# COMMAND ----------

payloadSelectTable = "SELECT * FROM adventureworkssqlserver.salesdemo_address"

# COMMAND ----------

df = spark.sql(payloadSelectTable)
display(df)

# COMMAND ----------

# MAGIC %sql
# MAGIC SHOW TABLES IN metadatadatabase.control_pipelines

# COMMAND ----------


