def get_merge_payload_variables(payload: dict()) -> list():
    # create variables for each payload item
    table_name = payload["DatasetDisplayName"] 
    load_type = payload["LoadType"]
    load_action = payload["LoadAction"]
    load_action_text = "full" if load_action == "F" else "incremental"
    version_number = f"{int(payload['VersionNumber']):04d}"

    raw_storage_name = payload["RawStorageName"]
    raw_container_name = payload["RawContainerName"]
    raw_secret = payload["RawStorageAccessKey"]
    raw_last_load_date = payload["RawLastLoadDate"]

    raw_schema_name = payload["RawSchemaName"]
    raw_file_type = payload["RawFileType"]
    datetime_folder_hierarchy = payload["DateTimeFolderHierarchy"]

    cleansed_storage_name = payload["CleansedStorageName"]
    cleansed_container_name = payload["CleansedContainerName"]
    cleansed_secret = payload["CleansedStorageAccessKey"]
    cleansed_last_load_date = payload["CleansedLastLoadDate"]

    cleansed_schema_name = payload["CleansedSchemaName"] 

    # Semantic checks for these required in the IngestChecks notebook?
    pk_list =  payload["CleansedPkList"].split(",")
    partition_list =  payload["CleansedPartitionFields"].split(",") if  payload["CleansedPartitionFields"] != "" else []

    columns_list = payload["CleansedColumnsList"].split(",")
    columns_type_list = payload["CleansedColumnsTypeList"].split(",")
    columns_format_list = payload["CleansedColumnsFormatList"].split(",")
    metadata_column_list = ["PipelineRunId","PipelineExecutionDateTime"]
    metadata_column_type_list = ["STRING","TIMESTAMP"]
    metadata_column_format_list = ["","yyyy-MM-dd HH:mm:ss"]

    # metadata_column_list = payload["cleansedMetadataColumnList"].split(",")
    # metadata_column_type_list = payload["cleansedMetadataColumnTypeList"].split(",")
    # metadata_column_format_list = payload["cleansedMetadataColumnFormatList"].split(",")

    total_column_list = columns_list + metadata_column_list
    total_column_type_list = columns_type_list + metadata_column_type_list
    total_column_format_list = columns_format_list + metadata_column_format_list

    # totalColumnList = columns_list
    # totalColumnTypeList = columnsTypeList
    # totalColumnFormatList = columnsFormatList

    output = [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list]

    return output
