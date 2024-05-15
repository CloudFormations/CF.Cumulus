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

# MAGIC %run ../Functions/IngestMergePayloadVariables

# COMMAND ----------

# MAGIC %run ../Functions/WriteDeltaTableHelper

# COMMAND ----------

dbutils.widgets.text("Merge Payload","")
dbutils.widgets.text("Pipeline Run Id","")
dbutils.widgets.text("Pipeline Run DateTime","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

import json
import datetime
from pyspark.sql.functions import *
import pandas as pd

# COMMAND ----------

payload = json.loads(dbutils.widgets.get("Merge Payload"))
pipelineRunId = dbutils.widgets.get("Pipeline Run Id")
pipelineExecutionDateTimeString = dbutils.widgets.get("Pipeline Run DateTime")

# COMMAND ----------

pipelineExecutionDateTime = pd.to_datetime(pipelineExecutionDateTimeString, format='%Y-%m-%dT%H:%M:%S.%fZ')

# COMMAND ----------


[tableName, loadType, loadTypeText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(payload)

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

# display(df)

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
df = df.withColumn('PipelineExecutionDateTime', to_timestamp(lit(pipelineExecutionDateTime)))
df = df.withColumn('PipelineRunId', lit(pipelineRunId))
# display(df)

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
