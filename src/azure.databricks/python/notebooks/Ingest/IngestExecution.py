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

payload = json.loads(dbutils.widgets.get("Merge Payload"))
pipelineRunId = json.loads(dbutils.widgets.get("Pipeline Run Id",""))

# payload = {
  # 'pipelineId': str, # Unsure if required at this stage
  # 'tableName': str,
  # 'attributesList': str, # SQL string cast to list in python
  # 'loadType': str,
  # 'computeTarget': str,
  # 'rawLoadDate': datetime,
  # 'rawStorageName': str,
  # 'rawContainerName': str,
  # 'rawDirectoryName': str, # I think we want to ignore this one
  # 'rawSchemaName': str # 'rawConnectionName': str
  # 'rawFileName': str,
  # 'transformedLastRunDate': datetime, # NULLable
  # 'cleansedStorageName': str,
  # 'cleansedContainerName': str,
  # 'cleansedSchemaName': str # 'cleansedConnectionName': str
  # 'cleansedFileName': str,
# }

# COMMAND ----------

#example values for widgets

payload = {
    "rawTableName": "control_Pipelines", # ingest.Datasets
    "loadType": "F", # ingest.Datasets
    "version": "1", # ingest.Datasets

    "rawLoadDate": "2024-01-01", # ingest.Datasets or folderHierarchy

    "computeTarget": "Databricks_small", # ingest.Connections # we could add a defensive check for the execution
    "rawStorageName": "cumulusframeworkdev", # ingest.Connections
    "rawContainerName": "raw", # ingest.Connections
    "rawSchemaName": "MetadataDatabase", # ingest.Connections
    "rawSecret": "cumulusframeworkdevaccesskey", # ingest.Connections

    "rawFileName": "control_Pipelines", # ingest.Datasets
    "rawFileType": "parquet", # ingest.Datasets
    "dateTimeFolderHierarchy": "year=2024/month=04/day=18",  # ingest.Datasets

    "cleansedTableName": "control_Pipelines", # ingest.Datasets
    "cleansedLastRunDate": "2024-01-01",#Null # ingest.Datasets
    "cleansedStorageName": "cumuluscleanseddev", # ingest.Connections
    "cleansedContainerName": "cleansed", # ingest.Connections
    "cleansedSchemaName": "MetadataDatabase", # ingest.Datasets
    "cleansedFileName": "control_Pipelines", # ingest.Datasets
    "cleansedSecret":"cumuluscleanseddevaccesskey", # ingest.Connections
    "cleansedPkList": "PipelineId", # transform.Datasets
    "cleansedPartitionFields": "", # transform.Datasets
    "cleansedColumnsList": "PipelineId,OrchestratorId,StageId,PipelineName,LogicalPredecessorId,Enabled,PipelineRunId,PipelineExecutionDateTime", # ingest.Attributes
    "cleansedColumnsTypeList": "integer,integer,integer,string,integer,boolean,string,string", # ingest.Attributes
    "cleansedColumnsFormatList": ",,,,,,,", # ingest.Attributes

    #sourceSysDataType
    #sparkSysDataType


    # additional supplementary columns if we want to replace the way we hand rawLoadDate, trasnformedLastRunDate
    # "cleansedMetadataColumnList": "TimeOfIngestion,TimeOfConformation", # ingest.Datasets
    # "cleansedMetadataColumnTypeList": "timestamp,timestamp", # ingest.Datasets
    # "cleansedMetadataColumnFormatList": "yyyy-MM-dd HH:mm:ss,yyyy-MM-dd HH:mm:ss", # ingest.Datasets
}

pipelineRunId = 'TestRunIdGUID'

# COMMAND ----------

# create variables for each payload item

tableName = payload["cleansedTableName"] 
loadType = payload["loadType"]
loadTypeText = "full" if loadType == "F" else "incremental"
version = f"{int(payload['version']):04d}"

rawStorageName = payload['rawStorageName']
rawContainerName = payload['rawContainerName']
rawSecret = payload['rawSecret']

rawSchemaName = payload['rawSchemaName']
rawFileType = payload['rawFileType']
dateTimeFolderHierarchy = payload['dateTimeFolderHierarchy']

cleansedStorageName = payload['cleansedStorageName']
cleansedContainerName = payload['cleansedContainerName']
cleansedSecret = payload['cleansedSecret']

cleansedSchemaName = payload["cleansedSchemaName"] 

# Semantic checks for these required in the TransformChecks notebook?
pkList =  payload["cleansedPkList"].split(",")
partitionList =  payload["cleansedPartitionFields"].split(",") if  payload["cleansedPartitionFields"] != "" else []

columnsList = payload["cleansedColumnsList"].split(",")
columnsTypeList = payload["cleansedColumnsTypeList"].split(",")
columnsFormatList = payload["cleansedColumnsFormatList"].split(",")
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
options = {'header':'True'}

# Extended option, we need to confirm the mergeSchema failure behaviour. When switching versions of dataset, will want this enabled.
# options = {
#     'header':'True',
#     "mergeSchema": "true"
#     }


#different options for specifying, based on how we save abfss folder hierarchy.
fileFullPath = f"{rawAbfssPath}/{rawSchemaName}/{tableName}/version={version}/{loadTypeText}/{dateTimeFolderHierarchy}/{tableName}.{rawFileType}"

# assuming json,csv, parquet
df = spark.read \
    .options(**options) \
    .format(rawFileType) \
    .load(fileFullPath)

display(df)

# COMMAND ----------

# Create temporary table for SELECT statements
tempViewName = f"{tableName}_{pipelineRunId}"
df.createOrReplaceTempView(tempViewName)

# COMMAND ----------

totalColumnStr = selectSqlColumnsFormatString(totalColumnList, totalColumnTypeList, totalColumnFormatList)

selectSQLFullString = f"SELECT {totalColumnStr} FROM {tempViewName}"
print(selectSQLFullString)

# COMMAND ----------

df = spark.sql(selectSQLFullString)
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