# Databricks notebook source
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# COMMAND ----------

def setColumnsListAsDict(columnsList: list()) -> dict:
    columnsDict = {column: col(f"src.{column}") for column in columnsList}
    return columnsDict

# COMMAND ----------

# Implementations of the base classes above, providing variations on the create statements required to create schema and table objects for different environments.

# Below are Cleansed-level standard operations

def mergeDelta(targetDf: DataFrame, df: DataFrame, pkFields: dict, columnsList: list(), partitionFields: dict = []) -> None:
    """
    Summary:
        Perform a Merge query for Incremental loading into the target Delta table for the Dataset.

    Args:
        targetDf (DataFrame): Target PySpark DataFrame of the data to be merged into.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        pkFields (dict): Dictionary of the primary key fields.
        columnsList (list): list of columns in source DataFrame.
        partitionFields (dict): Dictionary of the partition by fields.

    """
    columnsDict = setColumnsListAsDict(columnsList)

    (
        targetDf.alias("targetDf")
        .merge(
            source=df.alias("src"),
            condition="\nAND ".join(f"src.{pk} = targetDf.{pk}" for pk in pkFields + partitionFields),
        )
        .whenNotMatchedInsert(values=columnsDict)
        .whenMatchedUpdate(set=columnsDict)
        .execute()
    )
    return

def insertDelta(df: DataFrame, schemaName: str, tableName: str) -> None:
    """
    Summary:
        Perform an Insert query for appending data to the existing target Delta table for the Dataset.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("append").insertInto(f"{schemaName}.{tableName}")
    return

def overwriteDelta(df: DataFrame, schemaName: str, tableName: str) -> None:
    """
    Summary:
        Perform an Overwrite query for the Dataset to replace data in an target Delta table.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("overwrite").insertInto(f"{schemaName}.{tableName}")
    
    return

# COMMAND ----------

# Below are Curated-level operations to account for merging into tables with Identity generated surrogate key columns.
def overwriteDeltaSurrogateKey(df: DataFrame, schemaName: str, tableName: str) -> None:
    """
    Summary:
        Perform an Overwrite query for the Dataset to replace data in an target Delta table.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("overwrite").option("mergeSchema", "true").saveAsTable(f"{schemaName}.{tableName}")
    return

# COMMAND ----------

from functools import partial

def setOperationParameters(targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str, pkFields: dict,columnsList: list(), partitionFields: dict) -> dict:
    """
    Summary:
        Create the parameters for each operation based on the payload values.
    
    Args:
        targetDf (DataFrame): Target PySpark DataFrame of the data to be merged into.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.
        pkFields (dict): Dictionary of the primary key fields.
        partitionFields (dict): Dictionary of the partition by fields.
        columnsList (list): list of columns in source DataFrame.
    
    Returns:
        OperationParameters (dict): Dictionary mapping operation types to the parameter values used.
    """
    
    operationParameters = {
        "merge": partial(mergeDelta, targetDf=targetDf, df=df, pkFields=pkFields, columnsList=columnsList, partitionFields=partitionFields),
        # "insert": partial(insertDelta, df=df, schemaName=schemaName, tableName=tableName), # not currently supported
        "overwrite": partial(overwriteDelta, df=df, schemaName=schemaName, tableName=tableName),
        # "mergeSurrogateKey": partial(mergeDeltaSurrogateKey, targetDf=targetDf, df=df, pkFields=pkFields, columnsList=columnsList, partitionFields=partitionFields),
        "overwriteSurrogateKey": partial(overwriteDeltaSurrogateKey, df=df, schemaName=schemaName, tableName=tableName),
    }
    return operationParameters

# COMMAND ----------

def writeToDeltaExecutor(writeMode: str, targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str, pkFields: dict, columnsList: list(), partitionFields: dict = []) -> None:
    operationParameters = setOperationParameters(targetDf, df, schemaName, tableName, pkFields, columnsList, partitionFields)
    # perform the update statement based on the writeMode.
    try:
        writeToDeltaFunction = operationParameters[writeMode]
    except KeyError:
        print(f"Invalid write mode '{writeMode}' specified.")

    writeToDeltaFunction()
    return

# COMMAND ----------

def getTargetDeltaTable(schemaName: str, tableName: str, spark: SparkSession = spark) -> DataFrame:
    """
    Summary:
        Get the target Delta table as a PySpark DataFrame
    
    Args:
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.
        spark (SparkSession): Spark object to interact and retrieve Delta Table.
    
    Returns:
        targetDf (DeltaTable): Target Delta Table to be updated.
    """
    # dfSchema = df.schema.jsonValue()["fields"]

    targetDf = DeltaTable.forName(spark, f"{schemaName}.{tableName}")
    return targetDf
