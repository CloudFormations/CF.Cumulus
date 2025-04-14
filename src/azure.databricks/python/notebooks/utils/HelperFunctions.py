# Databricks notebook source
from delta.tables import *

# COMMAND ----------

def checkZeroBytes(loadAction: str, filePath: str) -> bool:
    """
    Summary:
        Confirm that the Raw file being read is not 0 bytes (empty and no header).
    
    Args:
        loadAction (str): Action to take on the file, either 'F' for full load or 'I' for incremental load.
        filePath (str): File path to the Raw file in ADLS.

    Returns:
        state (bool): Boolean state of the check, True if file is not empty.
    """
    fileMetadata = dbutils.fs.ls(filePath)
    fileSize = fileMetadata[0].size
    print(fileMetadata)
    print(fileSize)
    if fileSize == 0 and loadAction == 'F':
        raise Exception(f'File is empty, full load running. Please check the initial load which populated the file at {filePath}.')
    elif fileSize == 0 and loadAction == 'I':
        print("File is empty, incremental load running. No action required as this is valid activity.")
        return False
    elif fileSize > 0:
        print("File is not empty. No action required.")
        return True
    else:
        raise Exception("Unknown state. Raise error")

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