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

def format_exploded_column(column_format: str) -> str:
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
    pass


class FormatColumn():
    def __init__(self, column_name: str, column_type: str, column_format: str):
        self.COLUMN_NAME_FORMAT_RULES = {
            "num_char_only": format_column_name_allow_num_char_only,
            "spark_only": format_column_name_remove_spark_forbidden_characters,
            "allow_all": format_column_name_all_characters,
        }
        self.column_name = column_name
        self.column_type = column_type
        self.column_format = column_format

    def true_column_name(self, allowed_characters_rule: str):
        try:
            format_column_name_fcn = self.COLUMN_NAME_FORMAT_RULES[allowed_characters_rule]
            return format_column_name_fcn(self.column_name)
        except KeyError:
            raise KeyError(f"Invalid allowed_characters_rule: '{allowed_characters_rule}' specified.")

    def column_format_string(self, true_column_name: str) -> str:
        return f'cast(`{self.column_name}` as {self.column_type}) as `{true_column_name}`'



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
            return f"to_date(`{self.column_name}`) as `{true_column_name}`" 
        else:
            return f"to_date(`{self.column_name}`,'{self.column_format}') as `{true_column_name}`" 
        

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
            return f"to_timestamp(`{self.column_name}`) as `{true_column_name}`" 
        elif self.column_format == "yyyy-MM-ddTHH:mm:ss.SSSSSSSZ":
            return f"to_timestamp(`{self.column_name}`) as `{true_column_name}`" 
        else:
            return f"to_timestamp(`{self.column_name}`,'{self.column_format}') as `{true_column_name}`" 
    

class NestedFormatColumn(FormatColumn):
    def __init__(self, column_name: str, column_type: str, column_format: str):
        super().__init__(column_name, column_type, column_format)

    # Abstraction of base class not required.
    def true_column_name(self, allowed_characters_rule: str):
        return super().true_column_name(allowed_characters_rule)
    

    def column_format_string(self, true_column_name: str) -> str:
        return f'cast(`{self.column_name}` as {self.column_type}) as `{true_column_name}`'
