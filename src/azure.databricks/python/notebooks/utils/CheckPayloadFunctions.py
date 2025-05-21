import json
from datetime import datetime


# check load type in 'F' or 'I' currently supported
def checkLoadAction(loadAction: str) -> None:
    """
    Checks the load type provided to prevent unsupported load types occurring.
    Currently supports Full ('F') and Incremental ('I') loads.
 
    Args:
        loadAction (str): The load type supplied from the payload.  
    """

    loadActionAllowedValues = ['F','I']

    if loadAction in loadActionAllowedValues:
        print(f'Success, load type = {loadAction}')
    elif loadAction not in loadActionAllowedValues: 
        raise Exception(f'Load Type of {loadAction} not yet supported in cleansed layer logic. Please review.')
    else:
        raise Exception('Unexpected state.')
    
    return

# For incremental loads we require primary keys to be used in the merge criteria.
def checkMergeAndPKConditions(loadAction:str, pkList: list()) -> None:
    """
    Checks the combination of load type and primary key values providedprovided to prevent unsupported load types occurring.
    Currently supports Full ('F') and Incremental ('I') loads.
 
    Args:
        loadAction (str): The load type supplied from the payload.  
        pkList (list): The primary keys supplied from the payload.
    """
    if loadAction.upper() == "I" and len(pkList) > 0:
        print(f'Incremental loading configured with primary/business keys. This is a valid combination.')
    elif loadAction.upper() == "F" and len(pkList) > 0:
        print(f'Full loading configured with primary/business keys. This is a valid combination.')    
    elif loadAction.upper() == "F" and len(pkList) == 0:
        print(f'Full loading configured with no primary/business keys. This is a valid combination, assuming no subsequent incremental loads are due to take place.')
    elif loadAction.upper() == "I" and len(pkList) == 0:
        raise ValueError(f'Incremental loading configured with no primary/business keys. This is not a valid combination and will result in merge failures as no merge criteria can be specified.')
    else:
        raise Exception('Unexpected state.')


def checkContainerName(containerName: str) -> None:
    containers = [
        'raw',
        'cleansed',
        'curated',
    ]
    if containerName in containers:
        print(f'container name {containerName} is supported.')
    elif containerName not in containers:
        raise ValueError(f"Container name '{containerName}' not supported.")
    else:
        raise Exception('Unexpected state.')




def checkExistsDeltaSchema(schemaName: str) -> bool:
    """
    Check the spark catalog to see if the provided Delta schema exists.
    If a table does not exist, it will be created as part of the execution notebook.
 
    Args:
        schemaName (str): The schema name the dataset belongs to.
    """
    try:
        schemaExists = spark.catalog.databaseExists(schemaName)
    except Exception:
        raise Exception('Syntax error in schema name provided. Please review no erroneous characters, such as " " are included.')

    if (schemaExists == True):
        print('Schema exists. No action required.')
    elif (schemaExists == False):
        print('Schema not found. Schema will be populated as part of this process.')
    else:
        raise Exception('Unexpected state.')
    return schemaExists

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


# Confirm if a Delta table exists and is required to exist given the load Action being executed.
def checkExistsDeltaTable(tablePath: str, loadAction: str, loadType: str) -> bool:
    """
    Check the spark catalog to see if a Delta table exists at the provided location.
    If a table does not exist, and is required to exist for the loadAction specified, an error will be raised.
 
    Args:
        tablePath (str): The path for the Delta table for the Dataset. This only requires the schemaName.tableName information, and is separate from the full ADLS path. 
        loadAction (str): The load Action being run. Different load ctions will determine if an error will occur if no (cleansed) Dataset Delta table is found.
    """

    try:
        tableExists = spark.catalog.tableExists(tablePath)
    except Exception:
        raise Exception('Syntax error in table name provided. Please review no erroneous characters, such as " " are included.')

    if (tableExists == True) and (loadAction == 'I'):
        print('Table exists. No action required.')
    elif (tableExists == True) and (loadAction == 'F') and (loadType == 'I'):
        raise Exception('Table found but running full load for Dataset which supports incremental load. Please confirm that this is expected.')
    elif (tableExists == True) and (loadAction == 'F') and (loadType == 'F'):
        print('Table found but running full load for Dataset which only supports full loads. This will be overwritten, as expected.')
    elif (tableExists == False) and (loadAction == 'F'):
        print('Table not found. Full load being run, table will be created by default as part of this process.')
    elif (tableExists == False) and (loadAction == 'I'):
        raise Exception('Table not found, raise error.')
    else:
        raise Exception('Unexpected state.')

    return tableExists



# Compare the latest load date for the cleansed table with the load date of the raw file.
# Check nullable condition for each parameter
# manualOverride may have some quirks to historic delta loads being reapplied. We possibly need to use time-travel or something else in delta to achieve the effect.
def compareRawLoadVsLastCleansedDate(rawLastLoadDate: datetime.date , cleansedLastLoadDate: datetime.date, manualOverride: bool = False) -> None:
    """
    Check that the load date provided in the payload, which comes from the hierarchical folder path in raw, is not more recent than the last runtime of the ingestion into the merged cleansed dataset. If it does, raise an error for investigation.
 
    Args:
        rawLastLoadDate (datetime): The raw data load timestamp.
        cleansedLastLoadDate (datetime): The transformation process timestamp for the dataset
        manualOverride (bool): Manual override configuration, allowing users to manually load historic files on top of the current table
    """
    if rawLastLoadDate is None:
        raise ValueError("Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate.")
    if cleansedLastLoadDate is None:
        print('Cleansed has not been populated.') 
        # This should correspond with a full only, based on previous check condition, but possibly worth reviewing...
    elif (cleansedLastLoadDate is not None):
        if (rawLastLoadDate > cleansedLastLoadDate):
            print('Raw file load date greater than the cleansed last run date. It is safe to load this file.')
        elif (rawLastLoadDate == cleansedLastLoadDate):
            print('Raw file load date equals than the cleansed last run date. It is safe to load this file.')
        # review case is accurate and appropriate in event of reapplying incrementals out-of-order
        elif (rawLastLoadDate < cleansedLastLoadDate) and (manualOverride is True):
            print('Raw file load date less than the cleansed last run date. Manual override is selected, and this load historic is intended.')
        elif (rawLastLoadDate < cleansedLastLoadDate) and (manualOverride is False):
            raise ValueError('Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.')
        else:
            raise Exception('Unexpected state.')
    else:
        raise Exception('Unexpected state.')

    return



