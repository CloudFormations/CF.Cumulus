from notebooks.utils.CheckPayloadFunctions import *
import unittest
import pytest
import time

@pytest.fixture
def setup_default_schema_name() -> str:
    return "unit_test_default_schema"

@pytest.fixture
def setup_default_schema():
    default_schema_name = "unit_test_default_schema"
    print("\nSetting up resources...")
    spark.sql(f"CREATE SCHEMA {default_schema_name}")
    yield default_schema_name  # Provide the data to the test
    
    # Teardown: Clean up resources (if any) after the test
    print("\nTearing down resources...")
    spark.sql(f"DROP SCHEMA {default_schema_name}")

@pytest.fixture
def setup_default_table():
    default_table_name = "unit_test_default_table"
    print("\nSetting up resources...")
    spark.sql(f"CREATE TABLE {default_table_name}")
    yield default_table_name  # Provide the data to the test
    
    # Teardown: Clean up resources (if any) after the test
    print("\nTearing down resources...")
    spark.sql(f"DROP TABLE {default_table_name}")


class TestCheckLoadAction(unittest.TestCase):
    def test_check_load_action_f(self) -> None:
        actual = check_load_action("F")
        expected = None
        self.assertEqual(actual,expected)

    def test_check_load_action_i(self) -> None:
        actual = check_load_action("I")
        expected = None
        self.assertEqual(actual,expected)
    
    def test_check_load_action_unallowed_string(self) -> None:
        with self.assertRaises(Exception) as context:
            check_load_action("Q")
        expected = f"Load Type of Q not yet supported in cleansed layer logic. Please review."
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            check_load_action("Q")

    def test_check_load_action_unallowed_none(self) -> None:
        with self.assertRaises(Exception) as context:
            check_load_action(None)
        expected = f"Load Type of None not yet supported in cleansed layer logic. Please review."
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            check_load_action(None)
    

class TestCheckMergeAndPKConditions(unittest.TestCase):
    def test_check_merge_and_pk_conditions_i_with_pks(self) -> None:
        actual = check_merge_and_pk_conditions("I", ["pk1"])
        expected = None
        self.assertEqual(actual,expected)

        actual2 = check_merge_and_pk_conditions("I", ["pk1","pk2"])
        expected2 = None
        self.assertEqual(actual2,expected2)

    def test_check_merge_and_pk_conditions_f_with_pks(self) -> None:
        actual = check_merge_and_pk_conditions("F", ["pk1"])
        expected = None
        self.assertEqual(actual,expected)

        actual = check_merge_and_pk_conditions("F", ["pk1","pk2"])
        expected = None
        self.assertEqual(actual,expected)

    def test_check_merge_and_pk_conditions_f_with_no_pks(self) -> None:
        actual = check_merge_and_pk_conditions("F", [])
        expected = None
        self.assertEqual(actual,expected)

    def test_check_merge_and_pk_conditions_i_with_no_pks(self) -> None:
        with self.assertRaises(ValueError) as context:
            check_merge_and_pk_conditions("I", [])
        expected = f"Incremental loading configured with no primary/business keys. This is not a valid combination and will result in merge failures as no merge criteria can be specified."
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(ValueError):
            check_merge_and_pk_conditions("I", [])
    
    def test_check_merge_and_pk_conditions_invalid_load_action(self) -> None:
        with self.assertRaises(Exception) as context1:
            check_merge_and_pk_conditions("W", [])
        expected1 = f"Unexpected state."
        self.assertTrue(expected1 in str(context1.exception))

        with pytest.raises(Exception):
            check_merge_and_pk_conditions("W", [])

        with self.assertRaises(Exception) as context2:
            check_merge_and_pk_conditions("A", ["pk1s"])
        expected2 = f"Unexpected state."
        self.assertTrue(expected2 in str(context2.exception))

        with pytest.raises(Exception):
            check_merge_and_pk_conditions("A", ["pk1s"])
    

class TestCheckContainerName(unittest.TestCase):
    def test_check_container_name_supported(self) -> None:
        actual_raw = check_container_name("raw")
        expected_raw = None
        self.assertEqual(actual_raw,expected_raw)

        actual_cleansed = check_container_name("cleansed")
        expected_cleansed = None
        self.assertEqual(actual_cleansed,expected_cleansed)

        actual_curated = check_container_name("curated")
        expected_curated = None
        self.assertEqual(actual_curated,expected_curated)
    
    def test_check_container_name_not_supported(self) -> None:
        with pytest.raises(ValueError):
            check_container_name('invalid_name')


def test_check_exists_delta_schema_syntax_error():
    non_existant_schema = f"unique_schema.name" #forbidden "dot" character
    with pytest.raises(SyntaxError):
        check_exists_delta_schema(non_existant_schema)

def test_check_exists_delta_schema_non_existant(setup_default_schema_name):
    non_existant_schema = setup_default_schema_name
    actual = check_exists_delta_schema(non_existant_schema)
    expected = False
    assert actual == expected

