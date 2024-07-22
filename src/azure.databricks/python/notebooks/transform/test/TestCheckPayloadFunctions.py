# Databricks notebook source
# MAGIC %run ../utils/CheckPayloadFunctions

# COMMAND ----------

import unittest

# COMMAND ----------

class TestCheckSurrogateKey(unittest.TestCase):
    def test_checkSurrogateKeyValidString(self):
        actual = checkSurrogateKey(surrogateKey="StringValue")
        expected = True
        self.assertEqual(actual, expected)

    def test_checkSurrogateKeyBlankString(self):
        with self.assertRaises(Exception) as context:
            checkSurrogateKey(surrogateKey="")
        expected = "Surrogate Key is a blank string. Please ensure this is populated for Curated tables."
        self.assertTrue(expected in str(context.exception))

# COMMAND ----------

# class TestCheckExistsNotebook(unittest.TestCase):
#     def test_checkExistsNotebookValidPath(self):
#         actual = checkExistsNotebook(notebookPath="StringValue")
#         expected = True
#         self.assertEqual(actual, expected)

#     def test_checkExistsNotebookInvalidPath(self):
#         with self.assertRaises(Exception) as context:
#             checkExistsNotebook(notebookPath="StringValue2")
#         expected = "Notebook cannot be found at this path. Please ensure this has been created in the appropriate directory."
#         self.assertTrue(expected in str(context.exception))


# COMMAND ----------

class TestCompareDeltaTableSizeVsPartitionThreshold(unittest.TestCase):

    def test_compareDeltaTableSizeVsPartitionThresholdTableSmaller(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=100, partitionByThreshold=(1024**4))
        expected = 'Delta table samller than partition by threshold. Partitions not advised unless other requirements, such as RLS.'
        self.assertEqual(actual, expected)
    
    def test_compareDeltaTableSizeVsPartitionThresholdTableSmaller2(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=(1024**3), partitionByThreshold=(1024**4))
        expected = 'Delta table samller than partition by threshold. Partitions not advised unless other requirements, such as RLS.'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdTableSmaller3(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=100, partitionByThreshold=101)
        expected = 'Delta table samller than partition by threshold. Partitions not advised unless other requirements, such as RLS.'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdEqualSize(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=(1024**4), partitionByThreshold=(1024**4))
        expected = 'Delta table equal size to partition by threshold. Partitions may be used.'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdEqualSize2(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=100, partitionByThreshold=100)
        expected = 'Delta table equal size to partition by threshold. Partitions may be used.'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdEqualSize3(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=1099511627776, partitionByThreshold=(1024**4))
        expected = 'Delta table equal size to partition by threshold. Partitions may be used.'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdTableBigger(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=101, partitionByThreshold=100)
        expected = 'Delta table bigger than partition by threshold. Partitions may be used'
        self.assertEqual(actual, expected)

    def test_compareDeltaTableSizeVsPartitionThresholdTableBigger2(self):
        actual = compareDeltaTableSizeVsPartitionThreshold(deltaTableSizeInBytes=1099511627777, partitionByThreshold=(1024**4))
        expected = 'Delta table bigger than partition by threshold. Partitions may be used'
        self.assertEqual(actual, expected)

# COMMAND ----------

class TestCheckEmptyPartitionByFields(unittest.TestCase):

    def test_checkEmptyPartitionByFieldsTableExistsSingleElement(self):
        actual = checkEmptyPartitionByFields(partitionList=['sampleField'])
        expected = False
        self.assertEqual(actual, expected)
    
    def test_checkEmptyPartitionByFieldsTableExistsMultipleElements(self):
        actual = checkEmptyPartitionByFields(partitionList=['sampleField1','sampleField2'])
        expected = False
        self.assertEqual(actual, expected)

    def test_checkEmptyPartitionByFieldsTableEmpty(self):
        actual = checkEmptyPartitionByFields(partitionList=[])
        expected = True
        self.assertEqual(actual, expected)

    def test_checkEmptyPartitionByFieldsPartitionFieldsNone(self):
        with self.assertRaises(Exception) as context:
            checkEmptyPartitionByFields(partitionList=None)
        expected = "PartitionBy fields input as None value. Please review."
        self.assertTrue(expected in str(context.exception))
    


# COMMAND ----------

r = unittest.main(argv=[''], verbosity=2, exit=False)
assert r.result.wasSuccessful(), 'Test failed; see logs above'
