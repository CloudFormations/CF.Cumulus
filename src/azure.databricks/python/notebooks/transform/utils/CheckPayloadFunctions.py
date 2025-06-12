def check_surrogate_key(surrogate_key: str) -> bool:
    if surrogate_key == "":
        raise ValueError("Surrogate Key is a blank string. Please ensure this is populated for Curated tables.")
    elif surrogate_key != "":
        print(f"surrogate_key value {surrogate_key} is non-blank.")
        return True
    else:
        raise Exception("Unexpected state.")

def compare_delta_table_size_vs_partition_threshold(delta_table_size_in_bytes:int, partition_by_threshold: int):
    if delta_table_size_in_bytes > partition_by_threshold:
        return 'Delta table bigger than partition by threshold. Partitions may be used'
    elif delta_table_size_in_bytes < partition_by_threshold:
        return 'Delta table samller than partition by threshold. Partitions not advised unless other requirements, such as RLS.'
    elif delta_table_size_in_bytes == partition_by_threshold:
        return 'Delta table equal size to partition by threshold. Partitions may be used.'
    else:
        raise Exception('Unexpected state. Please investigate value provided for sizeInBytes and partition_by_threshold.')

# Advisory check partitionby not used for small tables (may have RLS use case)
def check_empty_partition_by_fields(partition_list: list()) -> bool:
    if partition_list == []:
        print('Empty list passed to partition fields value. No action required.')
        return True
    elif partition_list is None: 
        raise ValueError('PartitionBy fields input as None value. Please review.')
    elif partition_list != []:
        print('Non-empty list passed to partition fields value. Please confirm partitioning is required based on Delta table size and RLS requirements.')
        return False
    else:
        raise Exception('Unexpected state. Please investigate value provided for partition_list.')