from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from databricks.sdk.runtime import spark

def set_columns_list_as_dict(columns_list: list()) -> dict:
    columns_dict = {column: col(f"src.{column}") for column in columns_list}
    return columns_dict


# Implementations of the base classes above, providing variations on the create statements required to create schema and table objects for different environments.

# Below are Cleansed-level standard operations

def merge_delta(target_df: DataFrame, df: DataFrame, pk_fields: dict, columns_list: list(), partition_fields: dict = []) -> None:
    """
    Summary:
        Perform a Merge query for Incremental loading into the target Delta table for the Dataset.

    Args:
        target_df (DataFrame): Target PySpark DataFrame of the data to be merged into.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        pk_fields (dict): Dictionary of the primary key fields.
        columns_list (list): list of columns in source DataFrame.
        partition_fields (dict): Dictionary of the partition by fields.

    """
    columns_dict = set_columns_list_as_dict(columns_list)

    (
        target_df.alias("target_df")
        .merge(
            source=df.alias("src"),
            condition="\nAND ".join(f"src.{pk} = target_df.{pk}" for pk in pk_fields + partition_fields),
        )
        .whenNotMatchedInsert(values=columns_dict)
        .whenMatchedUpdate(set=columns_dict)
        .execute()
    )
    return

def insert_delta(df: DataFrame, schema_name: str, table_name: str) -> None:
    """
    Summary:
        Perform an Insert query for appending data to the existing target Delta table for the Dataset.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("append").insertInto(f"{schema_name}.{table_name}")
    return

def overwrite_delta(df: DataFrame, schema_name: str, table_name: str) -> None:
    """
    Summary:
        Perform an Overwrite query for the Dataset to replace data in an target Delta table.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{schema_name}.{table_name}")
    
    return

# Below are Curated-level operations to account for merging into tables with Identity generated surrogate key columns.
def overwrite_delta_surrogate_key(df: DataFrame, schema_name: str, table_name: str) -> None:
    """
    Summary:
        Perform an Overwrite query for the Dataset to replace data in an target Delta table.
    
    Args:
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.

    """
    df.write.format("delta").mode("overwrite").option("mergeSchema", "true").saveAsTable(f"{schema_name}.{table_name}")
    return

from functools import partial

def set_operation_parameters(target_df: DataFrame, df: DataFrame, schema_name: str, table_name: str, pk_fields: dict,columns_list: list(), partition_fields: dict) -> dict:
    """
    Summary:
        Create the parameters for each operation based on the payload values.
    
    Args:
        target_df (DataFrame): Target PySpark DataFrame of the data to be merged into.
        df (DataFrame): PySpark DataFrame of the data to be loaded.
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.
        pk_fields (dict): Dictionary of the primary key fields.
        partition_fields (dict): Dictionary of the partition by fields.
        columns_list (list): list of columns in source DataFrame.
    
    Returns:
        operation_parameters (dict): Dictionary mapping operation types to the parameter values used.
    """
    
    operation_parameters = {
        "merge": partial(merge_delta, target_df=target_df, df=df, pk_fields=pk_fields, columns_list=columns_list, partition_fields=partition_fields),
        # "insert": partial(insert_delta, df=df, schema_name=schema_name, table_name=table_name), # not currently supported
        "overwrite": partial(overwrite_delta, df=df, schema_name=schema_name, table_name=table_name),
        "overwriteSurrogateKey": partial(overwrite_delta_surrogate_key, df=df, schema_name=schema_name, table_name=table_name),
    }
    return operation_parameters


def write_to_delta_executor(write_mode: str, target_df: DataFrame, df: DataFrame, schema_name: str, table_name: str, pk_fields: dict, columns_list: list(), partition_fields: dict = []) -> None:
    operation_parameters = set_operation_parameters(target_df, df, schema_name, table_name, pk_fields, columns_list, partition_fields)
    # perform the update statement based on the write_mode.
    try:
        write_to_delta_function = operation_parameters[write_mode]
    except KeyError:
        raise KeyError(f"Invalid write mode '{write_mode}' specified.")

    write_to_delta_function()
    return


def get_target_delta_table(schema_name: str, table_name: str, spark: SparkSession = spark) -> DataFrame:
    """
    Summary:
        Get the target Delta table as a PySpark DataFrame
    
    Args:
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.
        spark (SparkSession): Spark object to interact and retrieve Delta Table.
    
    Returns:
        target_df (DeltaTable): Target Delta Table to be updated.
    """
    # dfSchema = df.schema.jsonValue()["fields"]
    try:
        return DeltaTable.forName(spark, f"{schema_name}.{table_name}")
    except Exception as e:
        print(e)
        raise Exception(f'Exception {e} occurred.')

