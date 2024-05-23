# Databricks notebook source
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# COMMAND ----------

# Implementations of the base classes above, providing variations on the create statements required to create schema and table objects for different environments.
def mergeDelta(targetDf: DataFrame, df: DataFrame, pkFields: dict, partitionFields: dict = []) -> None:
    """
    Summary:
        Perform a Merge query for Incremental loading into the target Delta table for the Dataset.

    Args:
        targetDf (DataFrame): Target PySpark DataFrame of the data to be merged into.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        pkFields (dict): Dictionary of the primary key fields.
        partitionFields (dict): Dictionary of the partition by fields.

    """
    (
        targetDf.alias("targetDf")
        .merge(
            source=df.alias("src"),
            condition="\nAND ".join(f"src.{pk} = targetDf.{pk}" for pk in pkFields + partitionFields),
        )
        .whenNotMatchedInsertAll()
        .whenMatchedUpdateAll()
        .execute()
    )
    return

def insertDelta(targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str) -> None:
    """
    Summary:
        Perform an Insert query for appending data to the existing target Delta table for the Dataset.
    
    Args:
        targetDf (DataFrame): Target PySpark DataFrame of the data to be appended.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("append").insertInto(f"{schemaName}.{tableName}")
    return

def overwriteDelta(targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str) -> None:
    """
    Summary:
        Perform an Overwrite query for the Dataset to replace data in an target Delta table.
    
    Args:
        targetDf (DataFrame): Target PySpark DataFrame of the data to be overwritten.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("overwrite").insertInto(f"{schemaName}.{tableName}")
    return

# COMMAND ----------

# Dictionary object which can be extended for different Schema and Table creation functions, such as other medallion layers, such as curated, or Unity Catalog-backed SQL Statements for each layer.

OPERATIONS = {
    "merge": mergeDelta,
    # "insert": InsertDelta, # not currently supported
    "overwrite": overwriteDelta,
}

# COMMAND ----------

def setOperationParameters(targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str, pkFields: dict, partitionFields: dict) -> dict:
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
    
    Returns:
        OperationParameters (dict): Dictionary mapping operation types to the parameter values used.
    """

    operationParameters = {
        "merge": mergeDelta(targetDf, df, pkFields, partitionFields),
        # "insert": insertDelta(targetDf, df, schemaName, tableName), # not currently supported
        "overwrite": overwriteDelta(targetDf, df, schemaName, tableName),
    }
    return operationParameters

# COMMAND ----------

# def getTargetDeltaTable(df: DataFrame) -> DataFrame:
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

# COMMAND ----------

def writeToDeltaFunction(writeMode: str, targetDf: DataFrame, df: DataFrame, schemaName: str, tableName: str, pkFields: dict, partitionFields: dict = []) -> None:
    operationParameters = setOperationParameters(targetDf, df, schemaName, tableName, pkFields, partitionFields)

    # perform the update statement based on the writeMode.
    try:
        # writeToDeltaFunction = OPERATIONS[writeMode]
        # writeToDeltaParameters = operationParameters[writeMode]
        writeToDeltaFunction = operationParameters[writeMode]
    except KeyError:
        print(f"Invalid write mode '{writeMode}' specified.")
        
    writeToDeltaFunction
    return
