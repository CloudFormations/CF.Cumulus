# Databricks notebook source
def getTransformPayloadVariables(payload: dict()) -> list():
    # create variables for each payload item
    cleansedSecret = payload["CleansedStorageAccessKey"]
    cleansedStorageName = payload["CleansedStorageName"] 
    cleansedContainerName = payload["CleansedContainerName"]    
    curatedSecret = payload["CuratedStorageAccessKey"]
    curatedStorageName = payload["CuratedStorageName"] 
    curatedContainerName = payload["CuratedContainerName"] 

    curatedSchemaName = payload["SchemaName"]
    curatedDatasetName = payload["DatasetName"]
    columnsList = payload["ColumnsList"].split(",")
    columnTypeList = payload["ColumnTypeList"].split(",")

    bkList =  payload["BkAttributesList"].split(",")
    partitionList =  payload["PartitionByAttributesList"].split(",") if  payload["PartitionByAttributesList"] != "" else []

    surrogateKey = payload["SurrogateKey"]

    loadType = payload["LoadType"]

    businessLogicNotebookPath = payload["BusinessLogicNotebookPath"]

    output = [cleansedSecret, cleansedStorageName, cleansedContainerName, curatedSecret, curatedStorageName, curatedContainerName, curatedSchemaName, curatedDatasetName, columnsList, columnTypeList, bkList, partitionList, surrogateKey, loadType, businessLogicNotebookPath]

    return output
