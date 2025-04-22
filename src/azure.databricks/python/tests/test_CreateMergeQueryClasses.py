from notebooks.ingest.utils.CreateMergeQueryClasses import format_column_name_allow_num_char_only, format_column_name_remove_spark_forbidden_characters, format_column_name_all_characters, format_exploded_column, FormatColumn, DecimalFormatColumn, DateFormatColumn, TimestampFormatColumn

import pytest

class TestFormatColumnNameAllowNumCharOnly():
    def test_format_column_name_allow_num_char_only(self):
        actual = format_column_name_allow_num_char_only(column="NoProblems")
        expected = "NoProblems"
        assert actual == expected

    # Add more

class TestFormatColumnNameRemoveSparkForbiddenCharacters():
    def test_format_column_name_remove_spark_forbidden_characters(self):
        actual = format_column_name_remove_spark_forbidden_characters(column="NoProblems")
        expected = "NoProblems"
        assert actual == expected

    # Add more

class TestFormatColumnNameAllCharacters():
    def test_format_column_name_all_characters(self):
        actual = format_column_name_all_characters(column="NoProblems")
        expected = "NoProblems"
        assert actual == expected

class TestFormatExplodeColumn():
    def test_format_exploded_column(self):
        column_format = ''
        actual = format_exploded_column(column_format)
        expected = None
        assert actual == expected

class TestFormatColumnTrueColumnName():
    def test_true_column_name_num_char_only_no_changes(self):
        column_name = "NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = FormatColumn(column_name, column_type, column_format)

        actual = format_column.true_column_name(allowed_characters_rule="num_char_only")
        expected = "NoProblems"
        assert actual == expected
        
        column_name2 = "No Problems"
        format_column2 = FormatColumn(column_name2, column_type, column_format)

        actual2 = format_column2.true_column_name(allowed_characters_rule="num_char_only")
        expected2 = "NoProblems"
        assert actual2 == expected2
    
        column_name3 = "No_Problems"
        format_column3 = FormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="num_char_only")
        expected3 = "NoProblems"
        assert actual3 == expected3

    def test_true_column_name_spark_only(self):
        column_name = "NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = FormatColumn(column_name, column_type, column_format)
        actual = format_column.true_column_name(allowed_characters_rule="spark_only")
        expected = "NoProblems"
        assert actual == expected

        column_name2 = "No Problems"
        format_column2 = FormatColumn(column_name2, column_type, column_format)
        actual2 = format_column2.true_column_name(allowed_characters_rule="spark_only")
        expected2 = "NoProblems"
        assert actual2 == expected2

        column_name3 = "No_Problems"
        format_column3 = FormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="spark_only")
        expected3 = "No_Problems"
        assert actual3 == expected3
        
        column_name4="No.Problems"
        format_column4 = FormatColumn(column_name4, column_type, column_format)
        actual4 = format_column4.true_column_name(allowed_characters_rule="spark_only")
        expected4 = "NoProblems"
        assert actual4 == expected4

    def test_true_column_name_num_all_characters(self):
        column_name="NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = FormatColumn(column_name, column_type, column_format)
        actual = format_column.true_column_name(allowed_characters_rule="allow_all")
        expected = "NoProblems"
        assert actual == expected

        column_name2="No Problems"
        format_column2 = FormatColumn(column_name2, column_type, column_format)
        actual2 = format_column2.true_column_name(allowed_characters_rule="allow_all")
        expected2 = "No Problems"
        assert actual2 == expected2

        column_name3="No_Problems"
        format_column3 = FormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="allow_all")
        expected3 = "No_Problems"
        assert actual3 == expected3

        column_name4="No.Problems"
        format_column4 = FormatColumn(column_name4, column_type, column_format)
        actual4 = format_column4.true_column_name(allowed_characters_rule="allow_all")
        expected4 = "No.Problems"
        assert actual4 == expected4

    def test_true_column_name_num_raise_key_error(self):
        column_name="NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = FormatColumn(column_name, column_type, column_format)
        with pytest.raises(KeyError):
            format_column.true_column_name(allowed_characters_rule="invalid_key")
        
        with pytest.raises(KeyError):
            format_column.true_column_name(allowed_characters_rule="")
    
