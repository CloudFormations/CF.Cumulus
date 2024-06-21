# Databricks notebook source
strSQL = """
SELECT 
  CAST(wd.WordDictionaryId AS INTEGER) AS `WordDictionaryId`,
  CAST(d.DateId AS INTEGER) AS `DateId`,
  --CAST(t.TimeId AS INTEGER) AS `TimeId`,
  CAST(result AS INTEGER) AS `Result`
FROM fileswindowservervm02binaryfiles.vocabularyresults AS vr
INNER JOIN dimensions.WordDictionary AS wd
ON vr.index_word = wd.wordIndex
INNER JOIN dimensions.Date AS d
ON vr.date = d.date
"""

# COMMAND ----------

dbutils.notebook.exit(strSQL)
