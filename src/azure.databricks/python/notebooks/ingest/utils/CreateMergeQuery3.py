# Databricks notebook source
import hashlib
import re
from typing import Optional

# COMMAND ----------

def rename_column_as_format(column: str, _format: str) -> str:
    if 'rename:(' in _format:
        return _format.replace("rename:(","").split(")")[0]
    else:
        return column
    
# COMMAND ----------

def format_column_name_remove_forbidden_characters(column: str, allowed_chars: Optional[str] = None) -> str:
    if allowed_chars == 'num_char_only':
        return re.sub("[^0-9a-zA-Z$]+", "", column)
    elif allowed_chars == 'spark_only':
        replacement = ''  # Replace with your desired string
        pattern = r'[,\;\{\}\(\)\.\n\t= ]'
        return re.sub(pattern, replacement, column)
    elif allowed_chars is None:
        return column
    else:
        raise ValueError(f'Unsupported type of {allowed_chars} provided for forbidden_type')

# COMMAND ----------

def selectSqlExplodedOptionString(totalColumnFormatList:list) -> list:

    totalColumnFormatListLowercase = [x.lower() for x in totalColumnFormatList]

    unstructuredFormat = []
    for _format in  totalColumnFormatListLowercase:
        if ("explode:" in _format):
            replace_explode_str = _format.replace("explode:(","").split(")")[0]
            quote_str = f"`{replace_explode_str.replace('.','`.`')}`"
            hashed_col_name = format_exploded_column_as_hashed_value(_format)
            # hashed_col_name = format_exploded_column_as_hashed_value(replace_explode_str)
            explode_str = f'lateral view outer explode({quote_str}) as {hashed_col_name}_exploded'
        else: 
            explode_str = ''
        unstructuredFormat.append(explode_str)

    # deduplicate
    unstructuredFormatUnique =  list(dict.fromkeys(unstructuredFormat)) 

    # to string
    unstructuredFormatStr = (" ".join(unstructuredFormatUnique)).strip()
    return unstructuredFormatStr


def format_attribute_target_data_explode(_format: str) -> str:

    format_lower = _format.lower()
    # get suffix of format string outside of "explode:()"
    suffix = format_lower.replace("explode:(","").split(")")[1]
    
    return f'{format_exploded_column_as_hashed_value(format_lower)}_exploded{suffix}'


def format_attribute_target_data_nested(_format: str) -> str:
    
    format_lower = _format.lower()

    return f'{format_lower.replace("nested:(","").split(")")[0]}_nested'


def format_attribute_target_data(_format: str) -> str:
    if ("explode:" in _format.lower()):
        return format_attribute_target_data_explode(_format)
    elif("nested:" in _format.lower()):
        return format_attribute_target_data_nested(_format)
    else:
        return _format

def formatAttributeTargetDataFormatList(AttributeTargetDataFormat:list) -> list:

    
    formatAttributeTargetDataFormat = [f'{format_attribute_target_data(_format)}'for _format in AttributeTargetDataFormat]

    return formatAttributeTargetDataFormat

# def formatAttributeTargetDataFormatList(AttributeTargetDataFormat:list) -> list:

#     AttributeTargetDataFormatLowercase = [x.lower() for x in AttributeTargetDataFormat]

#     formatAttributeTargetDataFormat = [f'{format_attribute_target_data(_format)}'for _format in AttributeTargetDataFormatLowercase]

#     return formatAttributeTargetDataFormat

# COMMAND ----------

from typing import List

def format_decimal(col_type_list: List[str]) -> List[str]:
    """
    Handles formatting for exploded columns.
    """
    return [f"{col_type.replace('comma', ',')}" for col_type in col_type_list]

# Not sure we want this! Captured by explode?
def format_explode(col_format: str, col_type: str) -> str:
    """
    Handles formatting for exploded columns.
    """
    return f"cast({col_format} as {col_type})"