def test_check_exists_delta_schema_exists(setup_default_schema_name, setup_default_schema):
    default_schema_name = setup_default_schema
    actual = check_exists_delta_schema(default_schema_name)
    expected = True
    assert actual == expected

def test_set_table_path_valid():
    actual = set_table_path('schema_name', 'table_name')
    expected = 'schema_name.table_name'
    assert actual == expected

def test_set_table_path_invalid_schema():
    with pytest.raises(ValueError):
        set_table_path('schema.name', 'table_name')

def test_set_table_path_invalid_table():
    with pytest.raises(ValueError):
        set_table_path('schema_name', 'table.name')


def test_check_exists_delta_table_syntax_error():
    non_existant_table = f"unique_table name" #forbidden "dot" character
    with pytest.raises(SyntaxError):
        check_exists_delta_table(non_existant_table,'F','F')

    with pytest.raises(SyntaxError):
        check_exists_delta_table(non_existant_table,'I','I')

    with pytest.raises(SyntaxError):
        check_exists_delta_table(non_existant_table,'F','I')

def test_check_exists_delta_table_true_incremental_load(setup_default_table):
    default_table_name = setup_default_table
    actual = check_exists_delta_table(default_table_name, 'I', 'I')
    expected = True
    assert actual == expected

def test_check_exists_delta_table_true_full_load_action_incremental_type(setup_default_table):
    default_table_name = setup_default_table
    with pytest.raises(ValueError):
        check_exists_delta_table(default_table_name, 'F', 'I')

def test_check_exists_delta_table_true_full_load_action_full_type(setup_default_table):
    default_table_name = setup_default_table
    actual = check_exists_delta_table(default_table_name, 'F', 'F')
    expected = True
    assert actual == expected

def test_check_exists_delta_table_false_full_load_action():
    table_name = 'unit_test_non_existant_table_name'
    actual1 = check_exists_delta_table(table_name, 'F', 'F')
    expected1 = False
    assert actual1 == expected1

    actual2 = check_exists_delta_table(table_name, 'F', 'I')
    expected2 = False
    assert actual2 == expected2

def test_check_exists_delta_table_false_full_load_action():
    table_name = 'unit_test_non_existant_table_name'
    actual1 = check_exists_delta_table(table_name, 'F', 'F')
    with pytest.raises(ValueError):
        check_exists_delta_table(table_name, 'I', 'I')





class TestCompareRawLoadVsLastCleansedDate(unittest.TestCase):
    def test_compare_raw_load_vs_last_cleansed_date_raw_none(self) -> None:
        # Check condition holds for both ManualOverrideParameterValues (Default False)
        with self.assertRaises(Exception) as context:
            compare_raw_load_vs_last_cleansed_date(None, datetime(2024,1,1))
        expected = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(Exception) as context2:
            compare_raw_load_vs_last_cleansed_date(None, datetime(2024,1,1), False)
        expected2 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected2 in str(context2.exception))

        with self.assertRaises(Exception) as context3:
            compare_raw_load_vs_last_cleansed_date(None, datetime(2024,1,1), True)
        expected3 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected3 in str(context3.exception))
    
    def test_compare_raw_load_vs_last_cleansed_date_raw_cleansed_none(self) -> None:
        # Check condition holds for both ManualOverrideParameterValues (Default False)
        with self.assertRaises(Exception) as context:
            compare_raw_load_vs_last_cleansed_date(None, None)
        expected = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(Exception) as context2:
            compare_raw_load_vs_last_cleansed_date(None, None, False)
        expected2 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected2 in str(context2.exception))


        with self.assertRaises(Exception) as context3:
            compare_raw_load_vs_last_cleansed_date(None, None, True)
        expected3 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected3 in str(context3.exception))

    def test_compare_raw_load_vs_last_cleansed_date_cleansed_none(self) -> None:
        actual = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), None)
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), None, False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), None, True)
        expected3 = None
        self.assertEqual(actual3,expected3)

    def test_compare_raw_load_vs_last_cleansed_date_raw_gt_cleansed(self) -> None:
        actual = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,2), datetime(2024,1,1))
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,2), datetime(2024,1,1), False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,2), datetime(2024,1,1), True)
        expected3 = None
        self.assertEqual(actual3,expected3)
        
    def test_compare_raw_load_vs_last_cleansed_date_raw_eq_cleansed(self) -> None:
        actual = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,1))
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,1), False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,1), True)
        expected3 = None
        self.assertEqual(actual3,expected3)

    def test_compare_raw_load_vs_last_cleansed_date_raw_lt_cleansed_no_manual_override(self) -> None:
        with self.assertRaises(ValueError) as context:
            compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,2))
        expected = f"Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended."
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(ValueError) as context2:
            compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,2))
        expected2 = f"Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended."
        self.assertTrue(expected2 in str(context2.exception))

    def test_compare_raw_load_vs_last_cleansed_date_raw_lt_cleansed_manual_override(self) -> None:
        actual3 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,2), True)
        expected3 = None
        self.assertEqual(actual3,expected3)
    
   