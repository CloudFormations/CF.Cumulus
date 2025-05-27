
from delta.tables import *
from pyspark.sql.functions import col
from databricks.sdk.runtime import spark


# Variations of required the create statements required to create schema and table objects for different environments.
def create_generic_schema_sql(schema_name: str) -> str:
    create_sql = f"""
    CREATE SCHEMA {schema_name}
    """
    return create_sql


def create_table_as_select_sql(schema_name: str,
                    table_name: str,
                    location: str, 
                    partition_fields_sql: str,
                    temp_view_name: str) -> str:

    create_sql = f"""
        CREATE TABLE {schema_name}.{table_name} 
        LOCATION '{location}'
        {partition_fields_sql}AS SELECT * FROM {temp_view_name}
        """
    return create_sql

def create_generic_table_sql(schema_name: str, table_name:str, location:str, partition_fields_sql: str, columns_string: str, surrogate_key: str, replace: bool) -> str:

    createStatement = "CREATE TABLE IF NOT EXISTS"
    if replace:
        createStatement = "CREATE OR REPLACE TABLE"
    
    surrogate_keyStatement = ""
    if surrogate_key != "":
        surrogate_keyStatement = f"{surrogate_key} BIGINT GENERATED ALWAYS AS IDENTITY,"

    create_sql = f"""
    {createStatement} {schema_name}.{table_name} (
        {surrogate_keyStatement}
        {columns_string}
    )
    USING DELTA
    LOCATION '{location}'
    {partition_fields_sql}
    """

    return create_sql

# Supported Schema mappings
SCHEMAS = {
    "cleansed": create_generic_schema_sql,
    "curated": create_generic_schema_sql,
    # Unity Catalog variations
}
# Supported Table mappings
TABLES = {
    "cleansed": create_table_as_select_sql,
    "curated": create_generic_table_sql,
    # Unity Catalog variations
}

def create_object(create_sql: str) -> None:
    """Create the Delta object being processed."""
    spark.sql(create_sql)
    return

def set_delta_table_location(schema_name: str, table_name: str, abfss_path: str) -> str:
    return f'{abfss_path}{schema_name}/{table_name}'


def format_columns_sql(columns_list: list(), typeList: list()) -> str:
    columns_string = ""
    for colName, colType in zip(columns_list, typeList): 
        columns_string += f"`{colName}` {colType}, "
        # print(colName, colType)

    return columns_string[:-2]


# def set_table_parameters_restore(schema_name:str, table_name: str, location: str, partition_fields_sql:str, temp_view_name: str, columns_string:str, surrogate_key: str, replace: bool) -> dict:
#     """
#     Summary:
#         Create the parameters for each table creation statement based on the payload values.
    
#     Args:
#         schema_name (str): Name of the schema the dataset belongs to.
#         table_name (str): Name of the target table for the dataset.
#         location (str): Path to the target Delta Table.
#         pk_fields (dict): Dictionary of the primary key fields.
#         partition_fields (dict): Dictionary of the partition by fields.
        
#     Cleansed Args:
#         temp_view_name (str): Temporary view as source dataset.

#     Curated Args:
#         partition_fields_sql (str): String of the partition fields SQL statement.
#         columns_string (str): String of the formatted columns for table creation.
#         surrogate_key (str): String name of the surrogate key to be used in table.
#         replace (bool): Boolean value to determine type of CREATE statement.

#     Returns:
#         table_parameters (dict): Dictionary mapping operation types to the parameter values used.
#     """

#     table_parameters = {
#         "cleansed": create_table_as_select_sql(schema_name, table_name, location, partition_fields_sql, temp_view_name),
#         "curated": create_generic_table_sql(schema_name, table_name, location, partition_fields_sql, columns_string, surrogate_key, replace)
#     }
#     return table_parameters

def set_table_parameters(schema_name:str, table_name: str, location: str, partition_fields_sql:str, columns_string:str, surrogate_key: str, replace: bool) -> dict:
    """
    Summary:
        Create the parameters for each table creation statement based on the payload values.
    
    Args:
        schema_name (str): Name of the schema the dataset belongs to.
        table_name (str): Name of the target table for the dataset.
        location (str): Path to the target Delta Table.
        partition_fields_sql (str): String of the partition fields SQL statement.
        columns_string (str): String of the formatted columns for table creation.
        surrogate_key (str): String name of the surrogate key to be used in table.
        replace (bool): Boolean value to determine type of CREATE statement.

    Returns:
        table_parameters (dict): Dictionary mapping operation types to the parameter values used.
    """

    table_parameters = {
        "cleansed": create_generic_table_sql(schema_name, table_name, location, partition_fields_sql, columns_string, surrogate_key, replace),
        "curated": create_generic_table_sql(schema_name, table_name, location, partition_fields_sql, columns_string, surrogate_key, replace),
    }
    return table_parameters


def create_schema(container_name: str, schema_name: str) -> None:
    # create the schema based on the container
    try:
        create_schema_sql_function = SCHEMAS[container_name]
    except KeyError:
        print(f"Invalid container name '{container_name}' specified.")
    create_schema_sql = create_schema_sql_function(schema_name=schema_name)
    create_object(create_schema_sql)
    print('Schema created.')
    return

def create_table(container_name: str, schema_name: str, table_name: str, location: str, partition_fields_sql: str, columns_string: str = None, surrogate_key: str = "", replace: bool = None) -> None:

    table_parameters = set_table_parameters(schema_name, table_name, location, partition_fields_sql, columns_string, surrogate_key, replace)

    # create the table based on the parameters
    try:
        # create_table_sql_function = TABLES[container_name]
        create_table_sql_function = table_parameters[container_name]
    except KeyError:
        raise KeyError(f"Invalid container name '{container_name}' specified.")
        
    create_table_sql = create_table_sql_function
    print()
    create_object(create_table_sql)
    print('Table Created')
    return
