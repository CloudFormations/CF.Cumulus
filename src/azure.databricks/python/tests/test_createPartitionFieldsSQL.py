from notebooks.utils.HelperFunctionsT import createPartitionFieldsSQL

class TestCreatePartitionFieldsSQL():
    def test_createPartitionFieldsSQL_single_column(self) -> None:
        actual = createPartitionFieldsSQL(['col1'])
        expected = "\nPARTITIONED BY (""col1"")\n"
        assert actual ==  expected

        actual2 = createPartitionFieldsSQL(['col2'])
        expected2 = "\nPARTITIONED BY (""col2"")\n"
        assert actual2 ==  expected2

    def test_createPartitionFieldsSQL_multi_columns(self) -> None:
        actual = createPartitionFieldsSQL(['col1','col2'])
        expected = "\nPARTITIONED BY (""col1"",""col2"")\n"
        assert actual ==  expected

        actual2 = createPartitionFieldsSQL(['col1','col2','col3'])
        expected2 = "\nPARTITIONED BY (""col1"",""col2"",""col3"")\n"
        assert actual2 ==  expected2
    
    def test_createPartitionFieldsSQL_empty_list(self) -> None:
        actual = createPartitionFieldsSQL([])
        expected = ""
        assert actual ==  expected