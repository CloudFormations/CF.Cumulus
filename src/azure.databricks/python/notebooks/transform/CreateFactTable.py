# Databricks notebook source
# MAGIC %run ../utils/Initialise

# COMMAND ----------

# MAGIC %run ../utils/CreateDeltaObjects

# COMMAND ----------

from utils.HelperFunctions import *

# COMMAND ----------

from utils.ConfigurePayloadVariables import *

# COMMAND ----------

# MAGIC %run ../utils/CheckPayloadFunctions

# COMMAND ----------

dbutils.widgets.text("Notebook Payload","")
dbutils.widgets.text("Pipeline Run Id","")

# COMMAND ----------

import json
payload = json.loads(dbutils.widgets.get("Notebook Payload"))

# COMMAND ----------

cleansed_secret, cleansed_storage_name, cleansed_container_name, curated_secret, curated_storage_name, curated_container_name, curated_schema_name, curated_dataset_name, columns_list, columnTypeList, bk_list, partition_list, surrogate_key, loadType, businessLogicNotebookPath = get_transform_payload_variables(payload)

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

if loadType.upper() == "F":
   # This will catch schema changes based on upsteam load action configuration?
    replace = 1
elif loadType.upper() == "I":
    replace = 0
else: 
    raise Exception("LoadType not supported.")

# COMMAND ----------

# check Delta Objects exist (import check functions)
# check schema exists
schemaExists = check_exists_delta_schema(schema_name=curated_schema_name)

# create schema, if required
if schemaExists == False:
    create_schema(container_name=curated_container_name, schema_name=curated_schema_name)

# COMMAND ----------

partition_fields_sql = create_partition_fields_sql(partition_list)
location = set_delta_table_location(schema_name=curated_schema_name, table_name=curated_dataset_name, abfss_path=curated_abfss_path)
columns_string = format_columns_sql(columns_list, columnTypeList)

# COMMAND ----------

create_table(container_name=curated_container_name, schema_name=curated_schema_name, table_name=curated_dataset_name, location=location, partition_fields_sql=partition_fields_sql, columns_string=columns_string, surrogate_key=surrogate_key, replace=replace)


# COMMAND ----------

location


# COMMAND ----------


