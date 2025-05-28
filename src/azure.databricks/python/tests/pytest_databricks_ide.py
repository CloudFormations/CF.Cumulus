import pytest
import os
import sys

# Run all tests in the connected directory in the remote Databricks workspace.
# By default, pytest searches through all files with filenames ending with
# "_test.py" for tests. Within each of these files, pytest runs each function
# with a function name beginning with "test_".

# Get the path to the directory for this file in the workspace.
dir_root = os.path.dirname(os.path.realpath(__file__))
# Switch to the root directory.
os.chdir(dir_root)

# Skip writing .pyc files to the bytecode cache on the cluster.
sys.dont_write_bytecode = True

# Now run pytest from the root directory, using the
# arguments that are supplied by your custom run configuration in
# your Visual Studio Code project. In this case, the custom run
# configuration JSON must contain these unique "program" and
# "args" objects:
#
# ...
# {
#   ...
#   "program": "${workspaceFolder}/path/to/this/file/in/workspace",
#   "args": ["/path/to/_test.py-files"]
# }
# ...
#
retcode = pytest.main(sys.argv[1:])