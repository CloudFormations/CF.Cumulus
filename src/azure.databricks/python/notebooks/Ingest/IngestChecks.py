# Databricks notebook source
# MAGIC %md
# MAGIC #Merge Check Functionality
# MAGIC - Check payload validity
# MAGIC - Confirm storage is accessible
# MAGIC - Create Delta Table, if required
# MAGIC - Defensive check Rundate vs Last load date
# MAGIC
# MAGIC #TODO items:
# MAGIC - Unit tests
# MAGIC - Fully populate raw with all datasets created so far for testing
# MAGIC

# COMMAND ----------

# MAGIC %run ../Functions/Initialise

# COMMAND ----------

# MAGIC %run ../Functions/CheckFunctions

# COMMAND ----------

dbutils.widgets.text("Merge Payload","")
dbutils.widgets.text("Pipeline Run Id","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

import json

payload = json.loads(dbutils.widgets.get("Merge Payload"))


# COMMAND ----------


# create variables for each payload item
tableName = payload["DatasetDisplayName"] 
loadType = payload["LoadAction"]
loadTypeText = "full" if loadType == "F" else "incremental"
versionNumber = f"{int(payload['VersionNumber']):04d}"

rawStorageName = payload["RawStorageName"]
rawContainerName = payload["RawContainerName"]
rawSecret = f'{payload["RawStorageName"]}accesskey'
rawLastLoadDate = payload["RawLastLoadDate"]

rawSchemaName = payload["RawSchemaName"]
rawFileType = payload["RawFileType"]
dateTimeFolderHierarchy = payload["DateTimeFolderHierarchy"]

cleansedStorageName = payload["CleansedStorageName"]
cleansedContainerName = payload["CleansedContainerName"]
cleansedSecret = f'{payload["CleansedStorageName"]}accesskey'
cleansedLastLoadDate = payload["CleansedLastLoadDate"]

cleansedSchemaName = payload["CleansedSchemaName"] 

# Semantic checks for these required in the IngestChecks notebook?
pkList =  payload["CleansedPkList"].split(",")
partitionList =  payload["CleansedPartitionFields"].split(",") if  payload["CleansedPartitionFields"] != "" else []

columnsList = payload["CleansedColumnsList"].split(",")
columnsTypeList = payload["CleansedColumnsTypeList"].split(",")
columnsFormatList = payload["CleansedColumnsFormatList"].split(",")
metadataColumnList = ["PipelineRunId","PipelineExecutionDateTime"]
metadataColumnTypeList = ["STRING","TIMESTAMP"]
metadataColumnFormatList = ["","yyyy-MM-dd HH:mm:ss"]

# metadataColumnList = payload["cleansedMetadataColumnList"].split(",")
# metadataColumnTypeList = payload["cleansedMetadataColumnTypeList"].split(",")
# metadataColumnFormatList = payload["cleansedMetadataColumnFormatList"].split(",")

totalColumnList = columnsList + metadataColumnList
totalColumnTypeList = columnsTypeList + metadataColumnTypeList
totalColumnFormatList = columnsFormatList + metadataColumnFormatList

# totalColumnList = columnsList
# totalColumnTypeList = columnsTypeList
# totalColumnFormatList = columnsFormatList


# COMMAND ----------

# MAGIC %md
# MAGIC # Initialisation

# COMMAND ----------

print("Setting raw ABFSS config...")
setAbfssSparkConfig(rawSecret, rawStorageName)

print("Setting cleansed ABFSS config...")
setAbfssSparkConfig(cleansedSecret, cleansedStorageName)

# COMMAND ----------

print("Setting raw ABFSS path...")
rawAbfssPath = setAbfssPath(rawStorageName, rawContainerName)

print("Setting cleansed ABFSS path...")
cleansedAbfssPath = setAbfssPath(cleansedStorageName, cleansedContainerName)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Payload Validity

# COMMAND ----------

# Check data types and nullability of each dictionary element
loadTypeCheck(loadType = loadType)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Storage accessibility

# COMMAND ----------

# Check Raw storage account exists and is accessible.
abfssCheck(abfssPath=rawAbfssPath)

# Check cleansed storage account exists and is accessible.
abfssCheck(abfssPath=cleansedAbfssPath)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Table created

# COMMAND ----------

cleansedTablePath = setTablePath(schemaName =cleansedSchemaName, tableName =tableName)
print(cleansedTablePath)

# COMMAND ----------

deltaTableExistsCheck(tablePath = cleansedTablePath, loadType = loadType)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: RunDate vs Last load Date

# COMMAND ----------

compareRawLoadVsLastCleansedDate(rawLastLoadDate = rawLastLoadDate, cleansedLastLoadDate = cleansedLastLoadDate)
