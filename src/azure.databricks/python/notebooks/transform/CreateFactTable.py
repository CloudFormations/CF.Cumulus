# Databricks notebook source
# MAGIC %run ../utils/Initialise

# COMMAND ----------

# MAGIC %run ../utils/CreateDeltaObjects

# COMMAND ----------

# MAGIC %run ../utils/HelperFunctions

# COMMAND ----------

# MAGIC %run ./utils/ConfigurePayloadVariables

# COMMAND ----------

# MAGIC %run /Workspace/Repos/matthew.collins@cloudformations.org/CF.Cumulus/src/azure.databricks/python/notebooks/ingest/checkpayload/CheckPayloadFunctions

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")

# COMMAND ----------

import json
payload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

# payload = {
#     "CuratedStorageAccessKey": "cumulusframeworkdevcuratedaccesskey",
#     "CuratedStorageName": "cumulusframeworkdev", 
#     "CuratedContainerName": "curated", 
#     "CleansedStorageAccessKey": "cumulusframeworkdevcleansedaccesskey",
#     "CleansedStorageName": "cumulusframeworkdev", 
#     "CleansedContainerName": "cleansed", 
#     "SchemaName": "Facts",
#     "DatasetName": "GoldAgg1",
#     "ColumnsList": "AddressId,FullAddress",
#     "ColumnTypeList": "INTEGER,STRING",
#     "CuratedPkList": "AddressId",
#     "CuratedPkListPartitionFields":"",
#     "SurrogateKey": "GoldAgg1Id",
#     "LoadType": "F",
#     "BusinessLogicNotebookPath": "./businesslogicnotebooks/BespokeNotebook",
# }


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

def formatColumnsSQL(columnsList: list(), typeList: list()) -> str:
    columnsString = ""
    for colName, colType in zip(columnsList, typeList): 
        columnsString += f"`{colName}` {colType}, "
        print(colName, colType)

    return columnsString[:-2]


# COMMAND ----------

partitionFieldsSQL = createPartitionFieldsSQL(partitionList)
location = setDeltaTableLocation(schemaName=curatedSchemaName, tableName=curatedDatasetName, abfssPath=curatedAbfssPath)
columnsString = formatColumnsSQL(columnsList, columnTypeList)

# COMMAND ----------

createTable(containerName=curatedContainerName, schemaName=curatedSchemaName, tableName=curatedDatasetName, location=location, partitionFieldsSQL=partitionFieldsSQL, columnsString=columnsString, surrogateKey=surrogateKey, replace=replace)


# COMMAND ----------



