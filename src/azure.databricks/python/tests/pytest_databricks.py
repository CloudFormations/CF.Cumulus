# Databricks notebook source
# MAGIC %md Test runner for `pytest`

# COMMAND ----------
!cp ../requirements.txt ~/.
%pip install -r ~/requirements.txt


# COMMAND ----------

# pytest.main runs our tests directly in the notebook environment, providing
# fidelity for Spark and other configuration variables.
#
# A limitation of this approach is that changes to the test will be
# cache by Python's import caching mechanism.
#
# To iterate on tests during development, we restart the Python process 
# and thus clear the import cache to pick up changes.
dbutils.library.restartPython()

# COMMAND ----------

# pytest.main runs our tests directly in the notebook environment, providing
# fidelity for Spark and other configuration variables.
#
# A limitation of this approach is that changes to the test will be
# cache by Python's import caching mechanism.
#
# To iterate on tests during development, we restart the Python process 
# and thus clear the import cache to pick up changes.

import pytest
import os
import sys

# Change to the tests directory
os.chdir('/Workspace/Shared/UnitTest/files/tests')

# Add parent directory to Python path so 'notebooks' module can be found
parent_dir = '/Workspace/Shared/UnitTest/files/'
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

print(f"Current directory: {os.getcwd()}")
print(f"Python path includes: {parent_dir}")

# Skip writing pyc files on a readonly filesystem.
sys.dont_write_bytecode = True

retcode = pytest.main([".", "-v", "-p", "no:cacheprovider", "--import-mode=importlib"])

# Fail the cell execution if we have any test failures.
assert retcode == 0, 'The pytest invocation failed. See the log above for details.'

# COMMAND ----------


