# Databricks notebook source
import sys, os
from pprint import pprint

current_directory = os.getcwd()
parent_directory = os.path.abspath(os.path.join(current_directory, '..'))
sys.path.append(parent_directory)
utils_directory = os.path.abspath(os.path.join(current_directory, '..','utils'))
sys.path.append(utils_directory)

# COMMAND ----------

# Import Base utility functions
from Initialise import *
from HelperFunctions import *
from CheckPayloadFunctions import *
from CreateDeltaObjects import *
from WriteToDelta import *
from OperationalMetrics import *

# Import Ingest utility functions
from utils.ConfigurePayloadVariables import *
from utils.CheckPayloadFunctions import *

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
str_sql = dbutils.notebook.run(business_logic_notebook_path, 60 ,{})

# COMMAND ----------

source_df = spark.sql(str_sql)
# display(source_df)

# COMMAND ----------

target_df = spark.read.format("delta").load(location)

# COMMAND ----------

output = {}

# COMMAND ----------

# check DF size 
is_df_non_zero = check_df_size(df=source_df)

if is_df_non_zero is False:
    output = {"message": "No New Rows to Process"}
        
    # break out of notebook
    dbutils.notebook.exit(output)

# COMMAND ----------

if load_type.upper() == "F":
    print('Write mode set to overwrite')
    write_mode = "overwrite"
elif load_type.upper() == "I":
    print('Write mode set to merge')
    write_mode = "merge"
else: 
    raise ValueError("Load type not supported.")

# COMMAND ----------

target_delta = get_target_delta_table(schema_name = curated_schema_name, table_name=curated_dataset_name)

write_to_delta_executor(write_mode=write_mode, target_df=target_delta, df=source_df, schema_name=curated_schema_name, table_name=curated_dataset_name, pk_fields=bk_list, columns_list=columns_list, partition_fields=partition_list)

# COMMAND ----------

output = get_operation_metrics(schema_name=curated_schema_name, table_name=curated_dataset_name, output=output)
print(output)
