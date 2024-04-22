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
dbutils.widgets.text("pipeline_run_id","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

import json

payload = json.loads(dbutils.widgets.get("Merge Payload"))


# COMMAND ----------



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
    "dateTimeFolderHierarchy": "year=2024/month=04/day=09",  # ingest.Datasets

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

# COMMAND ----------


# create variables for each payload item
tableName = payload["cleansedTableName"] 
loadType = payload["loadType"]
loadTypeText = "full" if loadType == "F" else "incremental"
version = f"{int(payload['version']):04d}"

rawStorageName = payload["rawStorageName"]
rawContainerName = payload["rawContainerName"]
rawSecret = payload["rawSecret"]
rawLoadDate = payload["rawLoadDate"]

rawSchemaName = payload["rawSchemaName"]
rawFileType = payload["rawFileType"]
dateTimeFolderHierarchy = payload["dateTimeFolderHierarchy"]

cleansedStorageName = payload["cleansedStorageName"]
cleansedContainerName = payload["cleansedContainerName"]
cleansedSecret = payload["cleansedSecret"]
cleansedLastRunDate = payload["cleansedLastRunDate"]

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

# loadType = 'F'
# cleansedTablePath = 'failed_table_name'
# cleansedTablePath = 'failed table name'
# cleansedTablePath = 'default.people'

cleansedTablePath = setTablePath(schemaName =cleansedSchemaName, tableName =tableName)
print(cleansedTablePath)

# COMMAND ----------

deltaTableExistsCheck(tablePath = cleansedTablePath, loadType = loadType)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: RunDate vs Last load Date

# COMMAND ----------

rawLoadDateFmt = datetime.strptime(rawLoadDate,'%Y-%m-%d').date()
cleansedLastRunDateFmt = datetime.strptime(cleansedLastRunDate,'%Y-%m-%d').date()

# COMMAND ----------

compareLoadVsLastCleansedDate(rawLoadDate = rawLoadDate, cleansedLastRunDate = cleansedLastRunDate)

# COMMAND ----------

