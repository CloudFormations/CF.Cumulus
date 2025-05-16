# Databricks notebook source

# COMMAND ----------

raw_container_path = "abfss://raw@mystorageaccount.dfs.core.windows.net/"

# COMMAND ----------
try:
    files_in_raw_path = dbutils.fs.ls(raw_container_path)
    if len(files_in_raw_path) > 0:
        print(f"Files found in '{raw_container_path}' and container is accessible.")
    elif len(files_in_raw_path) == 0:
        print(f"No files found in '{raw_container_path}', but container is accessible")
    else:
        print(1)
except Exception as e:
    print(str(e))
    if "The specified path does not exist." in str(e):
        raise ValueError("File path within container provided does not exist. Please review the provided container path: {raw_container_path}")
    elif "The specified filesystem does not exist." in str(e):
        raise ValueError("Container provided does not exist. Please review the provided container path: {raw_container_path}")
    elif "Failure to initialize configuration for storage account" in str(e):
        raise ValueError("Storage account is not accessible to the Databricks Cluster or does not exist. Please review storage account specified in the provided path: {raw_container_path}")
    else:
        raise Exception(f"Unknown error encountered: {str(e)}")
