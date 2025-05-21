def getMergePayloadVariables(payload: dict()) -> list():
    # create variables for each payload item
    tableName = payload["DatasetDisplayName"] 
    loadType = payload["LoadType"]
    loadAction = payload["LoadAction"]
    loadActionText = "full" if loadAction == "F" else "incremental"
    versionNumber = f"{int(payload['VersionNumber']):04d}"

    rawStorageName = payload["RawStorageName"]
    rawContainerName = payload["RawContainerName"]
    rawSecret = payload["RawStorageAccessKey"]
    rawLastLoadDate = payload["RawLastLoadDate"]

    rawSchemaName = payload["RawSchemaName"]
    rawFileType = payload["RawFileType"]
    dateTimeFolderHierarchy = payload["DateTimeFolderHierarchy"]

    cleansedStorageName = payload["CleansedStorageName"]
    cleansedContainerName = payload["CleansedContainerName"]
    cleansedSecret = payload["CleansedStorageAccessKey"]
    cleansedLastLoadDate = payload["CleansedLastLoadDate"]

    cleansedSchemaName = payload["CleansedSchemaName"] 

    # Semantic checks for these required in the IngestChecks notebook?
    pkList =  payload["CleansedPkList"].split(",")
    partitionList =  payload["CleansedPartitionFields"].split(",") if  payload["CleansedPartitionFields"] != "" else []

    columnsList = payload["CleansedColumnsList"].split(",")
    columnsTypeList = payload["CleansedColumnsTypeList"].split(",")
    columnsFormatList = payload["CleansedColumnsFormatList"].split(",")
    metadataColumnList = ["PipelineRunId","PipelineExecutionDateTime"]
    metadataColumnTypeList = ["STRING","TIMESTAMP"]
    metadataColumnFormatList = ["","yyyy-MM-dd HH:mm:ss"]

    # metadataColumnList = payload["cleansedMetadataColumnList"].split(",")
    # metadataColumnTypeList = payload["cleansedMetadataColumnTypeList"].split(",")
    # metadataColumnFormatList = payload["cleansedMetadataColumnFormatList"].split(",")

    totalColumnList = columnsList + metadataColumnList
    totalColumnTypeList = columnsTypeList + metadataColumnTypeList
    totalColumnFormatList = columnsFormatList + metadataColumnFormatList

    # totalColumnList = columnsList
    # totalColumnTypeList = columnsTypeList
    # totalColumnFormatList = columnsFormatList

    output = [tableName, loadType, loadAction, loadActionText, versionNumber, rawStorageName, rawContainerName, rawSecret, rawLastLoadDate, rawSchemaName, rawFileType, dateTimeFolderHierarchy, cleansedStorageName, cleansedContainerName, cleansedSecret, cleansedLastLoadDate, cleansedSchemaName, pkList, partitionList, columnsList, columnsTypeList, columnsFormatList, metadataColumnList, metadataColumnTypeList, metadataColumnFormatList, totalColumnList, totalColumnTypeList, totalColumnFormatList]

    return output
