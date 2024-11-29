# Databricks notebook source
strSQL = """
SELECT 
  c.CustomerID, 
  c.CompanyName, 
  REPLACE(c.SalesPerson, 'adventure-works\', '') AS SalesPerson, 
  CASE WHEN ca.AddressType IS NULL THEN  'Not Specified' ELSE ca.AddressType END  AS AddressType 
FROM hive_metastore.adventureworkssqlserver.salesdemo_customer AS c
LEFT JOIN hive_metastore.adventureworkssqlserver.SalesDemo_CustomerAddress AS ca
ON c.CustomerID = ca.CustomerID
"""

# COMMAND ----------

dbutils.notebook.exit(strSQL)
