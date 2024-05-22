# Databricks notebook source
def getOperationMetrics(schemaName: str, tableName: str, output: dict) -> dict:
    """
    Summary:
        Query the history of the Delta table to get the operational metrics of the merge, append, insert transformation.
    
    Args:
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.
        output (dict): Dictionary of metrics to be saved for logging purposes. 

    """
    operationMetrics = (
        spark.sql(f"DESCRIBE HISTORY {schemaName}.{tableName}")
        .orderBy(col("version").desc())
        .limit(1)
        .collect()[0]["operationMetrics"]
    )
    for metric, value in operationMetrics.items():
        output[f"mergeMetrics.{metric}"] = int(value)
    return output
