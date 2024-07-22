# Databricks notebook source
strSQL = """
SELECT
  (hour * 10000) + (minute * 100) + second AS TimeBK,
  hour AS Hour24,
  LPAD(CAST(hour AS STRING), 2, '0') AS Hour24ShortString,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':00') AS Hour24MinString,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':00:00') AS Hour24FullString,
  hour % 12 AS Hour12,
  LPAD(CAST(hour % 12 AS STRING), 2, '0') AS Hour12ShortString,
  CONCAT(LPAD(CAST(hour % 12 AS STRING), 2, '0'), ':00') AS Hour12MinString,
  CONCAT(LPAD(CAST(hour % 12 AS STRING), 2, '0'), ':00:00') AS Hour12FullString,
  hour / 12 AS AmPmCode,
  CASE WHEN hour < 12 THEN 'AM' ELSE 'PM' END AS AmPmString,
  minute AS Minute,
  (hour * 100) + minute AS MinuteCode,
  LPAD(CAST(minute AS STRING), 2, '0') AS MinuteShortString,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':', LPAD(CAST(minute AS STRING), 2, '0'), ':00') AS MinuteFullString24,
  CONCAT(LPAD(CAST(hour % 12 AS STRING), 2, '0'), ':', LPAD(CAST(minute AS STRING), 2, '0'), ':00') AS MinuteFullString12,
  minute / 30 AS HalfHour,
  (hour * 100) + ((minute / 30) * 30) AS HalfHourCode,
  LPAD(CAST(((minute / 30) * 30) AS STRING), 2, '0') AS HalfHourShortString,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':', LPAD(CAST(((minute / 30) * 30) AS STRING), 2, '0'), ':00') AS HalfHourFullString24,
  CONCAT(LPAD(CAST(hour % 12 AS STRING), 2, '0'), ':', LPAD(CAST(((minute / 30) * 30) AS STRING), 2, '0'), ':00') AS HalfHourFullString12,
  second AS Second,
  LPAD(CAST(second AS STRING), 2, '0') AS SecondShortString,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':', LPAD(CAST(minute AS STRING), 2, '0'), ':', LPAD(CAST(second AS STRING), 2, '0')) AS FullTimeString24,
  CONCAT(LPAD(CAST(hour % 12 AS STRING), 2, '0'), ':', LPAD(CAST(minute AS STRING), 2, '0'), ':', LPAD(CAST(second AS STRING), 2, '0')) AS FullTimeString12,
  CONCAT(LPAD(CAST(hour AS STRING), 2, '0'), ':', LPAD(CAST(minute AS STRING), 2, '0'), ':', LPAD(CAST(second AS STRING), 2, '0')) AS FullTime
FROM (
  SELECT
    hour,
    minute,
    second
  FROM (
    SELECT EXPLODE(SEQUENCE(0, 23)) AS hour
  ) h
  CROSS JOIN (
    SELECT EXPLODE(SEQUENCE(0, 59)) AS minute
  ) m
  CROSS JOIN (
    SELECT EXPLODE(SEQUENCE(0, 59)) AS second
  ) s
) t;
"""

# COMMAND ----------

dbutils.notebook.exit(strSQL)
