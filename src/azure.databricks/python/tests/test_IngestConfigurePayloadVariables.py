from notebooks.ingest.utils.ConfigurePayloadVariables import getMergePayloadVariables
import pytest

@pytest.fixture
def dict_of_empty_values() -> dict: 
    return {
        "DatasetDisplayName": "",
        "LoadType": "",
        "LoadAction": "",
        'VersionNumber': "",
        "RawStorageName": "",
        "RawContainerName": "",
        "RawStorageAccessKey": "",
        "RawLastLoadDate": "",
        "RawSchemaName": "",
        "RawFileType": "",
        "DateTimeFolderHierarchy": "",
        "CleansedStorageName": "",
        "CleansedContainerName": "",
        "CleansedStorageAccessKey": "",
        "CleansedLastLoadDate": "",
        "CleansedSchemaName": "",
        "CleansedPkList": "",
        "CleansedPartitionFields": "",
        "CleansedPartitionFields": "",
        "CleansedColumnsList": "",
        "CleansedColumnsTypeList": "",
        "CleansedColumnsFormatList": "",
        "cleansedMetadataColumnList": "",
        "cleansedMetadataColumnTypeList": "",
        "cleansedMetadataColumnFormatList": ""
    }

def test_getMergePayloadVariables_versionNumber_single_digit(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_var['VersionNumber'] = 1
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_var)
    expected = '0001'
    assert versionNumber ==  expected

def test_getMergePayloadVariables_versionNumber_double_digit(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_var['VersionNumber'] = 10
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_var)
    expected = '0010'
    assert versionNumber ==  expected

def test_getMergePayloadVariables_versionNumber_double_digit2(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_var['VersionNumber'] = 11
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_var)
    expected = '0011'
    assert versionNumber ==  expected

def test_getMergePayloadVariables_versionNumber_triple_digit(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_var['VersionNumber'] = 100
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_var)
    expected = '0100'
    assert versionNumber ==  expected

def test_getMergePayloadVariables_partitionList_blank(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_var['VersionNumber'] = 1
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_var)

    expected = []
    assert partitionList ==  expected

def test_getMergePayloadVariables_partitionList_single_pk(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_with_single_pk = dict_var
    dict_with_single_pk['VersionNumber'] = 1
    dict_with_single_pk["CleansedPartitionFields"] = "pk1"
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_with_single_pk)

    expected = ['pk1']
    assert partitionList ==  expected

def test_getMergePayloadVariables_partitionList_multi_pk(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_with_multi_pk = dict_var
    dict_with_multi_pk['VersionNumber'] = 1
    dict_with_multi_pk["CleansedPartitionFields"] = "pk1,pk2"
    [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList] = getMergePayloadVariables(dict_with_multi_pk)

    expected = ['pk1', 'pk2']
    assert partitionList ==  expected

