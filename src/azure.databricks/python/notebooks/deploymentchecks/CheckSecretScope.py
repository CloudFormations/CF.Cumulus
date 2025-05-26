# Databricks notebook source

# COMMAND ----------

# Set-up Secret Scope Name
# Default Value
scope_name = "CumulusScope01"

# COMMAND ----------

# Check Secret Scope exists
try:
    if any(scope.name == scope_name for scope in dbutils.secrets.listScopes()):
        print(f"Secret scope '{scope_name}' exists.")
    else:
        raise ValueError("Secret scope '{scope_name}' does not exist. Please ensure this is created for successful integration between Databricks and Azure Key Vault.")
except Exception as e:
    raise ValueError(f"Unexpected error occurred when accessing secret scope '{scope_name}: {str(e)}")

# COMMAND ----------

from py4j.protocol import Py4JJavaError

# Check visibility of secrets in Secret Scope:
try:
    if len(dbutils.secrets.list(scope_name)) > 0:
        print("Secrets in scope '{scope_name}' are visible.")
    elif len(dbutils.secrets.list(scope_name)) == 0:
        raise ValueError("No secrets in scope '{scope_name}'. Please ensure secrets are created for successful integration between Databricks and Azure Key Vault.")
except Py4JJavaError as e:
    raise PermissionError(f"Secrets in scope '{scope_name}' are not visible. Please ensure secrets are created for successful integration between Databricks and Azure Key Vault.")
except Exception as e:
    raise ValueError(f"Unexpected error occurred when accessing secrets in scope '{scope_name}: {str(e)}")
