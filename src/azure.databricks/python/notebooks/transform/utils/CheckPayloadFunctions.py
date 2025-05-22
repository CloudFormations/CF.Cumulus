# Databricks notebook source
def check_surrogate_key(surrogate_key: str) -> bool:
    if surrogate_key == "":
        raise ValueError("Surrogate Key is a blank string. Please ensure this is populated for Curated tables.")
    elif surrogate_key != "":
        print(f"surrogate_key value {surrogate_key} is non-blank.")
        return True
    else:
        raise Exception("Unexpected state.")

# COMMAND ----------

# # Requires API as can't iterate through notebooks...
# def checkExistsNotebook(notebookPath: str) -> bool:
#     raise NotImplementedError


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

# r = unittest.main(argv=[''], verbosity=2, exit=False)
# assert r.result.wasSuccessful(), 'Test failed; see logs above'

# COMMAND ----------

def compare_delta_table_size_vs_partition_threshold(delta_table_size_in_bytes:int, partition_by_threshold: int):
    if delta_table_size_in_bytes > partition_by_threshold:
        return 'Delta table bigger than partition by threshold. Partitions may be used'
    elif delta_table_size_in_bytes < partition_by_threshold:
        return 'Delta table samller than partition by threshold. Partitions not advised unless other requirements, such as RLS.'
    elif delta_table_size_in_bytes == partition_by_threshold:
        return 'Delta table equal size to partition by threshold. Partitions may be used.'
    else:
        raise Exception('Unexpected state. Please investigate value provided for sizeInBytes and partition_by_threshold.')

# COMMAND ----------

# Advisory check partitionby not used for small tables (may have RLS use case)
def check_empty_partition_by_fields(partition_list:list()) -> bool:
    if partition_list == []:
        print('Empty list passed to partition fields value. No action required.')
        return True
    elif partition_list is None: 
        raise Exception('PartitionBy fields input as None value. Please review.')
    elif partition_list != []:
        print('Non-empty list passed to partition fields value. Please confirm partitioning is required based on Delta table size and RLS requirements.')
        return False
    else:
        raise Exception('Unexpected state. Please investigate value provided for partition_list.')
