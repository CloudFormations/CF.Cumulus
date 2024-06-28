# Databricks notebook source
# Generate Sample Date Table: https://www.tackytech.blog/how-to-create-a-date-dimension-table-in-python-and-pyspark/

# load packages
from pyspark.sql.functions import *
from datetime import datetime, timedelta

# COMMAND ----------

# define boundaries
startdate = datetime.strptime('2023-01-01','%Y-%m-%d')
enddate   = (datetime.now() + timedelta(days=365 * 3)).replace(month=12, day=31)  # datetime.strptime('2023-10-01','%Y-%m-%d')

# COMMAND ----------

# define column names and its transformation rules on the Date column
column_rule_df = spark.createDataFrame([
    ("DateBk",              "cast(date_format(date, 'yyyyMMdd') as int)"),     # 20230101
    ("Year",                "year(date)"),                                     # 2023
    ("Quarter",             "quarter(date)"),                                  # 1
    ("Month",               "month(date)"),                                    # 1
    ("Day",                 "day(date)"),                                      # 1
    ("Week",                "weekofyear(date)"),                               # 1
    ("QuarterNameLong",     "date_format(date, 'QQQQ')"),                      # 1st qaurter
    ("QuarterNameShort",    "date_format(date, 'QQQ')"),                       # Q1
    ("QuarterNumberString", "date_format(date, 'QQ')"),                        # 01
    ("MonthNameLong",       "date_format(date, 'MMMM')"),                      # January
    ("MonthNameShort",      "date_format(date, 'MMM')"),                       # Jan
    ("MonthNumberString",   "date_format(date, 'MM')"),                        # 01
    ("DayNumberString",     "date_format(date, 'dd')"),                        # 01
    ("WeekNameLong",        "concat('week', lpad(weekofyear(date), 2, '0'))"), # week 01
    ("WeekNameShort",       "concat('w', lpad(weekofyear(date), 2, '0'))"),    # w01
    ("WeekNumberString",    "lpad(weekofyear(date), 2, '0')"),                 # 01
    ("DayOfWeek",           "dayofweek(date)"),                                # 1
    ("YearMonthString",     "date_format(date, 'yyyy/MM')"),                   # 2023/01
    ("DayOfWeekNameLong",   "date_format(date, 'EEEE')"),                      # Sunday
    ("DayOfWeekNameShort",  "date_format(date, 'EEE')"),                       # Sun
    ("DayOfMonth",          "cast(date_format(date, 'd') as int)"),            # 1
    ("DayOfYear",           "cast(date_format(date, 'D') as int)"),            # 1
], ["new_column_name", "expression"])


# COMMAND ----------

# explode dates between the defined boundaries into one column
start = int(startdate.timestamp())
stop  = int(enddate.timestamp())
df = spark.range(start, stop, 60*60*24).select(col("id").cast("timestamp").cast("date").alias("Date"))
# display(df)

# COMMAND ----------

# this loops over all rules defined in column_rule_df adding the new columns
for row in column_rule_df.collect():
    new_column_name = row["new_column_name"]
    expression = expr(row["expression"])
    df = df.withColumn(new_column_name, expression)
# display(df)

# COMMAND ----------

# display(df.withColumn("Playground", expr("date_format(date, 'yyyyMMDD')")))


# COMMAND ----------

df.createOrReplaceGlobalTempView('vw_MyDateTable')

# COMMAND ----------

strSQL = """
SELECT 
  *
FROM
  global_temp.vw_MyDateTable
"""

# COMMAND ----------

# display(spark.sql(strSQL))

# COMMAND ----------

dbutils.notebook.exit(strSQL)
