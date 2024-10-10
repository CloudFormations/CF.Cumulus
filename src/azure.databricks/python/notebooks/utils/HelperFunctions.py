# Databricks notebook source
from delta.tables import *

# COMMAND ----------

def checkDfSize(df: DataFrame) -> bool:
    """
    Summary:
        Confirm that the dataset provided is not empty (non-zero row count).
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.

    Returns:
        state (bool): Boolean state of the check, True if non-empty DataFrame
        output (dict): Output message to log that no rows were in the DataFrame for processing
    """
    if df.count() > 0:
        return True
    elif df.count() == 0:
        return False
    else: 
        raise Exception(f'Invalid rowcount returned from DataFrame. Value {df.count()}.')


# COMMAND ----------

def createPartitionFieldsSQL(partitionFields: list() = []) -> str:
    """
    Summary:
        Create the SQL statement to partition dataset by the partition fields specified in the Transformation payload.
    
    Args:
        partitionFields (dict): Dictionary of Attributes in the dataset to partition the Delta table by.
    
    Returns:
        partitionFieldsSQL (str): Spark SQL partition by clause containing the provided Attributes.
    """
    partitionFieldsSQL = ''
    if len(partitionFields) > 0:
        partitionFieldsSQL = "\nPARTITIONED BY (" + ",".join(f"{pf}" for pf in partitionFields) + ")\n"
    return partitionFieldsSQL

# COMMAND ----------

# For incremental loads or depending on source file format, columns may not be loaded to bronze, despite being specified in the schema. Example - reading entirely NULL columns from Dynamics 365 excludes these from the Parquet which is written.
def getColumnsNotInSchema(columnsList: list(), df: DataFrame) -> list():
    return [column for column in columnsList if column not in df.columns]

# Add to DataFrame as NULL columns
def setNullColumn(df: DataFrame, column: str) -> DataFrame:
    return df.withColumn(column, lit(None))