def format_timestamp(col_name: str, col_format: str) -> str:
    """
    Handles formatting for timestamp columns.
    """
    if col_format == 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ':
        return f"to_timestamp({col_name})"
    elif '_exploded' in col_format:
        return f"to_timestamp({col_format})"
    elif '_nested' in col_format:
        return f"to_timestamp({col_format.replace('_nested', '')})"
    else:
        return f"to_timestamp({col_name},'{col_format.replace('`','')}')"

def format_date(col_name: str, col_format: str) -> str:
    """
    Handles formatting for date columns.
    """
    if col_format == '':
        return f"to_date({col_name})"
    elif '_exploded' in col_format:
        return f"to_date({col_format})"
    elif '_nested' in col_format:
        return f"to_date({col_format.replace('_nested', '')})"
    else:
        return f"to_date({col_name},'{col_format.replace('`','')}')"

def format_general(col_name: str, col_type: str, col_format: str) -> str:
    """
    Handles general column formatting.
    """
    if '_exploded' in col_format:
        return f"cast({col_format} as {col_type})"
    elif '_nested' in col_format:
        return f"cast({col_format.replace('_nested', '')} as {col_type})"
    else:
        return f"cast({col_name} as {col_type})"

def format_sql_column(col_name: str, col_type: str, col_format: str) -> str:
    """
    Formats a single SQL column using the appropriate schema enforcement logic.
    """
    if col_type == "timestamp":
        return format_timestamp(col_name, col_format)
    elif col_type == "date":
        return format_date(col_name, col_format)
    else:
        return format_general(col_name, col_type, col_format)

def format_column(column: str) -> str:
    """
    Format a single column name: convert to lowercase and replace dots with backticks.
    Handles cases with indices such as '[0]'.
    """
    # Split column to separate parts before and after indices
    parts = re.split(r"(\[\d+\])", column)
    # Replace dots with backticks only in the main part (before indices)
    parts[0] = f"`{parts[0]}`"
    return "".join(parts)

def format_column_names(column_list: List[str], replace_dot: bool = False) -> List[str]:
    """
    Format column names based on input list.
    If replace_dot is True, replaces dots with backticks for hierarchical names.
    """
    if replace_dot:
        return [f'{format_column(col).replace(".", "`.`")}' for col in column_list]
    return [f'{col}' for col in column_list]


def format_column_names_lower(column_list: List[str], replace_dot: bool = False) -> List[str]:
    """
    Format column names based on input list.
    If replace_dot is True, replaces dots with backticks for hierarchical names.
    """
    if replace_dot:
        return [f'{format_column(col.lower()).replace(".", "`.`")}' for col in column_list]
    return [f'{col.lower()}' for col in column_list]

def format_column_types(column_type_list: List[str]) -> List[str]:
    """
    Convert all column types to lowercase.
    """
    return [col_type.lower() for col_type in column_type_list]

def generate_sql_format_strings(
    column_names: List[str],
    column_types: List[str],
    column_formats: List[str]
) -> List[str]:
    """
    Generate SQL format strings based on column properties.
    """
    return [
        format_sql_column(col_name, col_type, col_format)
        for col_name, col_type, col_format in zip(
            column_names, column_types, column_formats
        )
    ]

def selectSqlColumnsFormatString(
    total_column_list: List[str], 
    total_column_type_list: List[str], 
    total_column_format_list: List[str]
) -> str:
    """
    Main function to format SQL columns.
    """
    clean_column_names = format_column_names(total_column_list, replace_dot=True)
    clean_column_formats = format_column_names(total_column_format_list, replace_dot=True)
    column_types = format_column_types(total_column_type_list)
    clean_column_types = format_decimal(column_types)

    sql_format_strings = generate_sql_format_strings(
        clean_column_names, clean_column_types, clean_column_formats
    )

    clean_column_names_removed_forbidden_characters = [format_column_name_remove_forbidden_characters(col) for col in clean_column_names]

    sql_format_strings_alias = [f"{format_string} as {col_name}" for format_string, col_name in zip(sql_format_strings, clean_column_names_removed_forbidden_characters)]
    
    return ", ".join(sql_format_strings_alias)



# COMMAND ----------

