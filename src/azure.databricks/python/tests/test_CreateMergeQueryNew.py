from notebooks.ingest.utils.CreateMergeQuery3 import format_column_name_remove_forbidden_characters,rename_column_as_format 


class TestFormatColumnNameRemoveForbiddenCharacters():
    def test_format_column_name_remove_forbidden_characters_standard(self):
        actual1 = format_column_name_remove_forbidden_characters(column="NoProblems",allowed_chars=None)
        expected1 = "NoProblems"
        assert actual1 == expected1

        actual2 = format_column_name_remove_forbidden_characters(column="NoProblems")
        expected2 = "NoProblems"
        assert actual2 == expected2

        actual3 = format_column_name_remove_forbidden_characters(column="NoProblems",allowed_chars="num_char_only")
        expected3 = "NoProblems"
        assert actual3 == expected3

        actual4 = format_column_name_remove_forbidden_characters(column="NoProblems",allowed_chars="spark_only")
        expected4 = "NoProblems"
        assert actual4 == expected4
    
    def test_format_column_name_remove_forbidden_characters_standard_space(self):
        actual1 = format_column_name_remove_forbidden_characters(column="Name with spaces",allowed_chars=None)
        expected1 = "Name with spaces"
        assert actual1 == expected1

        actual2 = format_column_name_remove_forbidden_characters(column="Name with spaces")
        expected2 = "Name with spaces"
        assert actual2 == expected2

        actual3 = format_column_name_remove_forbidden_characters(column="Name with spaces",allowed_chars="num_char_only")
        expected3 = "Namewithspaces"
        assert actual3 == expected3

        actual4 = format_column_name_remove_forbidden_characters(column="Name with spaces",allowed_chars="spark_only")
        expected4 = "Namewithspaces"
        assert actual4 == expected4

    def test_format_column_name_remove_forbidden_characters_standard_spark_dot(self):
        actual1 = format_column_name_remove_forbidden_characters(column="Spark._Dots",allowed_chars=None)
        expected1 = "Spark.Dots"
        assert actual1 == expected1

        actual2 = format_column_name_remove_forbidden_characters(column="Spark.Dots")
        expected2 = "Spark.Dots"
        assert actual2 == expected2

        actual3 = format_column_name_remove_forbidden_characters(column="Spark.Dots",allowed_chars="num_char_only")
        expected3 = "SparkDots"
        assert actual3 == expected3

        actual4 = format_column_name_remove_forbidden_characters(column="Spark.Dots",allowed_chars="spark_only")
        expected4 = "SparkDots"
        assert actual4 == expected4

    def test_format_column_name_remove_forbidden_characters_standard_spark_dot(self):
        actual1 = format_column_name_remove_forbidden_characters(column="Spark._DotsUnderscore",allowed_chars=None)
        expected1 = "Spark._DotsUnderscore"
        assert actual1 == expected1

        actual2 = format_column_name_remove_forbidden_characters(column="Spark._DotsUnderscore")
        expected2 = "Spark._DotsUnderscore"
        assert actual2 == expected2

        actual3 = format_column_name_remove_forbidden_characters(column="Spark._DotsUnderscore",allowed_chars="num_char_only")
        expected3 = "SparkDotsUnderscore"
        assert actual3 == expected3

        actual4 = format_column_name_remove_forbidden_characters(column="Spark._DotsUnderscore",allowed_chars="spark_only")
        expected4 = "Spark_DotsUnderscore"
        assert actual4 == expected4


    def test_format_column_name_remove_forbidden_characters_standard_spark_all(self):
        actual1 = format_column_name_remove_forbidden_characters(column=",;{}().\n\t=Example string with illegal characters.,;{}().\n\t=",allowed_chars=None)
        expected1 = ",;{}().\n\t=Example string with illegal characters.,;{}().\n\t="
        assert actual1 == expected1

        actual2 = format_column_name_remove_forbidden_characters(column=",;{}().\n\t=Example string with illegal characters.,;{}().\n\t=")
        expected2 = ",;{}().\n\t=Example string with illegal characters.,;{}().\n\t="
        assert actual2 == expected2

        actual3 = format_column_name_remove_forbidden_characters(column=",;{}().\n\t=Example string with illegal characters.,;{}().\n\t=",allowed_chars="num_char_only")
        expected3 = "Examplestringwithillegalcharacters"
        assert actual3 == expected3

        actual4 = format_column_name_remove_forbidden_characters(column=",;{}().\n\t=Example string with illegal characters.,;{}().\n\t=",allowed_chars="spark_only")
        expected4 = "Examplestringwithillegalcharacters"
        assert actual4 == expected4


class TestRenameColumnAsFormat():
    def test_rename_column_as_format_false(self):
        actual = rename_column_as_format(column='MyColumn', _format='')
        expected = 'MyColumn'
        assert actual == expected

    def test_rename_column_as_format_true(self):
        actual = rename_column_as_format(column='MyNewColumn', _format='rename:(MyColumn)')
        expected = 'MyNewColumn'
        assert actual == expected