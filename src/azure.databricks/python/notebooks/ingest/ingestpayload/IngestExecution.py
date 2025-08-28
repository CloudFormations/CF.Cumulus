# Databricks notebook source
# MAGIC %md
# MAGIC #Merge Functionality
# MAGIC - Process metadata schemas raw vs cleansed with data typing
# MAGIC - Create SELECT script for the merge operation
# MAGIC - Functionality for 'F' and 'I' loads:
# MAGIC   - 'F': recreate cleansed table upon execution
# MAGIC   - 'I': merge data on top of existing table
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
from HelperFunctions import *
from OperationalMetrics import *
from CreateDeltaObjects import *
from WriteToDelta import *

# Import Ingest utility functions
from utils.ConfigurePayloadVariables import get_merge_payload_variables
from utils.CreateMergeQuery import *

# COMMAND ----------

import json
import datetime
from pyspark.sql.functions import *
import pandas as pd

# COMMAND ----------

dbutils.widgets.text("Merge Payload","")
dbutils.widgets.text("Pipeline Run Id","")
dbutils.widgets.text("Pipeline Run DateTime","")
#Remove Widgets
#dbutils.widgets.remove("<widget name>")
#dbutils.widgets.removeAll()

# COMMAND ----------

payload = json.loads(dbutils.widgets.get("Merge Payload"))
pipeline_run_id = dbutils.widgets.get("Pipeline Run Id")
pipeline_execution_datetime = dbutils.widgets.get("Pipeline Run DateTime")

# COMMAND ----------

pipeline_execution_datetime = pd.to_datetime(pipeline_execution_datetime, format='%Y-%m-%dT%H:%M:%S.%fZ')

# COMMAND ----------

[table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, columns_unpack_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload)


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
# MAGIC #Get dataset from raw

# COMMAND ----------

# Spark Read extended options. When switching versions of dataset, this is a required option.
options = {
    'header':'True',
    "mergeSchema": "true"
    }

#different options for specifying, based on how we save abfss folder hierarchy.
file_full_path = f"{raw_abfss_path}/{raw_schema_name}/{table_name}/version={version_number}/{load_action_text}/{datetime_folder_hierarchy}/{table_name}.{raw_file_type}"
print(file_full_path)

# assuming json,csv, parquet
df = spark.read \
    .options(**options) \
    .format(raw_file_type) \
    .load(file_full_path)

# display(df)

# COMMAND ----------

df = df.withColumn('PipelineExecutionDateTime', to_timestamp(lit(pipeline_execution_datetime)))
df = df.withColumn('PipelineRunId', lit(pipeline_run_id))
# display(df)

# COMMAND ----------

# For incremental loads or depending on source file format, columns may not be loaded to bronze, despite being specified in the schema. Example - reading entirely NULL columns from Dynamics 365 excludes these from the Parquet which is written.

columns_not_in_schema = get_columns_not_in_schema(columns_list, df)

for column in columns_not_in_schema:
    df = set_null_column(df, column)

# display(df)

# COMMAND ----------

# drop duplicates
df = df.dropDuplicates()

# COMMAND ----------

# Create temporary table for SELECT statements
pipeline_run_id_view_extension = pipeline_run_id.replace('-', '_')
temp_view_name = f"{table_name}_{pipeline_run_id_view_extension}"
df.createOrReplaceTempView(temp_view_name)

# COMMAND ----------

additional_config = select_sql_exploded_option_string(total_column_list, total_column_type_list, total_column_format_list)

format_total_column_format_list = format_attribute_target_data_format_list(total_column_format_list)

total_column_str = select_sql_columns_format_string(total_column_list, total_column_type_list, format_total_column_format_list, columns_unpack_list)

select_sql_full_string = f"SELECT {total_column_str} FROM {temp_view_name} {additional_config}"
print(select_sql_full_string)

# COMMAND ----------

df = spark.sql(select_sql_full_string)

# COMMAND ----------

# Set output for operational metrics
output = {}

# COMMAND ----------

# check DF size 
is_df_non_zero = check_df_size(df=df)

if is_df_non_zero is False:
    output = {"message": "No New Rows to Process"}
    
    # explicitly drop the temporary view
    spark.catalog.dropTempView(temp_view_name)
    
    # break out of notebook
    dbutils.notebook.exit(output)

# COMMAND ----------

# build partition_fields_sql statement
partition_fields_sql = create_partition_fields_sql(partition_fields=partition_list)

# COMMAND ----------

# check Delta Objects exist (import check functions)
# check schema exists
schema_exists = check_exists_delta_schema(schema_name=cleansed_schema_name)

# create schema, if required
if schema_exists == False:
    create_schema(container_name=cleansed_container_name, schema_name=cleansed_schema_name)

# COMMAND ----------

# check Delta Objects exist (import check functions)
# set Delta Table file path
location = set_delta_table_location(schema_name=cleansed_schema_name, table_name=table_name, abfss_path=cleansed_abfss_path)

# check Delta table exists
cleansed_table_path = set_table_path(schema_name =cleansed_schema_name, table_name =table_name)
table_exists = check_exists_delta_table(table_path = cleansed_table_path, load_action = load_action, load_type = load_type)

# Create Delta table, if required
table_created = False

if table_exists == False:
    columns_string = format_columns_sql(total_column_list, total_column_type_list)
    create_table(container_name=cleansed_container_name, schema_name=cleansed_schema_name, table_name=table_name,location=location, partition_fields_sql=partition_fields_sql, columns_string=columns_string)
    table_created = True
    
    # get operations metrics 
    output = get_operation_metrics(schema_name=cleansed_schema_name, table_name=table_name, output=output)


# COMMAND ----------

if load_action.upper() == "F":
    print('Write mode set to overwrite')
    write_mode = "overwrite"
elif load_action.upper() == "I":
    print('Write mode set to merge')
    write_mode = "merge"
else: 
    raise Exception("load_action not supported.")

target_delta = get_target_delta_table(schema_name = cleansed_schema_name, table_name=table_name)

write_to_delta_executor(write_mode=write_mode, target_df=target_delta, df=df, schema_name=cleansed_schema_name, table_name=table_name, pk_fields=pk_list, columns_list=total_column_list, partition_fields=partition_list)

# COMMAND ----------

output = get_operation_metrics(schema_name=cleansed_schema_name, table_name=table_name, output=output)
print(output)

# COMMAND ----------

# explicitly drop the temporary view
spark.catalog.dropTempView(temp_view_name)
