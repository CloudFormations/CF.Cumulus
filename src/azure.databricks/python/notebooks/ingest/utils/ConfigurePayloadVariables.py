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

    raw_connection_name = payload["RawConnectionName"] # connection name of data source
    raw_file_type = payload["RawFileType"] 
    raw_source_path = payload["RawSourcePath"] # physical path in raw container
    raw_source_name = payload["RawSourceName"] # file name in raw container
    
    datetime_folder_hierarchy = payload["DateTimeFolderHierarchy"]

    cleansed_storage_name = payload["CleansedStorageName"]
    cleansed_container_name = payload["CleansedContainerName"]
    cleansed_secret = payload["CleansedStorageAccessKey"]
    cleansed_last_load_date = payload["CleansedLastLoadDate"]

    cleansed_connection_name = payload["CleansedConnectionName"] # connection name of data source
    cleansed_source_path = payload["CleansedSourcePath"] # desired physical path in cleansed container
    cleansed_source_name = payload["CleansedSourceName"] # desired file name in cleansed container

    filter_condition = payload["FilterCondition"] 

    # Semantic checks for these required in the IngestChecks notebook?
    pk_list =  payload["CleansedPkList"].split("|")
    partition_list =  payload["CleansedPartitionFields"].split("|") if  payload["CleansedPartitionFields"] != "" else []

    columns_list = payload["CleansedColumnsList"].split("|")
    columns_type_list = payload["CleansedColumnsTypeList"].split("|")
    columns_format_list = payload["CleansedColumnsFormatList"].split("|")
    metadata_column_list = ["PipelineRunId","PipelineExecutionDateTime"]
    metadata_column_type_list = ["STRING","TIMESTAMP"]
    metadata_column_format_list = ["","yyyy-MM-dd HH:mm:ss"]

    total_column_list = columns_list + metadata_column_list
    total_column_type_list = columns_type_list + metadata_column_type_list
    total_column_format_list = columns_format_list + metadata_column_format_list

    output = [table_name,load_type,load_action,load_action_text,version_number,raw_storage_name,raw_container_name,raw_secret,raw_last_load_date,raw_connection_name,raw_file_type,raw_source_path,raw_source_name,datetime_folder_hierarchy,cleansed_storage_name,cleansed_container_name,cleansed_secret,cleansed_last_load_date,cleansed_connection_name,cleansed_source_path,cleansed_source_name,filter_condition,pk_list,partition_list,columns_list,columns_type_list,columns_format_list,metadata_column_list,metadata_column_type_list,metadata_column_format_list,total_column_list,total_column_type_list,total_column_format_list]

    return output
