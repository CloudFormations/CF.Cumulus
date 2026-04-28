from databricks.sdk.runtime import spark
from pyspark.sql.functions import col

def get_operation_metrics(schema_name: str, table_name: str, output: dict) -> dict:
    """
    Summary:
        Query the history of the Delta table to get the operational metrics of the merge, append, insert transformation.
    
    Args:
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.
        output (dict): Dictionary of metrics to be saved for logging purposes. 

    """
    operation_metrics = (
        spark.sql(f"DESCRIBE HISTORY {schema_name}.{table_name}")
        .orderBy(col("version").desc())
        .limit(1)
        .collect()[0]["operationMetrics"]
    )
    for metric, value in operation_metrics.items():
        output[f"mergeMetrics.{metric}"] = int(value)
    return output
