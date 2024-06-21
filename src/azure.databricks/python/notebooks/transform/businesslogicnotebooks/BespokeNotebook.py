# Databricks notebook source
strSQL = """
    SELECT AddressId, CONCAT_WS(',' , AddressLine1,AddressLine2) as FullAddress 
    FROM adventureworkssqlserver.salesdemo_address
"""

# COMMAND ----------

dbutils.notebook.exit(strSQL)
