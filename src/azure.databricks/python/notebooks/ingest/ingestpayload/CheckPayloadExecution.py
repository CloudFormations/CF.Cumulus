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

import sys, os
from pprint import pprint

current_directory = os.getcwd()
parent_directory = os.path.abspath(os.path.join(current_directory, '..'))
sys.path.append(parent_directory)
utils_directory = os.path.abspath(os.path.join(current_directory, '..','..','utils'))
sys.path.append(utils_directory)

# COMMAND ----------

# Import Base utility functions
from Initialise import *
from CheckPayloadFunctions import *

# Import Ingest utility functions]
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

[table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload)

# COMMAND ----------

# MAGIC %md
# MAGIC # Initialisation

# COMMAND ----------

print("Setting raw ABFSS config...")
set_abfss_spark_config(raw_secret, raw_storage_name)

print("Setting cleansed ABFSS config...")
set_abfss_spark_config(cleansed_secret, cleansed_storage_name)

# COMMAND ----------

print("Setting raw ABFSS path...")
raw_abfss_path = set_abfss_path(raw_storage_name, raw_container_name)

print("Setting cleansed ABFSS path...")
cleansed_abfss_path = set_abfss_path(cleansed_storage_name, cleansed_container_name)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Payload Validity

# COMMAND ----------

# Check data types and nullability of each dictionary element
check_load_action(load_action = load_action)

# COMMAND ----------

check_merge_and_pk_conditions(load_action = load_action, pk_list=pk_list)

# COMMAND ----------

check_container_name(container_name = raw_container_name)

# COMMAND ----------

check_container_name(container_name = cleansed_container_name)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Storage accessibility

# COMMAND ----------

# Check Raw storage account exists and is accessible.
check_abfss(abfss_path=raw_abfss_path)

# Check cleansed storage account exists and is accessible.
check_abfss(abfss_path=cleansed_abfss_path)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Schema created

# COMMAND ----------

schema_exists = check_exists_delta_schema(schema_name = cleansed_schema_name)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: Delta Table created

# COMMAND ----------

cleansed_table_path = set_table_path(schema_name =cleansed_schema_name, table_name =table_name)
print(cleansed_table_path)

# COMMAND ----------

table_exists = check_exists_delta_table(table_path = cleansed_table_path, load_action = load_action, load_type = load_type)

# COMMAND ----------

# MAGIC %md
# MAGIC # Check: RunDate vs Last load Date

# COMMAND ----------

compare_raw_load_vs_last_cleansed_date(raw_last_load_date = raw_last_load_date,cleansed_last_load_date =cleansed_last_load_date)
