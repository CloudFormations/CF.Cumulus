# Databricks notebook source
def selectSqlColumnsFormatString(totalColumnList:list,totalColumnTypeList:list, totalColumnFormatList:list) -> list:

    sqlFormat = [
        f"to_timestamp({str(col)},'{_format}') as {str(col)}" if _type.lower() == "timestamp" 
        else f"to_timestamp({str(col)}) as {str(col)}" if (_type.lower() == "timestamp" and _format == 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ')
        else f"to_date({str(col)},'{_format}') as {str(col)}" if _type.lower() == "date" 
        else f"cast({str(col)} as {_type}) as {str(col)}"
        for col,_type,_format in zip(totalColumnList,totalColumnTypeList, totalColumnFormatList)
        ]
        
    totalColumnStr = ", ".join(sqlFormat)
    return totalColumnStr


# Further editing required for timestamp and date when specific formats required.
# Worth reviewing, as this saves us from creating a temp table for the select statement and creating another pyspark dataframe.

def pythonColumnsFormatString(totalColumnList:list, totalColumnTypeList:list, totalColumnFormatList:list) -> list:

    pythonFormat = [
        f"{str(col)} timestamp '{_format}'" if _type == "timestamp" 
        else f"{str(col)} date '{_format}'" if _type == "date" 
        else f"{str(col)} {_type}"
        for col,_type,_format in zip(totalColumnList,totalColumnTypeList, totalColumnFormatList)
        ]
        
    totalColumnStr = ", ".join(pythonFormat)

    return totalColumnStr

# Not used, can be used for defensive programming and error handling tests
def splitStringToList(listAsString:str) -> list:
    return listAsString.split(",")
