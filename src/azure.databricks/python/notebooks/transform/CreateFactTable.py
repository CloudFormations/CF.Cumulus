# Databricks notebook source
# MAGIC %run ../utils/Initialise

# COMMAND ----------

# MAGIC %run ../utils/CreateDeltaObjects

# COMMAND ----------

from utils.HelperFunctions import *

# COMMAND ----------

from utils.ConfigurePayloadVariables import *

# COMMAND ----------

# MAGIC %run ../utils/CheckPayloadFunctions

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")

# COMMAND ----------

import json
payload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath = getTransformPayloadVariables(payload)

# COMMAND ----------

print("Setting cleansed ABFSS config...")
setAbfssSparkConfig(cleansedSecret, cleansedStorageName)

print("Setting curated ABFSS config...")
setAbfssSparkConfig(cleansedSecret, curatedStorageName)

# COMMAND ----------

print("Setting cleansed ABFSS path...")
cleansedAbfssPath = setAbfssPath(cleansedStorageName, cleansedContainerName)

print("Setting curated ABFSS path...")
curatedAbfssPath = setAbfssPath(curatedStorageName, curatedContainerName)

# COMMAND ----------

# Payload Validation: 
# ADVISORY: Check for unadvised column types (e.g. STRING)
# ADVISORY: Check aggregations exist
# ADVISORY: Check for partitionby fields being used if data size is expected < 1TB

# COMMAND ----------

if loadType.upper() == "F":
   # This will catch schema changes based on upsteam load action configuration?
    replace = 1
elif loadType.upper() == "I":
    replace = 0
else: 
    raise Exception("LoadType not supported.")

# COMMAND ----------

# check Delta Objects exist (import check functions)
# check schema exists
schemaExists = checkExistsDeltaSchema(schemaName=curatedSchemaName)

# create schema, if required
if schemaExists == False:
    createSchema(containerName=curatedContainerName, schemaName=curatedSchemaName)

# COMMAND ----------

partitionFieldsSQL = createPartitionFieldsSQL(partitionList)
location = setDeltaTableLocation(schemaName=curatedSchemaName, tableName=curatedDatasetName, abfssPath=curatedAbfssPath)
columnsString = formatColumnsSQL(columnsList, columnTypeList)

# COMMAND ----------

createTable(containerName=curatedContainerName, schemaName=curatedSchemaName, tableName=curatedDatasetName, location=location, partitionFieldsSQL=partitionFieldsSQL, columnsString=columnsString, surrogateKey=surrogateKey, replace=replace)


# COMMAND ----------

location


# COMMAND ----------


