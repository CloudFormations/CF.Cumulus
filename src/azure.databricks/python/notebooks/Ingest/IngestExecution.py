# Databricks notebook source
# MAGIC %md
# MAGIC #Merge Functionality
# MAGIC - Process metadata schemas raw vs cleansed with data typing
# MAGIC - Allow for Rejected data handling
# MAGIC - Create SELECT script for the merge operation
# MAGIC - Functionality for 'F' and 'I' loads:
# MAGIC   - 'F': recreate cleansed table upon execution
# MAGIC   - 'I': merge data on top of existing table
# MAGIC
# MAGIC #TODO items:
# MAGIC - Unit tests
# MAGIC - Specify schema flexibility option in merge command
# MAGIC

# COMMAND ----------

# MAGIC %run ../Functions/Initialise

# COMMAND ----------

# MAGIC %run ../Functions/IngestCreateMergeQuery

# COMMAND ----------

# MAGIC %run ../Functions/WriteDeltaTableHelper

# COMMAND ----------

dbutils.widgets.text("Merge Payload","")
dbutils.widgets.text("Pipeline Run Id","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

import json
import datetime
from pyspark.sql.functions import *

# COMMAND ----------

payload = json.loads(dbutils.widgets.get("Merge Payload"))
pipelineRunId = dbutils.widgets.get("Pipeline Run Id")

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
# metadataColumnList = ["PipelineRunId","PipelineExecutionDateTime"]
# metadataColumnTypeList = ["STRING","TIMESTAMP"]
# metadataColumnFormatList = ["","yyyy-MM-ddTHH:mm:ss.SSSSSSSZ"]

PipelineExecutionDateTime = datetime.datetime.now(datetime.timezone.utc)

# metadataColumnList = payload["cleansedMetadataColumnList"].split(",")
# metadataColumnTypeList = payload["cleansedMetadataColumnTypeList"].split(",")
# metadataColumnFormatList = payload["cleansedMetadataColumnFormatList"].split(",")

# totalColumnList = columnsList + metadataColumnList
# totalColumnTypeList = columnsTypeList + metadataColumnTypeList
# totalColumnFormatList = columnsFormatList + metadataColumnFormatList

totalColumnList = columnsList
totalColumnTypeList = columnsTypeList
totalColumnFormatList = columnsFormatList


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
# MAGIC #Get dataset from raw

# COMMAND ----------

# Spark read options. Can be customised if needed, but this is standard.
# options = {'header':'True'}

# Extended option, we need to confirm the mergeSchema failure behaviour. When switching versions of dataset, will want this enabled.
options = {
    'header':'True',
    "mergeSchema": "true"
    }


#different options for specifying, based on how we save abfss folder hierarchy.
fileFullPath = f"{rawAbfssPath}/{rawSchemaName}/{tableName}/version={versionNumber}/{loadTypeText}/{dateTimeFolderHierarchy}/{tableName}.{rawFileType}"
print(fileFullPath)

# assuming json,csv, parquet
df = spark.read \
    .options(**options) \
    .format(rawFileType) \
    .load(fileFullPath)

display(df)

# COMMAND ----------

# Create temporary table for SELECT statements
pipelineRunIdViewExtension = pipelineRunId.replace('-', '_')
tempViewName = f"{tableName}_{pipelineRunIdViewExtension}"
df.createOrReplaceTempView(tempViewName)

# COMMAND ----------

totalColumnStr = selectSqlColumnsFormatString(totalColumnList, totalColumnTypeList, totalColumnFormatList)

selectSQLFullString = f"SELECT {totalColumnStr} FROM {tempViewName}"
print(selectSQLFullString)

# COMMAND ----------

df = spark.sql(selectSQLFullString)
df = df.withColumn('PipelineExecutionDateTime', to_timestamp(lit(PipelineExecutionDateTime)))
df = df.withColumn('PipelineRunId', lit(PipelineRunId))
display(df)

# COMMAND ----------

if loadType.upper() == "F":
    print('write mode set to overwrite')
    writeMode = "overwrite"
elif loadType.upper() == "I":
    print('write mode set to merge')
    writeMode = "merge"
else: 
    raise Exception("LoadType not supported.")

deltaApp = DeltaHelper()

output, df = deltaApp.writeToDelta(
    df=df,
    tempViewName=tempViewName,
    abfssPath=cleansedAbfssPath,
    containerName=cleansedContainerName,
    schemaName=cleansedSchemaName,
    tableName=tableName,
    pkFields=pkList, 
    partitionFields=partitionList, 
    writeMode=writeMode)

# COMMAND ----------

print(output)

# COMMAND ----------

# explicitly drop the temporary view
spark.catalog.dropTempView(tempViewName)
