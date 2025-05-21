import pyspark
import pytest
from notebooks.utils.HelperFunctions import *
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, IntegerType, FloatType, StringType


# Start Spark Session as using .py file rather than notebook
@pytest.fixture
def spark() -> SparkSession:
    return SparkSession.builder \
                        .appName('unit-tests') \
                        .getOrCreate()

# Create sample DataFrame
@pytest.fixture
def sample_dataframe() -> DataFrame:
    schema = StructType([ \
    StructField("_c0",     IntegerType(), True), \
    StructField("col1",   FloatType(),   True), \
    ])

    data = [ (1, 0.23, "Ideal",   "E", "SI2", 61.5, 55, 326, 3.95, 3.98, 2.43 ), \
            (2, 0.21, "Premium", "E", "SI1", 59.8, 61, 326, 3.89, 3.84, 2.31 ) ]





class TestCreatePartitionFieldsSQL():
    def test_createPartitionFieldsSQL_single_column(self) -> None:
        actual = createPartitionFieldsSQL(['col1'])
        expected = "\nPARTITIONED BY (""col1"")\n"
        assert actual ==  expected

        actual2 = createPartitionFieldsSQL(['col2'])
        expected2 = "\nPARTITIONED BY (""col2"")\n"
        assert actual2 ==  expected2

    def test_createPartitionFieldsSQL_multi_columns(self) -> None:
        actual = createPartitionFieldsSQL(['col1','col2'])
        expected = "\nPARTITIONED BY (""col1"",""col2"")\n"
        assert actual ==  expected

        actual2 = createPartitionFieldsSQL(['col1','col2','col3'])
        expected2 = "\nPARTITIONED BY (""col1"",""col2"",""col3"")\n"
        assert actual2 ==  expected2
    
    def test_createPartitionFieldsSQL_empty_list(self) -> None:
        actual = createPartitionFieldsSQL([])
        expected = ""
        assert actual ==  expected