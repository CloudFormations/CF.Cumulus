# Databricks notebook source
def selectSqlColumnsFormatString(totalColumnList:list,totalColumnTypeList:list, totalColumnFormatList:list) -> list:
    """
    Format strings with required schema enforcement for SQL.
    """
    
    totalColumnListLowercase = [x.lower() for x in totalColumnList]
    totalColumnTypeListLowercase = [x.lower() for x in totalColumnTypeList]
    # Note we do not want totalColumnFormatList in lowercase

    sqlFormat = [
        # timestamp handling
        f"to_timestamp({str(col)},'{_format}') as {str(col)}" if _type == "timestamp" and _format != 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ'
        else f"to_timestamp({str(col)}) as {str(col)}" if (_type == "timestamp" and _format == 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ')

        # date handling
        else f"to_date({str(col)},'{_format}') as {str(col)}" if _type == "date" 

        # nested json handling
        else f"{str(_format)} as {str(col)}" if "_exploded" in _format and not "." in _format
        else f"cast({_format} as {_type}) as {str(col)}" if "_exploded" in _format and "." in _format

        # else
        else f"cast({str(col)} as {_type}) as {str(col)}"

        for col,_type,_format in zip(totalColumnListLowercase,totalColumnTypeListLowercase, totalColumnFormatList)
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

# COMMAND ----------

def selectSqlExplodedOptionString(totalColumnList:list,totalColumnTypeList:list, totalColumnFormatList:list) -> list:
    """
    Format SQL statement for any lateral views required in exploded columns.
    """

    totalColumnListLowercase = [x.lower() for x in totalColumnList]
    totalColumnTypeListLowercase = [x.lower() for x in totalColumnTypeList]
    totalColumnFormatListLowercase = [x.lower() for x in totalColumnFormatList]

    unstructuredFormat = [
        f'lateral view explode({(_format.split(".")[0]).replace("explode:","")}) as {(_format.split(".")[0]).replace("explode:","")}_exploded' if ("explode:" in _format and "." in _format)
        else f'lateral view explode({_format.replace("explode:","")}) as {_format.replace("explode:","")}_exploded' if ("explode:" in _format and not "." in _format)
        # else f"cast({str(col)} as {_type}) as {str(col)}"
        else ''
        for col,_type,_format in zip(totalColumnListLowercase,totalColumnTypeListLowercase, totalColumnFormatListLowercase)
        ]
        
    # deduplicate
    unstructuredFormatUnique =  list(dict.fromkeys(unstructuredFormat)) 

    # to string
    unstructuredFormatStr = (" ".join(unstructuredFormatUnique)).strip()
    return unstructuredFormatStr

def formatAttributeTargetDataFormatList(AttributeTargetDataFormat:list) -> list:
    """
    Extract exploded column formats.
    """

    AttributeTargetDataFormatLowercase = [x.lower() for x in AttributeTargetDataFormat]
    
    formatAttributeTargetDataFormat = [
        _str.replace("explode:","").replace('.','_exploded.') if ("explode:" in _str and "." in _str)
        else f'{_str.replace("explode:","")}_exploded' if ("explode:" in _str and not "." in _str)
        else ''
        for _str in AttributeTargetDataFormatLowercase]

    return formatAttributeTargetDataFormat