class TestFormatColumnFormatString():
    def test_column_format_string(self):
        column_name="NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = FormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "cast(`NoProblems` as STRING) as `NoProblem`"
        assert actual == expected

class TestDecimalFormatColumnFixDecimalType():
    def test_fix_decimal_type_declare(self):
        column_name = "NoProblems"
        column_type = "decimal(10comma2)"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        actual = format_column.fix_decimal_type(column_type)
        expected = "decimal(10,2)"
        assert actual == expected

        column_type2 = "decimal(20comma4)"
        format_column2 = DecimalFormatColumn(column_name, column_type2, column_format)
        actual2 = format_column2.fix_decimal_type(column_type2)
        expected2 = "decimal(20,4)"
        assert actual2 == expected2

        column_type3 = "decimal(10)"
        format_column3 = DecimalFormatColumn(column_name, column_type3, column_format)
        actual3 = format_column3.fix_decimal_type(column_type3)
        expected3 = "decimal(10)"
        assert actual3 == expected3
        
        column_type4 = "decimal()"
        format_column4 = DecimalFormatColumn(column_name, column_type4, column_format)
        actual4 = format_column4.fix_decimal_type(column_type4)
        expected4 = "decimal()"
        assert actual4 == expected4

    def test_fix_decimal_type_auto_declare(self):
        column_name = "NoProblems"
        column_type = "decimal(10comma2)"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_type
        expected = "decimal(10,2)"
        assert actual == expected

        column_type2 = "decimal(20comma4)"
        format_column2 = DecimalFormatColumn(column_name, column_type2, column_format)
        actual2 = format_column2.column_type
        expected2 = "decimal(20,4)"
        assert actual2 == expected2

        column_type3 = "decimal(10)"
        format_column3 = DecimalFormatColumn(column_name, column_type3, column_format)
        actual3 = format_column3.column_type
        expected3 = "decimal(10)"
        assert actual3 == expected3
        
        column_type4 = "decimal()"
        format_column4 = DecimalFormatColumn(column_name, column_type4, column_format)
        actual4 = format_column4.column_type
        expected4 = "decimal()"
        assert actual4 == expected4

class TestDecimalFormatColumnTrueColumnName():
    def test_true_column_name_num_char_only_no_changes(self):
        column_name = "NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)

        actual = format_column.true_column_name(allowed_characters_rule="num_char_only")
        expected = "NoProblems"
        assert actual == expected
        
        column_name2 = "No Problems"
        format_column2 = DecimalFormatColumn(column_name2, column_type, column_format)

        actual2 = format_column2.true_column_name(allowed_characters_rule="num_char_only")
        expected2 = "NoProblems"
        assert actual2 == expected2
    
        column_name3 = "No_Problems"
        format_column3 = DecimalFormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="num_char_only")
        expected3 = "NoProblems"
        assert actual3 == expected3

    def test_true_column_name_spark_only(self):
        column_name = "NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        actual = format_column.true_column_name(allowed_characters_rule="spark_only")
        expected = "NoProblems"
        assert actual == expected

        column_name2 = "No Problems"
        format_column2 = DecimalFormatColumn(column_name2, column_type, column_format)
        actual2 = format_column2.true_column_name(allowed_characters_rule="spark_only")
        expected2 = "NoProblems"
        assert actual2 == expected2

        column_name3 = "No_Problems"
        format_column3 = DecimalFormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="spark_only")
        expected3 = "No_Problems"
        assert actual3 == expected3
        
        column_name4="No.Problems"
        format_column4 = DecimalFormatColumn(column_name4, column_type, column_format)
        actual4 = format_column4.true_column_name(allowed_characters_rule="spark_only")
        expected4 = "NoProblems"
        assert actual4 == expected4

    def test_true_column_name_num_all_characters(self):
        column_name="NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        actual = format_column.true_column_name(allowed_characters_rule="allow_all")
        expected = "NoProblems"
        assert actual == expected

        column_name2="No Problems"
        format_column2 = DecimalFormatColumn(column_name2, column_type, column_format)
        actual2 = format_column2.true_column_name(allowed_characters_rule="allow_all")
        expected2 = "No Problems"
        assert actual2 == expected2

        column_name3="No_Problems"
        format_column3 = DecimalFormatColumn(column_name3, column_type, column_format)
        actual3 = format_column3.true_column_name(allowed_characters_rule="allow_all")
        expected3 = "No_Problems"
        assert actual3 == expected3

        column_name4="No.Problems"
        format_column4 = DecimalFormatColumn(column_name4, column_type, column_format)
        actual4 = format_column4.true_column_name(allowed_characters_rule="allow_all")
        expected4 = "No.Problems"
        assert actual4 == expected4

    def test_true_column_name_num_raise_key_error(self):
        column_name="NoProblems"
        column_type = "STRING"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        with pytest.raises(KeyError):
            format_column.true_column_name(allowed_characters_rule="invalid_key")
        
        with pytest.raises(KeyError):
            format_column.true_column_name(allowed_characters_rule="")

