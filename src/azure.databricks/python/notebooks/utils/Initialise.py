from databricks.sdk.runtime import dbutils, spark

# Set abfss initialisation
# Set abfss paths
# Check abfss exists

def set_abfss_spark_config(account_key_secret_name:str, storage_name: str) -> None:
    """
    Set the Spark configuration for the ABFSS link to a storage account.

    Args:
        account_key_secret_name (str): The Azure Key Vault Secret name for the storage account.
        storage_name (str): The ADLS storage account name. 
    """
    account_key = dbutils.secrets.get(scope = "CumulusScope01", key = account_key_secret_name)
    spark.conf.set(
        f"fs.azure.account.key.{storage_name}.dfs.core.windows.net",
        account_key
    )
    return

def set_abfss_path(storage_name: str, container_name: str) -> str:
    """
    Set the ABFSS path of the container as a string.

    Args:
        storage_name (str): The ADLS storage account name.
        container_name (str): The container created within the ADLS storage location.
 
    """
    return f"abfss://{container_name}@{storage_name}.dfs.core.windows.net/"

# abfss check path exists in dbutils
def check_abfss(abfss_path:str) -> None:
    """
    Checks the ABFSS path of the container and raises an error if it does not exist.
 
    Args:
        abfss_path (str): The abfss path of the ADLS storage account container.
 
    """
    try:
        files_in_path = dbutils.fs.ls(abfss_path)
        print(f'Abfss path {abfss_path} exists. {len(files_in_path)} files found at first level.')
    except Exception: 
        raise ValueError('Storage location not accessible. Please check ADLS location exists, the Databricks account has access and no typing mistakes are present.')

    return
