import re


def format_column_name_allow_num_char_only(column: str) -> str:
    return re.sub("[^0-9a-zA-Z$]+", "", column)

def format_column_name_remove_spark_forbidden_characters(column: str) -> str:
    replacement = ''  # Replace with your desired string
    pattern = r'[,\;\{\}\(\)\.\n\t= ]'
    return re.sub(pattern, replacement, column)

def format_column_name_all_characters(column:str) -> str:
    return column

def format_column_positional_element():
    """Function to handle positional list elements within a column.
    Requirements: 
        - col[]

    Args:
        column_format (str): _description_

    Returns:
        str: _description_
    """
    pass

def format_nested_column_name(column_name: str, column_format: str) -> str:
    """Function to handle nested columns, where forbidden dot character is required to be handled in spark sql.
    """
    if 'NESTED:' in column_format:
        column_format_stripped = column_format.replace('NESTED:(', '').replace(')','')
        column_format_dot_notation = column_format_stripped.replace('.','`.`')
        return column_format_dot_notation
    else: 
        return column_name
    
def format_nested_column_format(column_format: str) -> str:
    """Function to handle nested columns, where forbidden dot character is required to be handled in spark sql.
    """
    if 'NESTED:' in column_format:
        return ''
    else: 
        return column_format


class FormatExplode():
    def __init__(self):
        pass

    def lateral_view_statement():
        pass



def format_exploded_column_name(column_name: str, column_format: str) -> str:
    """Function to handle exploded columns.
    Requirements: 
        - col.subcolumn -> `col`.`subcol`
        - explode(col.subcolumn) as explode_col_name -> explode(`col`.`subcol`) as explode_col_name
        - cast(col.)

    Args:
        column_format (str): _description_

    Returns:
        str: _description_
    """
    if 'EXPLODE:' in column_format:
        column_format_stripped = column_format.replace('EXPLODE:(', '').split(')')[0]
        column_format_dot_notation = column_format_stripped.replace('.','`.`')
        return column_format_dot_notation
    else:
        return column_name


class FormatColumn():
    def __init__(self, column_name: str, column_type: str, column_format: str):
        self._column_name_format_rules = {
            "num_char_only": format_column_name_allow_num_char_only,
            "spark_only": format_column_name_remove_spark_forbidden_characters,
            "allow_all": format_column_name_all_characters,
        }
        self.column_name = column_name
        self.column_name_formatted = format_nested_column_name(column_name, column_format)
        self.column_type = column_type
        self.column_format = format_nested_column_format(column_format)

    def true_column_name(self, allowed_characters_rule: str):
        try:
            format_column_name_fcn = self._column_name_format_rules[allowed_characters_rule]
            return format_column_name_fcn(self.column_name)
        except KeyError:
            raise KeyError(f"Invalid allowed_characters_rule: '{allowed_characters_rule}' specified.")

    def column_format_string(self, true_column_name: str) -> str:
        return f'cast(`{self.column_name_formatted}` as {self.column_type}) as `{true_column_name}`'



class DecimalFormatColumn(FormatColumn):
    def __init__(self, column_name: str, column_type: str, column_format: str):
        super().__init__(column_name, column_type, column_format)
        self.column_type = self.fix_decimal_type(column_type)


    def fix_decimal_type(self, column_type: str) -> str:
        """
        Function to format a decimal column format. Due to upstream formatting dependencies,
        this will include 'comma' as a text string for any decimal columns that have a precision after
        the zero. 
        Example inputs: Example output 
        DECIMAL(10comma2): DECIMAL(10,2)
        DECIMAL(20comma4): DECIMAL(20,4)
        DECIMAL(10): DECIMAL(10)
        DECIMAL: DECIMAL

        Args:
            column_type (str): The format string for a decimal type data column.

        Returns:
            str: SPARK SQL formatted data type for a decimal
        """
        return column_type.replace('comma', ',')

    # Abstraction of base class not required.
    def true_column_name(self, allowed_characters_rule: str):
        return super().true_column_name(allowed_characters_rule)
    

    def column_format_string(self, true_column_name: str) -> str:
        return super().column_format_string(true_column_name)
    