class TestDecimalFormatColumnFormatString():
    def test_column_format_string(self):
        column_name="NoProblems"
        column_type = "decimal(10comma2)"
        column_format = ""
        format_column = DecimalFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "cast(`NoProblems` as decimal(10,2)) as `NoProblem`"
        assert actual == expected

class TestDateFormatColumnFormatString():
    def test_column_format_string_with_blank_format_string(self):
        column_name="NoProblems"
        column_type = "date"
        column_format = ""
        format_column = DateFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "to_date(`NoProblems`) as `NoProblem`"
        assert actual == expected

    def test_column_format_string_with_format_string(self):
        column_name="NoProblems"
        column_type = "date"
        column_format = "YYYY-mm-dd"
        format_column = DateFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "to_date(`NoProblems`,'YYYY-mm-dd') as `NoProblem`"
        assert actual == expected

        column_format2 = "YYYYmmdd"
        format_column2 = DateFormatColumn(column_name, column_type, column_format2)
        actual2 = format_column2.column_format_string(true_column_name= "NoProblem")
        expected2 = "to_date(`NoProblems`,'YYYYmmdd') as `NoProblem`"
        assert actual2 == expected2

class TestTimestampFormatColumnFormatString():
    def test_column_format_string_with_blank_format_string(self):
        column_name="NoProblems"
        column_type = "timestamp"
        column_format = ""
        format_column = TimestampFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "to_timestamp(`NoProblems`) as `NoProblem`"
        assert actual == expected

    def test_column_format_string_with_default_format_string(self):
        column_name="NoProblems"
        column_type = "timestamp"
        column_format = "yyyy-MM-ddTHH:mm:ss.SSSSSSSZ"
        format_column = TimestampFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "to_timestamp(`NoProblems`) as `NoProblem`"
        assert actual == expected

    def test_column_format_string_with_format_string(self):
        column_name="NoProblems"
        column_type = "timestamp"
        column_format = "yyyy/MM/ddTHH:mm:ss.SSSSSSSZ"
        format_column = TimestampFormatColumn(column_name, column_type, column_format)
        actual = format_column.column_format_string(true_column_name= "NoProblem")
        expected = "to_timestamp(`NoProblems`,'yyyy/MM/ddTHH:mm:ss.SSSSSSSZ') as `NoProblem`"
        assert actual == expected

        column_format2 = "ddMMyy HH:mm:ss"
        format_column2 = TimestampFormatColumn(column_name, column_type, column_format2)
        actual2 = format_column2.column_format_string(true_column_name= "NoProblem")
        expected2 = "to_timestamp(`NoProblems`,'ddMMyy HH:mm:ss') as `NoProblem`"
        assert actual2 == expected2

class TestNestedFormatColumnString():
    def test_1(self):
        pass