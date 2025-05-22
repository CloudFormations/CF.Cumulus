import pyspark
import pytest
from notebooks.utils.HelperFunctions import *
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, IntegerType, FloatType, StringType


# Start Spark Session as using .py file rather than notebook
@pytest.fixture
def spark():
    spark = SparkSession.builder.appName("unit-tests").getOrCreate()
    yield spark

def test_check_df_size_true(spark) -> None:
    source_data1 = [("John", 25)]
    df1 = spark.createDataFrame(source_data1, ["name", "age"])
    actual1 = check_df_size(df1)
    expected1 = True

    source_data2 = [("John", 25), ("Alice", 30), ("Bob", 35)]
    df2 = spark.createDataFrame(source_data2, ["name", "age"])
    actual2 = check_df_size(df2)
    expected2 = True

    schema = StructType([
        StructField('Name', StringType(), True),
        StructField('Age', StringType(), True),
    ])
    source_data3 = [("John", 25), ("Alice", 30), ("Bob", 35)]
    df3 = spark.createDataFrame(source_data2, schema)
    actual3 = check_df_size(df3)
    expected3 = True

    assert actual1 == expected1
    assert actual2 == expected2
    assert actual3 == expected3

def test_check_df_size_false(spark) -> None:
    schema = StructType([
        StructField('Name', StringType(), True),
        StructField('Age', StringType(), True),
    ])

    source_data1 = []
    df1 = spark.createDataFrame(source_data1, schema)
    actual1 = check_df_size(df1)
    expected1 = False

    source_data2 = []
    df2 = spark.createDataFrame([], schema)
    actual2 = check_df_size(df2)
    expected2 = False

    assert actual1 == expected1
    assert actual2 == expected2


class TestCreatePartitionFieldsSQL():
    def test_create_partition_fields_sql_single_column(self) -> None:
        actual = create_partition_fields_sql(['col1'])
        expected = "\nPARTITIONED BY (""col1"")\n"
        assert actual ==  expected

        actual2 = create_partition_fields_sql(['col2'])
        expected2 = "\nPARTITIONED BY (""col2"")\n"
        assert actual2 ==  expected2

    def test_create_partition_fields_sql_multi_columns(self) -> None:
        actual = create_partition_fields_sql(['col1','col2'])
        expected = "\nPARTITIONED BY (""col1"",""col2"")\n"
        assert actual ==  expected

        actual2 = create_partition_fields_sql(['col1','col2','col3'])
        expected2 = "\nPARTITIONED BY (""col1"",""col2"",""col3"")\n"
        assert actual2 ==  expected2
    
    def test_create_partition_fields_sql_empty_list(self) -> None:
        actual = create_partition_fields_sql([])
        expected = ""
        assert actual ==  expected