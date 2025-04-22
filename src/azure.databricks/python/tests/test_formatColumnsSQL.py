from notebooks.utils.CreateDeltaObjectsT import formatColumnsSQL

class TestFormatColumnsSQL():
    def test_formatColumnsSQL_basic(self) -> None:
        actual = formatColumnsSQL(['col1'],['type1'])
        expected = f"`col1` type1"
        assert actual ==  expected
    
        actual2 = formatColumnsSQL(['col1','col2'],['type1','type2'])
        expected2 = f"`col1` type1, `col2` type2"
        assert actual2 ==  expected2
