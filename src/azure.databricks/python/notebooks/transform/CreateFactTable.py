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

# Import Ingest utility functions
from utils.ConfigurePayloadVariables import *

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")

# COMMAND ----------

import json
payload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

cleansed_secret, cleansed_storage_name, cleansed_container_name, curated_secret, curated_storage_name, curated_container_name, curated_schema_name, curated_dataset_name, columns_list, columnTypeList, bk_list, partition_list, surrogate_key, load_type, businessLogicNotebookPath = get_transform_payload_variables(payload)

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

# Payload Validation: 
# ADVISORY: Check for unadvised column types (e.g. STRING)
# ADVISORY: Check aggregations exist
# ADVISORY: Check for partitionby fields being used if data size is expected < 1TB

# COMMAND ----------

if load_type.upper() == "F":
   # This will catch schema changes based on upsteam load action configuration?
    replace = 1
elif load_type.upper() == "I":
    replace = 0
else: 
    raise ValueError("Load type not supported.")

# COMMAND ----------

# check Delta Objects exist (import check functions)
# check schema exists
schema_exists = check_exists_delta_schema(schema_name=curated_schema_name)

# create schema, if required
if schema_exists == False:
    create_schema(container_name=curated_container_name, schema_name=curated_schema_name)

# COMMAND ----------

partition_fields_sql = create_partition_fields_sql(partition_list)
location = set_delta_table_location(schema_name=curated_schema_name, table_name=curated_dataset_name, abfss_path=curated_abfss_path)
columns_string = format_columns_sql(columns_list, columnTypeList)

# COMMAND ----------

create_table(container_name=curated_container_name, schema_name=curated_schema_name, table_name=curated_dataset_name, location=location, partition_fields_sql=partition_fields_sql, columns_string=columns_string, surrogate_key=surrogate_key, replace=replace)

