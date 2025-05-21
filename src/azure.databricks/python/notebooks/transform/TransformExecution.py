# Databricks notebook source
# MAGIC %run ../utils/Initialise

# COMMAND ----------

import sys, os
from pprint import pprint

current_directory = os.getcwd()
parent_directory = os.path.abspath(os.path.join(current_directory, '..','..','utils'))
sys.path.append(parent_directory)

# COMMAND ----------

from utils.HelperFunctions import *

# COMMAND ----------

# MAGIC %run ../utils/CreateDeltaObjects

# COMMAND ----------

# MAGIC %run ../utils/WriteToDelta

# COMMAND ----------

# MAGIC %run ../utils/OperationalMetrics

# COMMAND ----------

from utils.ConfigurePayloadVariables import *

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

location = setDeltaTableLocation(schemaName=curatedSchemaName, tableName=curatedDatasetName, abfssPath=curatedAbfssPath)

# COMMAND ----------

# CALL BUSINESS LOGIC NOTEBOOK
strSQL = dbutils.notebook.run(businessLogicNotebookPath, 60 ,{})

# COMMAND ----------

sourceDf = spark.sql(strSQL)
# display(sourceDf)

# COMMAND ----------

targetDf = spark.read.format("delta").load(location)

# COMMAND ----------

output = {}

# COMMAND ----------

# check DF size 
isDfNonZero = checkDfSize(df=sourceDf)

if isDfNonZero is False:
    output = {"message": "No New Rows to Process"}
        
    # break out of notebook
    dbutils.notebook.exit(output)

# COMMAND ----------

if loadType.upper() == "F":
    print('Write mode set to overwrite')
    writeMode = "overwriteSurrogateKey"
elif loadType.upper() == "I":
    print('Write mode set to merge')
    writeMode = "merge"
else: 
    raise Exception("LoadType not supported.")

# COMMAND ----------

targetDelta = getTargetDeltaTable(schemaName = curatedSchemaName, tableName=curatedDatasetName)

writeToDeltaExecutor(writeMode=writeMode, targetDf=targetDelta, df=sourceDf, schemaName=curatedSchemaName, tableName=curatedDatasetName, pkFields=bkList, columnsList=columnsList, partitionFields=partitionList)

# COMMAND ----------

output = getOperationMetrics(schemaName=curatedSchemaName, tableName=curatedDatasetName, output=output)
print(output)
