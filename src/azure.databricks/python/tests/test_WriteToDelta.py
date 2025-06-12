import pytest
from functools import partial
from pyspark.sql import SparkSession
from notebooks.utils.WriteToDelta import set_operation_parameters, merge_delta, overwrite_delta, write_to_delta_executor, get_target_delta_table

@pytest.fixture(scope="module")
def spark():
    return SparkSession.builder.master("local").appName("PyTest").getOrCreate()

@pytest.fixture
def test_data(spark):
    target_df = spark.createDataFrame([], schema="id INT, name STRING")
    df = spark.createDataFrame([], schema="id INT, name STRING")
    return target_df, df

@pytest.fixture
def operation_parameters(test_data):
    target_df, df = test_data
    pk_fields = {"id": "int"}
    partition_fields = {}
    columns_list = ["id", "name"]
    schema_name = "test_schema"
    table_name = "test_table"

    return set_operation_parameters(target_df, df, schema_name, table_name, pk_fields, columns_list, partition_fields)

def set_columns_list_as_dict():
    columns_list = ['col1', 'col2']
    actual = set_columns_list_as_dict(columns_list)
    expected = {'col1': 'src.col1', 'col2': 'src.col2'}
    assert actual == expected


def test_set_operation_parameters_merge_partial(operation_parameters):
    merge_partial = operation_parameters["merge"]
    assert merge_partial.func is merge_delta
    keywords_expected = {
        "target_df": merge_partial.keywords["target_df"],
        "df": merge_partial.keywords["df"],
        "pk_fields": merge_partial.keywords["pk_fields"],
        "columns_list": merge_partial.keywords["columns_list"],
        "partition_fields": merge_partial.keywords["partition_fields"]
    }
    assert merge_partial.keywords == keywords_expected

def test_set_operation_parameters_overwrite_partial(operation_parameters):
    overwrite_partial = operation_parameters["overwrite"]
    assert overwrite_partial.func is overwrite_delta
    assert overwrite_partial.keywords == {
        "df": overwrite_partial.keywords["df"],
        "schema_name": overwrite_partial.keywords["schema_name"],
        "table_name": overwrite_partial.keywords["table_name"]
    }

    keywords_expected = {
        "df": overwrite_partial.keywords["df"],
        "schema_name": overwrite_partial.keywords["schema_name"],
        "table_name": overwrite_partial.keywords["table_name"]
    }
    assert overwrite_partial.keywords == keywords_expected

def test_write_to_delta_executor_invalid_write_mode(test_data):
    write_mode = 'invalid'
    target_df, df = test_data
    schema_name = "test_schema"
    table_name = "test_table"
    pk_fields = {"id": "int"}
    columns_list = ["id", "name"]
    partition_fields = {}
    with pytest.raises(KeyError):

        write_to_delta_executor(write_mode, target_df, df, schema_name, table_name, pk_fields, columns_list, partition_fields)


# Requires unit testing merge_delta, overwrite_delta first, with delta schema, table creation + tear down.
# def test_write_to_delta_executor_overwrite_write_modes(operation_parameters, test_data):
#     target_df, df = test_data
#     pk_fields = {"id": "int"}
#     partition_fields = {}
#     columns_list = ["id", "name"]
#     schema_name = "test_schema"
#     table_name = "test_table"

#     write_mode = "overwrite"

#     func_partial = operation_parameters[write_mode]

#     assert func_partial.func in [merge_delta, overwrite_delta]

#     write_to_delta_executor(write_mode, target_df, df, schema_name, table_name, pk_fields, columns_list, partition_fields)


# def test_get_target_delta_table(spark):
#     schema_name = "test_schema"
#     table_name = "test_table"
#     actual = get_target_delta_table(schema_name, table_name, spark)
#     expected = ''
#     assert actual == expected