# Databricks notebook source
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# COMMAND ----------

# Variations of required the create statements required to create schema and table objects for different environments.
def createGenericSchemaSQL(schemaName: str) -> str:
    createSQL = f"""
    CREATE SCHEMA {schemaName}
    """
    return createSQL

def createGenericTableSQL(tempViewName: str,
                    schemaName: str,
                    tableName: str,
                    location: str, 
                    partitionFieldsSQL: str) -> str:

    createSQL = f"""
        CREATE TABLE {schemaName}.{tableName} 
        LOCATION '{location}'
        {partitionFieldsSQL}AS SELECT * FROM {tempViewName}
        """
    return createSQL


# COMMAND ----------

# Supported Schema mappings
SCHEMAS = {
    "cleansed": createGenericSchemaSQL,
    #"curated": createGenericSchemaSQL,
    # Unity Catalog variations
}
# Supported Table mappings
TABLES = {
    "cleansed": createGenericTableSQL,
    #"curated": createGenericTableSQL,
    # Unity Catalog variations
}

# COMMAND ----------

def createObject(createSQL: str) -> None:
    """Create the Delta object being processed."""
    spark.sql(createSQL)
    return

# COMMAND ----------

def setDeltaTableLocation(schemaName: str, tableName: str, abfssPath: str) -> str:
    return f'{abfssPath}{schemaName}/{tableName}'

# COMMAND ----------

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

def createTable(containerName: str, tempViewName: str, schemaName: str, tableName: str, location: str, partitionFieldsSQL: str) -> None:
    # create the table based on the parameters
    try:
        createTableSQLFunction = TABLES[containerName]
    except KeyError:
        print(f"Invalid container name '{containerName}' specified.")
    
    createTableSQL = createTableSQLFunction(tempViewName=tempViewName, schemaName=schemaName, tableName=tableName, location=location, partitionFieldsSQL=partitionFieldsSQL)
    createObject(createTableSQL)
    print('Table Created')
    return

# COMMAND ----------


