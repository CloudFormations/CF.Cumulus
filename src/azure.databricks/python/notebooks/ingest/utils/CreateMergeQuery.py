def format_timestamp(col, _type, _format):
    if _type == "timestamp":
        if _format != 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ':
            return f"to_timestamp({col},'{_format}') as {col}"
        else:
            return f"to_timestamp({col}) as {col}"
    return None

def format_date(col, _type, _format):
    if _type == "date":
        return f"to_date({col},'{_format}') as {col}"
    return None

def format_nested(col, _type, _format, _unpack):
    if _unpack:
        if _type == "timestamp":
            return f"to_timestamp({_unpack},'{_format}') as {col}"
        elif _type == "date":
            return f"to_date({_unpack},'{_format}') as {col}"
        else:
            return f"cast({_unpack} as {_type}) as {col}"
    else:
        return None


def format_default(col, _type):
    return f"cast({col} as {_type}) as {col}"

def select_sql_columns_format_string(total_column_list: list, total_column_type_list: list, total_column_format_list: list, columns_unpack_list: list) -> str:
    """
    Format strings with required schema enforcement for SQL.
    """

    total_column_list_lowercase = [x.lower() for x in total_column_list]
    total_column_type_list_lowercase = [x.lower() for x in total_column_type_list]
    columns_unpack_list_lowercase = [x.lower() for x in columns_unpack_list]

    sql_format = []
    for col, _type, _format, _unpack in zip(total_column_list_lowercase, total_column_type_list_lowercase, total_column_format_list, columns_unpack_list_lowercase):
        formatted = (
            format_timestamp(col, _type, _format) or
            format_date(col, _type, _format) or
            format_nested(col, _type, _format, _unpack) or
            format_default(col, _type, _format)
        )
        sql_format.append(formatted)

    return ", ".join(sql_format)

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