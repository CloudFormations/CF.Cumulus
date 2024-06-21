# Databricks notebook source
strSQL = """
SELECT 
  word_index AS `WordIndex`,
  english AS `English`,
  hiragana AS `Hiragana`,
  kanji AS `Kanji`,
  date_added AS `DateAdded`,
  rank AS `Rank`,
  is_active AS `Active`
FROM 
  fileswindowservervm02binaryfiles.worddictionary
"""

# COMMAND ----------


dbutils.notebook.exit(strSQL)
