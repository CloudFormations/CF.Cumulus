# Databricks notebook source
str_sql = """
    SELECT 
        Date,
        CAST(DATE_FORMAT(Date, 'yyyyMMdd') AS INTEGER) AS DateKey,
        DATE_FORMAT(Date, 'EEEE') AS DayName,
        DAY(Date) AS DayOfMonth,
        MONTH(Date) AS Month,
        DATE_FORMAT(Date, 'MMMM') AS MonthName,
        QUARTER(Date) AS Quarter,
        YEAR(Date) AS Year
    FROM (
        SELECT 
            sequence(
                to_date('2005-01-01'), 
                to_date('2025-12-31'), 
                interval 1 day
            ) AS DateSeq
    ) AS DateRange
    LATERAL VIEW explode(DateSeq) AS Date;
"""

# COMMAND ----------

dbutils.notebook.exit(str_sql)
