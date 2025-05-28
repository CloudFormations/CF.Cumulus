import pyspark
import pytest
from notebooks.utils.CreateDeltaObjects import *

def test_create_generic_table_sql_basic() -> None:
    actual = create_generic_table_sql(schema_name='schema',table_name='table',location='adls/path',partition_fields_sql='',columns_string='`ID` INTEGER', surrogate_key='',replace=False)
    expected = """
    CREATE TABLE IF NOT EXISTS schema.table (
        `ID` INTEGER
    )
    USING DELTA
    LOCATION 'adls/path'
    """
    assert actual == expected

# def test_create_generic_table_sql_basic_multi_column() -> None:
#     actual = create_generic_table_sql(schema_name='schema',table_name='table',location='adls/path',partition_fields_sql='',columns_string='`ID` INTEGER, `NAME` STRING', surrogate_key='',replace=False)
#     expected = """
#     CREATE TABLE IF NOT EXISTS schema.table (
#         `ID` INTEGER,
#         `NAME` STRING
#     )
#     USING DELTA
#     LOCATION 'adls/path'
#     """
#     assert actual == expected

def test_format_columns_sql_single() -> None:
    actual = format_columns_sql(columns_list=['ID'], typeList=['INTEGER'])
    expected = "`ID` INTEGER"
    assert actual == expected

def test_format_columns_sql_multiple() -> None:
    actual = format_columns_sql(columns_list=['ID', 'NAME'], typeList=['INTEGER', 'STRING'])
    expected = "`ID` INTEGER, `NAME` STRING"
    assert actual == expected

