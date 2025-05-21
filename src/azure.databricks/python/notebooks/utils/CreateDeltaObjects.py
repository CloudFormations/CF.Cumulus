
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col


# Variations of required the create statements required to create schema and table objects for different environments.
def createGenericSchemaSQL(schemaName: str) -> str:
    createSQL = f"""
    CREATE SCHEMA {schemaName}
    """
    return createSQL


def createTableAsSelectSQL(schemaName: str,
                    tableName: str,
                    location: str, 
                    partitionFieldsSQL: str,
                    tempViewName: str) -> str:

    createSQL = f"""
        CREATE TABLE {schemaName}.{tableName} 
        LOCATION '{location}'
        {partitionFieldsSQL}AS SELECT * FROM {tempViewName}
        """
    return createSQL

def createGenericTableSQL(schemaName: str, tableName:str, location:str, partitionFieldsSQL: str, columnsString: str, surrogateKey: str, replace: bool) -> str:

    createStatement = "CREATE TABLE IF NOT EXISTS"
    if replace:
        createStatement = "CREATE OR REPLACE TABLE"
    
    surrogateKeyStatement = ""
    if surrogateKey != "":
        surrogateKeyStatement = f"{surrogateKey} BIGINT GENERATED ALWAYS AS IDENTITY,"

    createSQL = f"""
    {createStatement} {schemaName}.{tableName} (
        {surrogateKeyStatement}
        {columnsString}
    )
    USING DELTA
    LOCATION '{location}'
    {partitionFieldsSQL}
    """

    return createSQL

# Supported Schema mappings
SCHEMAS = {
    "cleansed": createGenericSchemaSQL,
    "curated": createGenericSchemaSQL,
    # Unity Catalog variations
}
# Supported Table mappings
TABLES = {
    "cleansed": createTableAsSelectSQL,
    "curated": createGenericTableSQL,
    # Unity Catalog variations
}

def createObject(createSQL: str) -> None:
    """Create the Delta object being processed."""
    spark.sql(createSQL)
    return

def setDeltaTableLocation(schemaName: str, tableName: str, abfssPath: str) -> str:
    return f'{abfssPath}{schemaName}/{tableName}'


def formatColumnsSQL(columnsList: list(), typeList: list()) -> str:
    columnsString = ""
    for colName, colType in zip(columnsList, typeList): 
        columnsString += f"`{colName}` {colType}, "
        # print(colName, colType)

    return columnsString[:-2]


# def setTableParametersRestore(schemaName:str, tableName: str, location: str, partitionFieldsSQL:str, tempViewName: str, columnsString:str, surrogateKey: str, replace: bool) -> dict:
#     """
#     Summary:
#         Create the parameters for each table creation statement based on the payload values.
    
#     Args:
#         schemaName (str): Name of the schema the dataset belongs to.
#         tableName (str): Name of the target table for the dataset.
#         location (str): Path to the target Delta Table.
#         pkFields (dict): Dictionary of the primary key fields.
#         partitionFields (dict): Dictionary of the partition by fields.
        
#     Cleansed Args:
#         tempViewName (str): Temporary view as source dataset.

#     Curated Args:
#         partitionFieldsSQL (str): String of the partition fields SQL statement.
#         columnsString (str): String of the formatted columns for table creation.
#         surrogateKey (str): String name of the surrogate key to be used in table.
#         replace (bool): Boolean value to determine type of CREATE statement.

#     Returns:
#         tableParameters (dict): Dictionary mapping operation types to the parameter values used.
#     """

#     tableParameters = {
#         "cleansed": createTableAsSelectSQL(schemaName, tableName, location, partitionFieldsSQL, tempViewName),
#         "curated": createGenericTableSQL(schemaName, tableName, location, partitionFieldsSQL, columnsString, surrogateKey, replace)
#     }
#     return tableParameters

def setTableParameters(schemaName:str, tableName: str, location: str, partitionFieldsSQL:str, columnsString:str, surrogateKey: str, replace: bool) -> dict:
    """
    Summary:
        Create the parameters for each table creation statement based on the payload values.
    
    Args:
        schemaName (str): Name of the schema the dataset belongs to.
        tableName (str): Name of the target table for the dataset.
        location (str): Path to the target Delta Table.
        partitionFieldsSQL (str): String of the partition fields SQL statement.
        columnsString (str): String of the formatted columns for table creation.
        surrogateKey (str): String name of the surrogate key to be used in table.
        replace (bool): Boolean value to determine type of CREATE statement.

    Returns:
        tableParameters (dict): Dictionary mapping operation types to the parameter values used.
    """

    tableParameters = {
        "cleansed": createGenericTableSQL(schemaName, tableName, location, partitionFieldsSQL, columnsString, surrogateKey, replace),
        "curated": createGenericTableSQL(schemaName, tableName, location, partitionFieldsSQL, columnsString, surrogateKey, replace),
    }
    return tableParameters


def createSchema(containerName: str, schemaName: str) -> None:
    # create the schema based on the container
    try:
        createSchemaSQLFunction = SCHEMAS[containerName]
    except KeyError:
        print(f"Invalid container name '{containerName}' specified.")
    createSchemaSQL = createSchemaSQLFunction(schemaName=schemaName)
    createObject(createSchemaSQL)
    print('Schema created.')
    return

def createTable(containerName: str, schemaName: str, tableName: str, location: str, partitionFieldsSQL: str, columnsString: str = None, surrogateKey: str = "", replace: bool = None) -> None:

    tableParameters = setTableParameters(schemaName, tableName, location, partitionFieldsSQL, columnsString, surrogateKey, replace)

    # create the table based on the parameters
    try:
        # createTableSQLFunction = TABLES[containerName]
        createTableSQLFunction = tableParameters[containerName]
    except KeyError:
        print(f"Invalid container name '{containerName}' specified.")
        
    createTableSQL = createTableSQLFunction
    print()
    createObject(createTableSQL)
    print('Table Created')
    return
