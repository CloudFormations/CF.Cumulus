from notebooks.transform.utils.ConfigurePayloadVariables import getTransformPayloadVariables
import pytest

@pytest.fixture
def dict_of_empty_values():
    return {
            "CleansedStorageAccessKey": "",
            "CleansedStorageName": "",
            "CleansedContainerName": "",
            "CuratedStorageAccessKey": "",
            "CuratedStorageName": "",
            "CuratedContainerName": "",
            "SchemaName": "",
            "DatasetName": "",
            "ColumnsList": "",
            "ColumnTypeList": "",
            "BkAttributesList": "",
            "PartitionByAttributesList": "",
            "SurrogateKey": "",
            "LoadType": "",
            "BusinessLogicNotebookPath": ""
        }

def test_getTransformPayloadVariables_partitionList_blank(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    [cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath] = getTransformPayloadVariables(dict_var)

    expected = []
    assert partitionList ==  expected

def test_getTransformPayloadVariables_partitionList_single_pk(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_with_single_pk = dict_var
    dict_with_single_pk["PartitionByAttributesList"] = "pk1"
    [cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath] = getTransformPayloadVariables(dict_with_single_pk)

    expected = ['pk1']
    assert partitionList ==  expected

def test_getTransformPayloadVariables_partitionList_multi_pk(dict_of_empty_values) -> None:
    dict_var = dict_of_empty_values
    dict_with_multi_pk = dict_var
    dict_with_multi_pk["PartitionByAttributesList"] = "pk1,pk2"
    [cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath] = getTransformPayloadVariables(dict_with_multi_pk)

    expected = ['pk1','pk2']
    assert partitionList ==  expected

