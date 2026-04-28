from delta.tables import *
from pyspark.sql.functions import lit
from pyspark.sql.types import StringType

def check_zero_bytes(load_action: str, file_path: str) -> bool:
    """
    Summary:
        Confirm that the Raw file being read is not 0 bytes (empty and no header).
    
    Args:
        load_action (str): Action to take on the file, either 'F' for full load or 'I' for incremental load.
        file_path (str): File path to the Raw file in ADLS.

    Returns:
        state (bool): Boolean state of the check, True if file is not empty.
    """
    file_metadata = dbutils.fs.ls(file_path)
    file_size = file_metadata[0].size
    print(file_metadata)
    print(file_size)
    if file_size == 0 and load_action == 'F':
        raise ValueError(f'File is empty, full load running. Please check the initial load which populated the file at {file_path}.')
    elif file_size == 0 and load_action == 'I':
        print("File is empty, incremental load running. No action required as this is valid activity.")
        return False
    elif file_size > 0:
        print("File is not empty. No action required.")
        return True
    else:
        raise Exception("Unknown state. Raise error")

def check_df_size(df: DataFrame) -> bool:
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
        raise ValueError(f'Invalid rowcount returned from DataFrame. Value {df.count()}.')


def create_partition_fields_sql(partition_fields: list() = []) -> str:
    """
    Summary:
        Create the SQL statement to partition dataset by the partition fields specified in the Transformation payload.
    
    Args:
        partition_fields (dict): Dictionary of Attributes in the dataset to partition the Delta table by.
    
    Returns:
        partition_fields_sql (str): Spark SQL partition by clause containing the provided Attributes.
    """
    partition_fields_sql = ''
    if len(partition_fields) > 0:
        partition_fields_sql = "\nPARTITIONED BY (" + ",".join(f"{pf}" for pf in partition_fields) + ")\n"
    return partition_fields_sql

# For incremental loads or depending on source file format, columns may not be loaded to bronze, despite being specified in the schema. Example - reading entirely NULL columns from Dynamics 365 excludes these from the Parquet which is written.
def get_columns_not_in_schema(columns_list: list(), df: DataFrame) -> list():
    return [column for column in columns_list if column not in df.columns]

# Add to DataFrame as NULL columns
def set_null_column(df: DataFrame, column: str) -> DataFrame:
    return df.withColumn(column, lit(None).cast(StringType()))