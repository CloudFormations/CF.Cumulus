from CreateMergeQueryClasses import *


GENERAL_COLUMN_TYPES = ['string','integer']

column_name, column_type, column_format = ['NoProblems','STRING','']
allowed_characters_rule = 'allow_all'


def looper(column_name, column_type, column_format,allowed_characters_rule):
    if column_type.lower() in GENERAL_COLUMN_TYPES:
        formatter = FormatColumn(column_name, column_type, column_format)
    elif 'decimal' in column_type.lower():
        formatter = DecimalFormatColumn(column_name, column_type, column_format)
    elif column_type.lower() == 'date':
        formatter = DateFormatColumn(column_name, column_type, column_format)
    elif column_type.lower() == 'timestamp':
        formatter = TimestampFormatColumn(column_name, column_type, column_format)
    else:
        raise ValueError('The chosen column_type is not valid.')

    true_column_name = formatter.true_column_name(allowed_characters_rule)
    column_format_string = formatter.column_format_string(true_column_name)

    print()
    print(column_format_string)


for allowed_characters_rule in ['allow_all','num_char_only','spark_only']:
    columns_metadata = [
        ['NoProblems.String','STRING',''],
        ['NoProblems_Decimal','DECIMAL',''],
        ['NoProblems.DecimalComma','DECIMAL(10comma2)',''],
        ['NoProblems.Date','DATE',''],
        ['NoProblems DateFmt','DATE','YYYY-mm-dd'],
        ['NoProblems-Timestamp','TIMESTAMP',''],
        ['NoProblemsTimestampFmt','TIMESTAMP','YY-mm-d HH:MM:ss'],
        ['NoProblemsNestedDecimal','DECIMAL','NESTED:(No.Problems)'],
        ['NoProblemsNestedDate','DATE','NESTED:(No.Problems)'],
        ['NoProblemsNestedTimestamp','TIMESTAMP','NESTED:(No.Problems)'],
        ['NoProblemsExplode','TIMESTAMP','NESTED:(No.Problems)'],
        ]
    for column_name, column_type, column_format in columns_metadata:
        looper(column_name, column_type, column_format,allowed_characters_rule)
    print()
    print()