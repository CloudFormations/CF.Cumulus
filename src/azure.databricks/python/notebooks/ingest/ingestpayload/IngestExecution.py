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

# MAGIC %run ../../utils/Initialise

# COMMAND ----------

# MAGIC %run ../../utils/HelperFunctions

# COMMAND ----------

# MAGIC %run ../utils/ConfigurePayloadVariables

# COMMAND ----------

# MAGIC %run ../../utils/CheckPayloadFunctions

# COMMAND ----------

# MAGIC %run ../../utils/OperationalMetrics

# COMMAND ----------

# MAGIC %run ./CreateMergeQuery

# COMMAND ----------

# MAGIC %run ../../utils/CreateDeltaObjects

# COMMAND ----------

# MAGIC %run ../../utils/WriteToDelta

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

[tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(payload)

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

# Spark Read extended options. When switching versions of dataset, this is a required option.
options = {
    'header':'True',
    "mergeSchema": "true"
    }


#different options for specifying, based on how we save abfss folder hierarchy.
fileFullPath = f"{rawAbfssPath}/{rawSchemaName}/{tableName}/version={versionNumber}/{loadActionText}/{dateTimeFolderHierarchy}/{tableName}.{rawFileType}"
print(fileFullPath)

# assuming json,csv, parquet
df = spark.read \
    .options(**options) \
    .format(rawFileType) \
    .load(fileFullPath)

# display(df)

# COMMAND ----------

df = df.withColumn('PipelineExecutionDateTime', to_timestamp(lit(pipelineExecutionDateTime)))
df = df.withColumn('PipelineRunId', lit(pipelineRunId))
# display(df)

# COMMAND ----------

# drop duplicates
df = df.dropDuplicates()

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

# COMMAND ----------

# Set output for operational metrics
output = {}

# COMMAND ----------

# check DF size 
isDfNonZero = checkDfSize(df=df)

if isDfNonZero is False:
    output = {"message": "No New Rows to Process"}
    
    # explicitly drop the temporary view
    spark.catalog.dropTempView(tempViewName)
    
    # break out of notebook
    dbutils.notebook.exit(output)

# COMMAND ----------

# build partitionFieldsSQL statement
partitionFieldsSQL = createPartitionFieldsSQL(partitionFields=partitionList)

# COMMAND ----------

# check Delta Objects exist (import check functions)
# check schema exists
schemaExists = checkExistsDeltaSchema(schemaName=cleansedSchemaName)

# create schema, if required
if schemaExists == False:
    createSchema(containerName=cleansedContainerName, schemaName=cleansedSchemaName)

# COMMAND ----------

# check Delta Objects exist (import check functions)
# set Delta Table file path
location = setDeltaTableLocation(schemaName=cleansedSchemaName, tableName=tableName, abfssPath=cleansedAbfssPath)

# check Delta table exists
cleansedTablePath = setTablePath(schemaName =cleansedSchemaName, tableName =tableName)
tableExists = checkExistsDeltaTable(tablePath = cleansedTablePath, loadAction = loadAction, loadType = loadType)

# Create Delta table, if required
tableCreated = False

if tableExists == False:
    columnsString = formatColumnsSQL(totalColumnList, totalColumnTypeList)
    createTable(containerName=cleansedContainerName, schemaName=cleansedSchemaName, tableName=tableName,location=location, partitionFieldsSQL=partitionFieldsSQL, columnsString=columnsString)
    tableCreated = True
    
    # get operations metrics 
    output = getOperationMetrics(schemaName=cleansedSchemaName, tableName=tableName, output=output)


# COMMAND ----------

if loadAction.upper() == "F":
    print('Write mode set to overwrite')
    writeMode = "overwrite"
elif loadAction.upper() == "I":
    print('Write mode set to merge')
    writeMode = "merge"
else: 
    raise Exception("LoadAction not supported.")

targetDelta = getTargetDeltaTable(schemaName = cleansedSchemaName, tableName=tableName)

writeToDeltaExecutor(writeMode=writeMode, targetDf=targetDelta, df=df, schemaName=cleansedSchemaName, tableName=tableName, pkFields=pkList, columnsList=totalColumnList, partitionFields=partitionList)

# COMMAND ----------

output = getOperationMetrics(schemaName=cleansedSchemaName, tableName=tableName, output=output)
print(output)

# COMMAND ----------

# explicitly drop the temporary view
spark.catalog.dropTempView(tempViewName)
