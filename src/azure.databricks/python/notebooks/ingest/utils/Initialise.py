# Databricks notebook source
# Set abfss initialisation
# Set abfss paths

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
