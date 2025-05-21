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

# MAGIC %run ../../utils/Initialise

# COMMAND ----------

# MAGIC %run ../../utils/CheckPayloadFunctions

# COMMAND ----------

from utils.ConfigurePayloadVariables import *

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

[tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(payload)

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
checkLoadAction(loadAction = loadAction)

# COMMAND ----------

checkMergeAndPKConditions(loadAction = loadAction, pkList=pkList)

# COMMAND ----------

checkContainerName(containerName = rawContainerName)

# COMMAND ----------

checkContainerName(containerName = cleansedContainerName)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Storage accessibility

# COMMAND ----------

# Check Raw storage account exists and is accessible.
checkAbfss(abfssPath=rawAbfssPath)

# Check cleansed storage account exists and is accessible.
checkAbfss(abfssPath=cleansedAbfssPath)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Schema created

# COMMAND ----------

schemaExists = checkExistsDeltaSchema(schemaName = cleansedSchemaName)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Table created

# COMMAND ----------

cleansedTablePath = setTablePath(schemaName =cleansedSchemaName, tableName =tableName)
print(cleansedTablePath)

# COMMAND ----------

tableExists = checkExistsDeltaTable(tablePath = cleansedTablePath, loadAction = loadAction, loadType = loadType)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: RunDate vs Last load Date

# COMMAND ----------

compareRawLoadVsLastCleansedDate(rawLastLoadDate = rawLastLoadDate, cleansedLastLoadDate = cleansedLastLoadDate)

# COMMAND ----------


