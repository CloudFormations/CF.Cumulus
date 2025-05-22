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

cleansed_secret, cleansed_storage_name, cleansed_container_name, curated_secret, curated_storage_name, curated_container_name, curated_schema_name, curated_dataset_name, columns_list, column_type_list, bk_list, partition_list, surrogate_key, load_type, business_logic_notebook_path = get_transform_payload_variables(payload)

# COMMAND ----------

print("Setting cleansed ABFSS config...")
set_abfss_spark_config(cleansed_secret, cleansed_storage_name)

print("Setting curated ABFSS config...")
set_abfss_spark_config(cleansed_secret, curated_storage_name)

# COMMAND ----------

print("Setting cleansed ABFSS path...")
cleansed_abfss_path = set_abfss_path(cleansed_storage_name, cleansed_container_name)

print("Setting curated ABFSS path...")
curated_abfss_path = set_abfss_path(curated_storage_name, curated_container_name)

# COMMAND ----------

location = set_delta_table_location(schema_name=curated_schema_name, table_name=curated_dataset_name, abfss_path=curated_abfss_path)

# COMMAND ----------

# CALL BUSINESS LOGIC NOTEBOOK
strSQL = dbutils.notebook.run(businessLogicNotebookPath, 60 ,{})

# COMMAND ----------

sourceDf = spark.sql(strSQL)
# display(sourceDf)

# COMMAND ----------

target_df = spark.read.format("delta").load(location)

# COMMAND ----------

output = {}

# COMMAND ----------

# check DF size 
isDfNonZero = check_df_size(df=sourceDf)

if isDfNonZero is False:
    output = {"message": "No New Rows to Process"}
        
    # break out of notebook
    dbutils.notebook.exit(output)

# COMMAND ----------

if loadType.upper() == "F":
    print('Write mode set to overwrite')
    write_mode = "overwritesurrogate_key"
elif loadType.upper() == "I":
    print('Write mode set to merge')
    write_mode = "merge"
else: 
    raise Exception("LoadType not supported.")

# COMMAND ----------

targetDelta = get_target_delta_table(schema_name = curated_schema_name, table_name=curated_dataset_name)

write_to_delta_executor(write_mode=write_mode, target_df=targetDelta, df=sourceDf, schema_name=curated_schema_name, table_name=curated_dataset_name, pk_fields=bk_list, columns_list=columns_list, partition_fields=partition_list)

# COMMAND ----------

output = get_operation_metrics(schema_name=curated_schema_name, table_name=curated_dataset_name, output=output)
print(output)
