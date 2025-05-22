# Databricks notebook source
# MAGIC %md
# MAGIC #Transform Check Functionality
# MAGIC - Check payload validity
# MAGIC - Confirm storage is accessible
# MAGIC - Create Delta Table, if required
# MAGIC

# COMMAND ----------

import sys, os
from pprint import pprint

current_directory = os.getcwd()
parent_directory = os.path.abspath(os.path.join(current_directory, '..'))
sys.path.append(parent_directory)
utils_directory = os.path.abspath(os.path.join(current_directory, '..','utils'))
sys.path.append(utils_directory)

# COMMAND ----------

# Import Base utility functions
from CheckPayloadFunctions import *

# Import Ingest utility functions
from utils.ConfigurePayloadVariables import *
from utils.CheckPayloadFunctions import *

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

cleansed_secret, cleansed_storage_name, cleansed_container_name, curated_secret, curated_storage_name, curated_container_name, curated_schema_name, curated_dataset_name, columns_list, column_type_list, bk_list, partition_list, surrogate_key, load_type, business_logic_notebook_path = get_transform_payload_variables(payload)


# COMMAND ----------

# MAGIC %md
# MAGIC # Initialisation

# COMMAND ----------

print("Setting cleansed ABFSS config...")
set_abfss_spark_config(cleansed_secret, cleansed_storage_name)

print("Setting curated ABFSS config...")
set_abfss_spark_config(curated_secret, curated_storage_name)

# COMMAND ----------

print("Setting cleansed ABFSS path...")
cleansed_abfss_path = set_abfss_path(cleansed_storage_name, cleansed_container_name)

print("Setting curated ABFSS path...")
curated_abfss_path = set_abfss_path(curated_storage_name, curated_container_name)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Payload Validity

# COMMAND ----------

# Check data types and nullability of each dictionary element
check_load_action(load_action = load_type)

# COMMAND ----------

check_merge_and_pk_conditions(load_action = load_type, pkList=bk_list)

# COMMAND ----------

check_container_name(container_name = cleansed_container_name)

# COMMAND ----------

check_container_name(container_name = curated_container_name)

# COMMAND ----------

check_surrogate_key(surrogate_key=surrogate_key)

# COMMAND ----------

check_empty_partition_by_fields(partition_list)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Storage accessibility

# COMMAND ----------

# Check cleansed storage account exists and is accessible.
check_abfss(abfss_path=cleansed_abfss_path)

# Check curated storage account exists and is accessible.
check_abfss(abfss_path=curated_abfss_path)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Schema created

# COMMAND ----------

schema_exists = check_exists_delta_schema(schema_name = curated_schema_name)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Table created

# COMMAND ----------

curated_table_path = set_table_path(schema_name =curated_schema_name, table_name =curated_dataset_name)
print(curated_table_path)

# COMMAND ----------

# add load_type to sp results + variables
# rename existing load_type to load_action in the prevtests 
table_exists = check_exists_delta_table(table_path = curated_table_path, load_action = load_type, load_type = load_type)
