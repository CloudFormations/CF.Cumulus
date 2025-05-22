from notebooks.utils.CheckPayloadFunctions import *
import unittest
import pytest


class TestCheckLoadAction(unittest.TestCase):
    def test_check_load_action_f(self) -> None:
        actual = check_load_action('F')
        expected = None
        self.assertEqual(actual,expected)

    def test_check_load_action_i(self) -> None:
        actual = check_load_action('I')
        expected = None
        self.assertEqual(actual,expected)
    
    def test_check_load_action_unallowed_string(self) -> None:
        with self.assertRaises(Exception) as context:
            check_load_action('Q')
        expected = f'Load Type of Q not yet supported in cleansed layer logic. Please review.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            check_load_action('Q')

    def test_check_load_action_unallowed_none(self) -> None:
        with self.assertRaises(Exception) as context:
            check_load_action(None)
        expected = f'Load Type of None not yet supported in cleansed layer logic. Please review.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            check_load_action(None)
    

class TestCheckMergeAndPKConditions(unittest.TestCase):
    def test_check_merge_and_pk_conditions_i_with_pks(self) -> None:
        actual = check_merge_and_pk_conditions('I', ['pk1'])
        expected = None
        self.assertEqual(actual,expected)

        actual2 = check_merge_and_pk_conditions('I', ['pk1','pk2'])
        expected2 = None
        self.assertEqual(actual2,expected2)

    def test_check_merge_and_pk_conditions_f_with_pks(self) -> None:
        actual = check_merge_and_pk_conditions('F', ['pk1'])
        expected = None
        self.assertEqual(actual,expected)

        actual = check_merge_and_pk_conditions('F', ['pk1','pk2'])
        expected = None
        self.assertEqual(actual,expected)

    def test_check_merge_and_pk_conditions_f_with_no_pks(self) -> None:
        actual = check_merge_and_pk_conditions('F', [])
        expected = None
        self.assertEqual(actual,expected)

    def test_check_merge_and_pk_conditions_i_with_no_pks(self) -> None:
        with self.assertRaises(ValueError) as context:
            check_merge_and_pk_conditions('I', [])
        expected = f'Incremental loading configured with no primary/business keys. This is not a valid combination and will result in merge failures as no merge criteria can be specified.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(ValueError):
            check_merge_and_pk_conditions('I', [])
    
    def test_check_merge_and_pk_conditions_invalid_load_action(self) -> None:
        with self.assertRaises(Exception) as context1:
            check_merge_and_pk_conditions('W', [])
        expected1 = f'Unexpected state.'
        self.assertTrue(expected1 in str(context1.exception))

        with pytest.raises(Exception):
            check_merge_and_pk_conditions('W', [])

        with self.assertRaises(Exception) as context2:
            check_merge_and_pk_conditions('A', ['pk1s'])
        expected2 = f'Unexpected state.'
        self.assertTrue(expected2 in str(context2.exception))

        with pytest.raises(Exception):
            check_merge_and_pk_conditions('A', ['pk1s'])
    

class TestCheckContainerName(unittest.TestCase):
    def test_check_container_name_supported(self) -> None:
        actual_raw = check_container_name('raw')
        expected_raw = None
        self.assertEqual(actual_raw,expected_raw)

        actual_cleansed = check_container_name('cleansed')
        expected_cleansed = None
        self.assertEqual(actual_cleansed,expected_cleansed)

        actual_curated = check_container_name('curated')
        expected_curated = None
        self.assertEqual(actual_curated,expected_curated)
    
    def test_check_container_name_not_supported(self) -> None:
        with self.assertRaises(ValueError) as context:
            check_container_name('invalid_name')
        expected = f'Container name \'invalid_name\' not supported.'
        print( str(context.exception))
        self.assertTrue(expected in str(context.exception))


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
        expected = f'Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.'
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(ValueError) as context2:
            compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,2))
        expected2 = f'Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.'
        self.assertTrue(expected2 in str(context2.exception))

    def test_compare_raw_load_vs_last_cleansed_date_raw_lt_cleansed_manual_override(self) -> None:
        actual3 = compare_raw_load_vs_last_cleansed_date(datetime(2024,1,1), datetime(2024,1,2), True)
        expected3 = None
        self.assertEqual(actual3,expected3)
    
   