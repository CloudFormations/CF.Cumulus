import json
from datetime import datetime
from databricks.sdk.runtime import spark


# check load type in 'F' or 'I' currently supported
def check_load_action(load_action: str) -> None:
    """
    Checks the load type provided to prevent unsupported load types occurring.
    Currently supports Full ('F') and Incremental ('I') loads.
 
    Args:
        load_action (str): The load type supplied from the payload.  
    """

    load_action_allowed_values = ['F','I']

    if load_action in load_action_allowed_values:
        print(f'Success, load type = {load_action}')
    elif load_action not in load_action_allowed_values: 
        raise ValueError(f'Load Type of {load_action} not yet supported in cleansed layer logic. Please review.')
    else:
        raise Exception('Unexpected state.')
    
    return

# For incremental loads we require primary keys to be used in the merge criteria.
def check_merge_and_pk_conditions(load_action: str, pk_list: list()) -> None:
    """
    Checks the combination of load type and primary key values providedprovided to prevent unsupported load types occurring.
    Currently supports Full ('F') and Incremental ('I') loads.
 
    Args:
        load_action (str): The load type supplied from the payload.  
        pk_list (list): The primary keys supplied from the payload.
    """
    if load_action.upper() == "I" and len(pk_list) > 0:
        print(f'Incremental loading configured with primary/business keys. This is a valid combination.')
    elif load_action.upper() == "F" and len(pk_list) > 0:
        print(f'Full loading configured with primary/business keys. This is a valid combination.')    
    elif load_action.upper() == "F" and len(pk_list) == 0:
        print(f'Full loading configured with no primary/business keys. This is a valid combination, assuming no subsequent incremental loads are due to take place.')
    elif load_action.upper() == "I" and len(pk_list) == 0:
        raise ValueError(f'Incremental loading configured with no primary/business keys. This is not a valid combination and will result in merge failures as no merge criteria can be specified.')
    else:
        raise Exception('Unexpected state.')


def check_container_name(container_name: str) -> None:
    containers = [
        'raw',
        'cleansed',
        'curated',
    ]
    if container_name in containers:
        print(f'container name {container_name} is supported.')
    elif container_name not in containers:
        raise ValueError(f"Container name '{container_name}' not supported.")
    else:
        raise Exception('Unexpected state.')




def check_exists_delta_schema(schema_name: str) -> bool:
    """
    Check the spark catalog to see if the provided Delta schema exists.
    If a table does not exist, it will be created as part of the execution notebook.
 
    Args:
        schema_name (str): The schema name the dataset belongs to.
    """
    try:
        schema_exists = spark.catalog.databaseExists(schema_name)
    except Exception:
        raise SyntaxError('Syntax error in schema name provided. Please review no erroneous characters, such as " " are included.')

    if (schema_exists == True):
        print('Schema exists. No action required.')
    elif (schema_exists == False):
        print('Schema not found. Schema will be populated as part of this process.')
    else:
        raise Exception('Unexpected state.')
    return schema_exists

def set_table_path(schema_name: str, table_name: str) -> str:
    """
    Concatenates the schema name and table name of the dataset to produce the table path in Hive storage.
    Contains checks for '.' characters in the schema and table names, as this is not allowed. Raise an error in this case.
 
    Args:
        schema_name (str): The schema name the dataset belongs to.
        table_name (str): The table name the dataset is created with.
 
    Returns:
        str: A 'dot' separated concatenation of schema and table name.
    """

    if '.' in schema_name:
        raise ValueError('Reserved character ''.'' found in the schema_name parameter: {schema_name}. Please review metadata value provided and correct as required' )

    if '.' in table_name:
        raise ValueError('Reserved character ''.'' found in the table_name parameter: {table_name}. Please review metadata value provided and correct as required' )

    return f'{schema_name}.{table_name}'


# Confirm if a Delta table exists and is required to exist given the load Action being executed.
def check_exists_delta_table(table_path: str, load_action: str, load_type: str) -> bool:
    """
    Check the spark catalog to see if a Delta table exists at the provided location.
    If a table does not exist, and is required to exist for the load_action specified, an error will be raised.
 
    Args:
        table_path (str): The path for the Delta table for the Dataset. This only requires the schema_name.table_name information, and is separate from the full ADLS path. 
        load_action (str): The load Action being run. Different load actions will determine if an error will occur if no (cleansed) Dataset Delta table is found.
    """

    try:
        table_exists = spark.catalog.tableExists(table_path)
    except Exception:
        raise SyntaxError('Syntax error in table name provided. Please review no erroneous characters, such as " " are included.')

    if (table_exists == True) and (load_action == 'I'):
        print('Table exists. No action required.')
    elif (table_exists == True) and (load_action == 'F') and (load_type == 'I'):
        raise ValueError('Table found but running full load for Dataset which supports incremental load. Please confirm that this is expected.')
    elif (table_exists == True) and (load_action == 'F') and (load_type == 'F'):
        print('Table found but running full load for Dataset which only supports full loads. This will be overwritten, as expected.')
    elif (table_exists == False) and (load_action == 'F'):
        print('Table not found. Full load being run, table will be created by default as part of this process.')
    elif (table_exists == False) and (load_action == 'I'):
        raise ValueError('Table not found, raise error.')
    else:
        raise Exception('Unexpected state.')

    return table_exists



# Compare the latest load date for the cleansed table with the load date of the raw file.
# Check nullable condition for each parameter
# manual_override may have some quirks to historic delta loads being reapplied. We possibly need to use time-travel or something else in delta to achieve the effect.
def compare_raw_load_vs_last_cleansed_date(raw_last_load_date: datetime.date , cleansed_last_load_date: datetime.date, manual_override: bool = False) -> None:
    """
    Check that the load date provided in the payload, which comes from the hierarchical folder path in raw, is not more recent than the last runtime of the ingestion into the merged cleansed dataset. If it does, raise an error for investigation.
 
    Args:
        raw_last_load_date (datetime): The raw data load timestamp.
        cleansed_last_load_date (datetime): The transformation process timestamp for the dataset
        manual_override (bool): Manual override configuration, allowing users to manually load historic files on top of the current table
    """
    if raw_last_load_date is None:
        raise ValueError("Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate.")
    if cleansed_last_load_date is None:
        print('Cleansed has not been populated.') 
        # This should correspond with a full only, based on previous check condition, but possibly worth reviewing...
    elif (cleansed_last_load_date is not None):
        if (raw_last_load_date > cleansed_last_load_date):
            print('Raw file load date greater than the cleansed last run date. It is safe to load this file.')
        elif (raw_last_load_date == cleansed_last_load_date):
            print('Raw file load date equals than the cleansed last run date. It is safe to load this file.')
        # review case is accurate and appropriate in event of reapplying incrementals out-of-order
        elif (raw_last_load_date < cleansed_last_load_date) and (manual_override is True):
            print('Raw file load date less than the cleansed last run date. Manual override is selected, and this load historic is intended.')
        elif (raw_last_load_date < cleansed_last_load_date) and (manual_override is False):
            raise ValueError('Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.')
        else:
            raise Exception('Unexpected state.')
    else:
        raise Exception('Unexpected state.')

    return



