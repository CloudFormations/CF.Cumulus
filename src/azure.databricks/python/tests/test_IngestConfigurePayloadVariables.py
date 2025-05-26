from notebooks.ingest.utils.ConfigurePayloadVariables import *
import pytest


@pytest.fixture
def default_payload() -> dict:
    payload = {
        "RawSchemaName":"Oracle",
        "ComputeName":"CF.Cumulus.Ingest.Compute",
        "ComputeWorkspaceURL":"https://devdatabricksguid.azuredatabricks.net/",
        "ComputeClusterId":"",
        "ComputeSize":"Standard_D4ds_v5",
        "ComputeVersion":"15.4.x-scala2.12",
        "CountNodes":1,
        "ComputeLinkedServiceName":"Ingest_LS_Databricks_Cluster_MIAuth",
        "ComputeResourceName":"devdatabricksworkspace",
        "ResourceGroupName":"devresourcegroup",
        "SubscriptionId":"12345-67890",
        "RawStorageName":"devdatalakestorage",
        "RawContainerName":"raw",
        "CleansedStorageName":"devdatalakestorage",
        "CleansedContainerName":"cleansed",
        "RawStorageAccessKey":"devdatalakestoragerawaccesskey",
        "CleansedStorageAccessKey":"devdatalakestoragecleansedaccesskey",
        "KeyVaultAddress":"https://devkeyvault.vault.azure.net/",
        "DatasetDisplayName":"testdataset",
        "SourcePath":"dbo",
        "SourceName":"testdataset",
        "RawFileType":"parquet",
        "VersionNumber":1,
        "CleansedSchemaName":"Oracle",
        "CleansedTableName":"testdataset",
        "Enabled":True,
        "LoadType":"I",
        "LoadAction":"F",
        "RawLastLoadDate":"2025-05-23T10:18:36.33",
        "CleansedLastLoadDate":"null",
        "CleansedColumnsList":"ID,NAME",
        "CleansedColumnsTypeList":"INTEGER,STRING",
        "CleansedColumnsFormatList":",",
        "CleansedPkList":"ID",
        "CleansedPartitionFields":"",
        "DateTimeFolderHierarchy":"year=2025/month=01/day=1/hour=10"}
    return payload

def test_get_merge_payload_variables_table_name(default_payload):
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=default_payload)
    expected = 'testdataset'
    assert table_name == expected

def test_get_merge_payload_variables_load_type_default(default_payload):
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=default_payload)
    expected = 'I'
    assert load_type == expected

def test_get_merge_payload_variables_load_type_override(default_payload):
    payload = default_payload.copy()
    payload['LoadType'] = 'F'
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=payload)
    expected = 'F'
    assert load_type == expected

def test_get_merge_payload_variables_load_action_default(default_payload):
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=default_payload)
    expected = 'F'
    assert load_action == expected

def test_get_merge_payload_variables_load_action_override(default_payload):
    payload = default_payload.copy()
    payload['LoadAction'] = 'I'
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=payload)
    expected = 'I'
    assert load_action == expected

def test_get_merge_payload_variables_load_action_text(default_payload):
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=default_payload)
    expected = 'full'
    assert load_action_text == expected

def test_get_merge_payload_variables_version_number(default_payload):
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=default_payload)
    expected = '0001'
    assert version_number == expected

def test_get_merge_payload_variables_version_number_tens(default_payload):
    payload = default_payload.copy()
    payload['VersionNumber'] = 10
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=payload)
    expected = '0010'
    assert version_number == expected

def test_get_merge_payload_variables_version_number_hundreds(default_payload):
    payload = default_payload.copy()
    payload['VersionNumber'] = 151
    [table_name, load_type, load_action, load_action_text, version_number, raw_storage_name, raw_container_name, raw_secret, raw_last_load_date, raw_schema_name, raw_file_type, datetime_folder_hierarchy, cleansed_storage_name, cleansed_container_name, cleansed_secret, cleansed_last_load_date, cleansed_schema_name, pk_list, partition_list, columns_list, columns_type_list, columns_format_list, metadata_column_list, metadata_column_type_list, metadata_column_format_list, total_column_list, total_column_type_list, total_column_format_list] = get_merge_payload_variables(payload=payload)
    expected = '0151'
    assert version_number == expected