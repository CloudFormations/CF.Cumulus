def get_transform_payload_variables(payload: dict()) -> list():
    # create variables for each payload item
    cleansed_secret = payload["CleansedStorageAccessKey"]
    cleansed_storage_name = payload["CleansedStorageName"] 
    cleansed_container_name = payload["CleansedContainerName"]    
    curated_secret = payload["CuratedStorageAccessKey"]
    curated_storage_name = payload["CuratedStorageName"] 
    curated_container_name = payload["CuratedContainerName"] 

    curated_schema_name = payload["SchemaName"]
    curated_dataset_name = payload["DatasetName"]
    columns_list = payload["ColumnsList"].split(",")
    column_type_list = payload["ColumnTypeList"].split(",")

    bk_list =  payload["BkAttributesList"].split(",")
    partition_list =  payload["PartitionByAttributesList"].split(",") if  payload["PartitionByAttributesList"] != "" else []

    surrogate_key = payload["SurrogateKey"]

    load_type = payload["LoadType"]

    business_logic_notebook_path = payload["BusinessLogicNotebookPath"]

    output = [cleansed_secret, cleansed_storage_name, cleansed_container_name, curated_secret, curated_storage_name, curated_container_name, curated_schema_name, curated_dataset_name, columns_list, column_type_list, bk_list, partition_list, surrogate_key, load_type, business_logic_notebook_path]

    return output
