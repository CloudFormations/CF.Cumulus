from notebooks.utils.CheckPayloadFunctions import *
import unittest
import pytest


class TestCheckLoadAction(unittest.TestCase):
    def test_checkLoadActionF(self) -> None:
        actual = checkLoadAction('F')
        expected = None
        self.assertEqual(actual,expected)

    def test_checkLoadActionI(self) -> None:
        actual = checkLoadAction('I')
        expected = None
        self.assertEqual(actual,expected)
    
    def test_checkLoadActionUnallowedString(self) -> None:
        with self.assertRaises(Exception) as context:
            checkLoadAction('Q')
        expected = f'Load Type of Q not yet supported in cleansed layer logic. Please review.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            checkLoadAction('Q')

    def test_checkLoadActionUnallowedNone(self) -> None:
        with self.assertRaises(Exception) as context:
            checkLoadAction(None)
        expected = f'Load Type of None not yet supported in cleansed layer logic. Please review.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(Exception):
            checkLoadAction(None)
    

class TestCheckMergeAndPKConditions(unittest.TestCase):
    def test_checkMergeAndPKConditions_I_with_pks(self) -> None:
        actual = checkMergeAndPKConditions('I', ['pk1'])
        expected = None
        self.assertEqual(actual,expected)

        actual2 = checkMergeAndPKConditions('I', ['pk1','pk2'])
        expected2 = None
        self.assertEqual(actual2,expected2)

    def test_checkMergeAndPKConditions_F_with_pks(self) -> None:
        actual = checkMergeAndPKConditions('F', ['pk1'])
        expected = None
        self.assertEqual(actual,expected)

        actual = checkMergeAndPKConditions('F', ['pk1','pk2'])
        expected = None
        self.assertEqual(actual,expected)

    def test_checkMergeAndPKConditions_F_with_no_pks(self) -> None:
        actual = checkMergeAndPKConditions('F', [])
        expected = None
        self.assertEqual(actual,expected)

    def test_checkMergeAndPKConditions_I_with_no_pks(self) -> None:
        with self.assertRaises(ValueError) as context:
            checkMergeAndPKConditions('I', [])
        expected = f'Incremental loading configured with no primary/business keys. This is not a valid combination and will result in merge failures as no merge criteria can be specified.'
        self.assertTrue(expected in str(context.exception))

        with pytest.raises(ValueError):
            checkMergeAndPKConditions('I', [])
    
    def test_checkMergeAndPKConditions_invalid_load_action(self) -> None:
        with self.assertRaises(Exception) as context1:
            checkMergeAndPKConditions('W', [])
        expected1 = f'Unexpected state.'
        self.assertTrue(expected1 in str(context1.exception))

        with pytest.raises(Exception):
            checkMergeAndPKConditions('W', [])

        with self.assertRaises(Exception) as context2:
            checkMergeAndPKConditions('A', ['pk1s'])
        expected2 = f'Unexpected state.'
        self.assertTrue(expected2 in str(context2.exception))

        with pytest.raises(Exception):
            checkMergeAndPKConditions('A', ['pk1s'])
    

class TestCheckContainerName(unittest.TestCase):
    def test_checkContainerNameSupported(self) -> None:
        actual_raw = checkContainerName('raw')
        expected_raw = None
        self.assertEqual(actual_raw,expected_raw)

        actual_cleansed = checkContainerName('cleansed')
        expected_cleansed = None
        self.assertEqual(actual_cleansed,expected_cleansed)

        actual_curated = checkContainerName('curated')
        expected_curated = None
        self.assertEqual(actual_curated,expected_curated)
    
    def test_checkContainerNameNotSupported(self) -> None:
        with self.assertRaises(ValueError) as context:
            checkContainerName('invalid_name')
        expected = f'Container name \'invalid_name\' not supported.'
        print( str(context.exception))
        self.assertTrue(expected in str(context.exception))


class TestCompareRawLoadVsLastCleansedDate(unittest.TestCase):
    def test_compareRawLoadVsLastCleansedDate_raw_none(self) -> None:
        # Check condition holds for both ManualOverrideParameterValues (Default False)
        with self.assertRaises(Exception) as context:
            compareRawLoadVsLastCleansedDate(None, datetime(2024,1,1))
        expected = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(Exception) as context2:
            compareRawLoadVsLastCleansedDate(None, datetime(2024,1,1), False)
        expected2 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected2 in str(context2.exception))

        with self.assertRaises(Exception) as context3:
            compareRawLoadVsLastCleansedDate(None, datetime(2024,1,1), True)
        expected3 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected3 in str(context3.exception))
    
    def test_compareRawLoadVsLastCleansedDate_raw_cleansed_none(self) -> None:
        # Check condition holds for both ManualOverrideParameterValues (Default False)
        with self.assertRaises(Exception) as context:
            compareRawLoadVsLastCleansedDate(None, None)
        expected = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(Exception) as context2:
            compareRawLoadVsLastCleansedDate(None, None, False)
        expected2 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected2 in str(context2.exception))


        with self.assertRaises(Exception) as context3:
            compareRawLoadVsLastCleansedDate(None, None, True)
        expected3 = f"Raw file has not been loaded historically. Confirm the desired file exists and the metadata provided is accurate."
        self.assertTrue(expected3 in str(context3.exception))

    def test_compareRawLoadVsLastCleansedDate_cleansed_none(self) -> None:
        actual = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), None)
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), None, False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), None, True)
        expected3 = None
        self.assertEqual(actual3,expected3)

    def test_compareRawLoadVsLastCleansedDate_raw_gt_cleansed(self) -> None:
        actual = compareRawLoadVsLastCleansedDate(datetime(2024,1,2), datetime(2024,1,1))
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compareRawLoadVsLastCleansedDate(datetime(2024,1,2), datetime(2024,1,1), False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compareRawLoadVsLastCleansedDate(datetime(2024,1,2), datetime(2024,1,1), True)
        expected3 = None
        self.assertEqual(actual3,expected3)
        
    def test_compareRawLoadVsLastCleansedDate_raw_eq_cleansed(self) -> None:
        actual = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,1))
        expected = None
        self.assertEqual(actual,expected)

        actual2 = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,1), False)
        expected2 = None
        self.assertEqual(actual2,expected2)

        actual3 = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,1), True)
        expected3 = None
        self.assertEqual(actual3,expected3)

    def test_compareRawLoadVsLastCleansedDate_raw_lt_cleansed_no_manual_override(self) -> None:
        with self.assertRaises(ValueError) as context:
            compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,2))
        expected = f'Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.'
        self.assertTrue(expected in str(context.exception))

        with self.assertRaises(ValueError) as context2:
            compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,2))
        expected2 = f'Raw file load date less than the cleansed last run date. This is not supported behaviour and needs manual overriding if intended.'
        self.assertTrue(expected2 in str(context2.exception))

    def test_compareRawLoadVsLastCleansedDate_raw_lt_cleansed_manual_override(self) -> None:
        actual3 = compareRawLoadVsLastCleansedDate(datetime(2024,1,1), datetime(2024,1,2), True)
        expected3 = None
        self.assertEqual(actual3,expected3)
    
   