class DateFormatColumn(FormatColumn):
    def __init__(self, column_name: str, column_type: str, column_format: str):
        super().__init__(column_name, column_type, column_format)

    
    def validate_format_string(self):
        """
        Run in-flight test against self.column_format to ensure that it can be handled downstream. 
        Fail-fast with useful error message.
        TBC
        """
        pass


    # Abstraction of base class not required.
    def true_column_name(self, allowed_characters_rule: str):
        return super().true_column_name(allowed_characters_rule)
    

    def column_format_string(self, true_column_name: str) -> str:
        if self.column_format == "":
            return f"to_date(`{self.column_name_formatted}`) as `{true_column_name}`" 
        else:
            return f"to_date(`{self.column_name_formatted}`,'{self.column_format}') as `{true_column_name}`" 
        

class TimestampFormatColumn(FormatColumn):
    def __init__(self, column_name: str, column_type: str, column_format: str):
        super().__init__(column_name, column_type, column_format)

    
    def validate_format_string(self):
        """
        Run in-flight test against self.column_format to ensure that it can be handled downstream. 
        Fail-fast with useful error message.
        TBC
        """
        pass


    # Abstraction of base class not required.
    def true_column_name(self, allowed_characters_rule: str):
        return super().true_column_name(allowed_characters_rule)
    

    def column_format_string(self, true_column_name: str) -> str:
        if self.column_format == "":
            return f"to_timestamp(`{self.column_name_formatted}`) as `{true_column_name}`" 
        elif self.column_format == "yyyy-MM-ddTHH:mm:ss.SSSSSSSZ":
            return f"to_timestamp(`{self.column_name_formatted}`) as `{true_column_name}`" 
        else:
            return f"to_timestamp(`{self.column_name_formatted}`,'{self.column_format}') as `{true_column_name}`" 
    


class SetSqlQuery():
    def __init__(self, schema_name: str, table_name: str, column_names: list, column_types: list, column_formats: list):
        self.schema_name = schema_name
        self.table_name = table_name
        self.column_names = column_names
        self.column_types = column_types
        self.column_formats = column_formats

        self._general_column_types = ['string', 'integer', 'double', 'float']
        
    def set_formatter(self,column_name: str, column_type: str, column_format: str):
        if self.column_type.lower() in self._general_column_types:
            formatter = FormatColumn(column_name, column_type, column_format)
        elif 'decimal' in column_type.lower():
            formatter = DecimalFormatColumn(column_name, column_type, column_format)
        elif column_type.lower() == 'date':
            formatter = DateFormatColumn(column_name, column_type, column_format)
        elif column_type.lower() == 'timestamp':
            formatter = TimestampFormatColumn(column_name, column_type, column_format)
        else:
            raise ValueError('The chosen column_type is not valid.')
        
    # Depends on other class
    def set_target_columns_list(self, allowed_characters_rule: str) -> list:
        target_columns_list = []
        for column_name, column_type, column_format in zip(self.column_names, self.column_types, self.column_formats):
            formatter = self.set_formatter(column_name, column_type, column_format)
            true_column_name = formatter.true_column_name(allowed_characters_rule)
            column_format_string = formatter.column_format_string(true_column_name)
            target_columns_list.append(column_format_string)
        return target_columns_list
        
    def set_column_string(self, target_columns_list: list) -> str:
        return ', \n'.join(target_columns_list)

    def set_additional_arguments(self):
        pass

    def set_full_query(self, column_string: str, additional_arguments: str) -> str:
        query = f"""
            SELECT {column_string}
            FROM {self.schema_name}.{self.table_name}
            {additional_arguments};
        """
        return query