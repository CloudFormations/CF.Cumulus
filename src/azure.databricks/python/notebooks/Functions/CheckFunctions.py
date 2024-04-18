# Databricks notebook source
import json
from datetime import datetime

# Payload validity checks:

# check load type in 'F' or 'I' currently supported
def loadTypeCheck(loadType: str) -> None:
    """
    Checks the load type provided to prevent unsupported load types occurring.
    Currently supports Full ('F') and Incremental ('I') loads.
 
    Args:
        loadType (str): The load type supplied from the payload.  
    """

    loadTypeAllowedValues = ['F','I']

    if loadType in loadTypeAllowedValues:
        print(f'Success, load type = {loadType}')
    elif loadType not in loadTypeAllowedValues: 
        raise Exception(f'Load Type of {loadType} not yet supported in cleansed layer logic. Please review.')
    else:
        raise Exception('Unexpected state.')
    
    return



# abfss check path exists in dbutils
def abfssCheck(abfssPath:str) -> None:
    """
    Checks the ABFSS path of the container and raises an error if it does not exist.
 
    Args:
        abfssPath (str): The abfss path of the ADLS storage account container.
 
    """
    try:
        filesInPath = dbutils.fs.ls(abfssPath)
        print(f'Abfss path {abfssPath} exists. {len(filesInPath)} files found at first level.')
    except Exception: 
        raise Exception('Storage location not accessible. Please check ADLS location exists, the Databricks account has access and no typing mistakes are present.')

    return


def setTablePath(schemaName: str, tableName: str) -> str:
    """
    Concatenates the schema name and table name of the dataset to produce the table path in Hive storage.
    Contains checks for '.' characters in the schema and table names, as this is not allowed. Raise an error in this case.
 
    Args:
        schemaName (str): The schema name the dataset belongs to.
        tableName (str): The table name the dataset is created with.
 
    Returns:
        str: A 'dot' separated concatenation of schema and table name.
    """

    if '.' in schemaName:
        raise Exception('Reserved character ''.'' found in the schemaName parameter: {schemaName}. Please review metadata value provided and correct as required' )

    if '.' in tableName:
        raise Exception('Reserved character ''.'' found in the tableName parameter: {tableName}. Please review metadata value provided and correct as required' )

    return f'{schemaName}.{tableName}'


# Confirm if a Delta table exists and is required to exist given the load type being executed.
def deltaTableExistsCheck(tablePath: str, loadType: str) -> None:
    """
    Check the spark catalog to see if a Delta table exists at the provided location.
    If a table does not exist, and is required to exist for the loadType specified, an error will be raised.
 
    Args:
        tablePath (str): The path for the Delta table for the Dataset. This only requires the schemaName.tableName information, and is separate from the full ADLS path. 
        loadType (str): The load type being run. Different load types will determine if an error will occur if no (cleansed) Dataset Delta table is found.
    """

    try:
        tableExists = spark.catalog.tableExists(tablePath)
    except Exception:
        raise Exception('Syntax error in table name provided. Please review no erroneous characters, such as " " are included.')

    if (tableExists == True) and (loadType == 'I'):
        print('Table exists. No action required.')
    elif (tableExists == True) and (loadType == 'F'):
        raise Exception('Table found but running full load. Please confirm that this is expected.')
    elif (tableExists == False) and (loadType == 'F'):
        print('Table not found. Full load being run, table will be created by default as part of this process.')
    elif (tableExists == False) and (loadType == 'I'):
        raise Exception('Table not found, raise error.')
    else:
        raise Exception('Unexpected state.')

    return


# Compare the latest load date for the cleansed table with the load date of the raw file.
# Check nullable condition for each parameter
# manualOverride may have some quirks to historic delta loads being reapplied. We possibly need to use time-travel or something else in delta to achieve the effect.
def compareLoadVsLastCleansedDate(rawLoadDate: datetime.date , cleansedLastRunDate: datetime.date, manualOverride: bool = False) -> None:
    """
    Check that the load date provided in the payload, which comes from the hierarchical folder path in raw, is not more recent than the last runtime of the ingestion into the merged cleansed dataset. If it does, raise an error for investigation.
 
    Args:
        rawLoadDate (datetime): The raw data load timestamp.
        cleansedLastRunDate (datetime): The transformation process timestamp for the dataset
        manualOverride (bool): Manual override configuration, allowing users to manually load historic files on top of the current table
    """
    if rawLoadDate is None:
        raise Exception("Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate.")
    if cleansedLastRunDate is None:
        print('Cleansed has not been populated.') 
        # This should correspond with a full only, based on previous check condition, but possibly worth reviewing...

    # check how this behaves with Nones
    if (rawLoadDate > cleansedLastRunDate):
        print('Raw file load date greater than the cleansed last run date. It is safe to load this file.')
    # check how this behaves with Nones
    elif (rawLoadDate == cleansedLastRunDate):
        print('Raw file load date equals than the cleansed last run date. It is safe to load this file.')
    # review case is accurate and appropriate in event of reapplying incrementals out-of-order
    elif rawLoadDate < cleansedLastRunDate and (manualOverride is True):
        print('Raw file load date less than the cleansed last run date. Manual override is selected, and this load historic is intended.')
    elif rawLoadDate < cleansedLastRunDate and (manualOverride is False):
        raise Exception('Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.')
    else:
        raise Exception('Unexpected state.')

    return

