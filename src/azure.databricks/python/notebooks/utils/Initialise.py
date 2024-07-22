# Databricks notebook source
# Set abfss initialisation
# Set abfss paths
# Check abfss exists

# COMMAND ----------

def setAbfssSparkConfig(accountKeySecretName:str, storageName: str) -> None:
    """
    Set the Spark configuration for the ABFSS link to a storage account.

    Args:
        accountKeySecretName (str): The Azure Key Vault Secret name for the storage account.
        storageName (str): The ADLS storage account name. 
    """
    accountKey = dbutils.secrets.get(scope = "CumulusScope01", key = accountKeySecretName)
    spark.conf.set(
        f"fs.azure.account.key.{storageName}.dfs.core.windows.net",
        accountKey
    )
    return

# COMMAND ----------

def setAbfssPath(storageName: str, containerName: str) -> str:
    """
    Set the ABFSS path of the container as a string.

    Args:
        storageName (str): The ADLS storage account name.
        containerName (str): The container created within the ADLS storage location.
 
    """
    return f"abfss://{containerName}@{storageName}.dfs.core.windows.net/"

# COMMAND ----------

# abfss check path exists in dbutils
def checkAbfss(abfssPath:str) -> None:
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
