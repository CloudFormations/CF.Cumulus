def select_sql_columns_format_string(total_column_list:list,total_column_type_list:list, total_column_format_list:list) -> list:
    """
    Format strings with required schema enforcement for SQL.
    """
    
    total_column_list_lowercase = [x.lower() for x in total_column_list]
    total_column_type_list_lowercase = [x.lower() for x in total_column_type_list]
    # Note we do not want total_column_format_list in lowercase

    sql_format = [
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

        for col,_type,_format in zip(total_column_list_lowercase,total_column_type_list_lowercase, total_column_format_list)
        ]
        
    total_column_str = ", ".join(sql_format)
    return total_column_str

# Further editing required for timestamp and date when specific formats required.
# Worth reviewing, as this saves us from creating a temp table for the select statement and creating another pyspark dataframe.

def python_columns_format_string(total_column_list:list, total_column_type_list:list, total_column_format_list:list) -> list:

    python_format = [
        f"{str(col)} timestamp '{_format}'" if _type == "timestamp" 
        else f"{str(col)} date '{_format}'" if _type == "date" 
        else f"{str(col)} {_type}"
        for col,_type,_format in zip(total_column_list,total_column_type_list, total_column_format_list)
        ]
        
    total_column_str = ", ".join(python_format)

    return total_column_str

# Not used, can be used for defensive programming and error handling tests
def split_string_to_list(list_as_string:str) -> list:
    return list_as_string.split(",")


def select_sql_exploded_option_string(total_column_list:list,total_column_type_list:list, total_column_format_list:list) -> list:

    total_column_list_lowercase = [x.lower() for x in total_column_list]
    total_column_type_list_lowercase = [x.lower() for x in total_column_type_list]
    total_column_format_listLowercase = [x.lower() for x in total_column_format_list]

    unstructured_format = [
        f'lateral view explode({_format.replace("explode:(","").split(")")[0]}) as {_format.replace("explode:(","").split(")")[0].split(".")[-1]}_exploded' if ("explode:" in _format)
        else f'lateral view explode({_format.replace("explode:","")}) as {_format.replace("explode:","")}_exploded' if ("explode:" in _format and not "." in _format)
        # else f"cast({str(col)} as {_type}) as {str(col)}"
        else ''
        for col,_type,_format in zip(total_column_list_lowercase,total_column_type_list_lowercase, total_column_format_listLowercase)
        ]
        
    # deduplicate
    unstructured_format_unique =  list(dict.fromkeys(unstructured_format)) 

    # to string
    unstructured_format_str = (" ".join(unstructured_format_unique)).strip()
    return unstructured_format_str

def format_attribute_target_data_format_list(attribute_target_data_format:list) -> list:

    attribute_target_data_format_lowercase = [x.lower() for x in attribute_target_data_format]
    
    format_attribute_target_data_format = [
        f'{_str.replace("explode:(","").split(")")[0].split(".")[-1]}_exploded{_str.replace("explode:(","").split(")")[1]}'if ("explode:" in _str)
        else ''
        for _str in attribute_target_data_format_lowercase]

    return format_attribute_target_data_format