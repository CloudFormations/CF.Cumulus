# Databricks notebook source
# MAGIC %md
# MAGIC #Transform Check Functionality
# MAGIC - Check payload validity
# MAGIC - Confirm storage is accessible
# MAGIC - Create Delta Table, if required
# MAGIC
# MAGIC #TODO items:
# MAGIC - Unit tests
# MAGIC

# COMMAND ----------

# MAGIC %run ../utils/Initialise

# COMMAND ----------

# MAGIC %run ../utils/CheckPayloadFunctions

# COMMAND ----------

# MAGIC %run ./utils/CheckPayloadFunctions
# MAGIC

# COMMAND ----------

from utils.ConfigurePayloadVariables import *

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

import json

payload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

[cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath]= getTransformPayloadVariables(payload)

# COMMAND ----------

# MAGIC %md
# MAGIC # Initialisation

# COMMAND ----------

print("Setting cleansed ABFSS config...")
setAbfssSparkConfig(cleansedSecret, cleansedStorageName)

print("Setting curated ABFSS config...")
setAbfssSparkConfig(curatedSecret, curatedStorageName)

# COMMAND ----------

print("Setting cleansed ABFSS path...")
cleansedAbfssPath = setAbfssPath(cleansedStorageName, cleansedContainerName)

print("Setting curated ABFSS path...")
curatedAbfssPath = setAbfssPath(curatedStorageName, curatedContainerName)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Payload Validity

# COMMAND ----------

# Check data types and nullability of each dictionary element
checkLoadAction(loadAction = loadType)

# COMMAND ----------

checkMergeAndPKConditions(loadAction = loadType, pkList=bkList)

# COMMAND ----------

checkContainerName(containerName = cleansedContainerName)

# COMMAND ----------

checkContainerName(containerName = curatedContainerName)

# COMMAND ----------

checkSurrogateKey(surrogateKey=surrogateKey)

# COMMAND ----------

checkEmptyPartitionByFields(partitionList)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Storage accessibility

# COMMAND ----------

# Check cleansed storage account exists and is accessible.
checkAbfss(abfssPath=cleansedAbfssPath)

# Check curated storage account exists and is accessible.
checkAbfss(abfssPath=curatedAbfssPath)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Schema created

# COMMAND ----------

schemaExists = checkExistsDeltaSchema(schemaName = curatedSchemaName)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Table created

# COMMAND ----------

curatedTablePath = setTablePath(schemaName =curatedSchemaName, tableName =curatedDatasetName)
print(curatedTablePath)

# COMMAND ----------

# add loadtype to sp results + variables
# rename existing loadType to loadAction in the prevtests 
tableExists = checkExistsDeltaTable(tablePath = curatedTablePath, loadAction = loadType, loadType = loadType)
