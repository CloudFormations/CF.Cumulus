# Databricks notebook source
str_sql = """
    SELECT 
        p.ProductID AS ProductKey,
        p.Name AS ProductName,
        p.Color AS ProductColour,
        p.Size AS ProductSize
    FROM 
        hive_metastore.adventureworksdemo.Product p
"""

# COMMAND ----------

dbutils.notebook.exit(str_sql)
