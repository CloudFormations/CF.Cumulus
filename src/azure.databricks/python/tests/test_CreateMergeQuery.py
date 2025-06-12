from notebooks.ingest.utils.CreateMergeQuery import *


class TestSelectSqlColumnsFormatString():

    # def test_select_sql_columns_format_stringEmpty(self):
    #     actual = select_sql_columns_format_string([''],[''], [''])
    #     expected = raise Exception
    #     self.assertException(actual, expected)

    def test_select_sql_columns_format_string_int1(self):
        actual = select_sql_columns_format_string(['age'],['int'], [''])
        expected = 'cast(age as int) as age'
        assert actual == expected
    
    def test_select_sql_columns_format_string_int_with_format(self):
        actual = select_sql_columns_format_string(['age'],['int'], ['1'])
        expected = 'cast(age as int) as age'
        assert actual == expected
    
    def test_select_sql_columns_format_string_int2(self):
        actual = select_sql_columns_format_string(['age', 'number'],['int', 'int'], ['',''])
        expected = 'cast(age as int) as age, cast(number as int) as number'
        assert actual == expected

    def test_select_sql_columns_format_string_string1(self):
        actual = select_sql_columns_format_string(['name'],['string'], [''])
        expected = 'cast(name as string) as name'
        assert actual == expected
    
    def test_select_sql_columns_format_string_string_with_format(self):
        actual = select_sql_columns_format_string(['name'],['string'], ['txt'])
        expected = 'cast(name as string) as name'
        assert actual == expected

    def test_select_sql_columns_format_string_string2(self):
        actual = select_sql_columns_format_string(['name', 'hobby'],['string', 'string'], ['',''])
        expected = 'cast(name as string) as name, cast(hobby as string) as hobby'
        assert actual == expected

    def test_select_sql_columns_format_string_int_and_string(self):
        actual = select_sql_columns_format_string(['name', 'age'],['string', 'int'], ['',''])
        expected = 'cast(name as string) as name, cast(age as int) as age'
        assert actual == expected
    
    def test_select_sql_columns_format_string_timestamp_format_type1(self):
        actual1 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyy-MM-dd'])
        expected1 = "to_timestamp(time,'yyyy-MM-dd') as time"
        actual2 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyy-MM-dd HH:mm'])
        expected2 = "to_timestamp(time,'yyyy-MM-dd HH:mm') as time"
        actual3 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyy-MM-dd HH'])
        expected3 = "to_timestamp(time,'yyyy-MM-dd HH') as time"
        actual4 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyy/MM/dd HH:mm:ss'])
        expected4 = "to_timestamp(time,'yyyy/MM/dd HH:mm:ss') as time"
        actual5 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyyMMdd HH:mm:ss'])
        expected5 = "to_timestamp(time,'yyyyMMdd HH:mm:ss') as time"
        actual6 = select_sql_columns_format_string(['time'],['timestamp'], ['yyMMd HH:mm:ss'])
        expected6 = "to_timestamp(time,'yyMMd HH:mm:ss') as time"
        assert actual1 == expected1
        assert actual2 == expected2
        assert actual3 == expected3
        assert actual4 == expected4
        assert actual5 == expected5
        assert actual6 == expected6

    def test_select_sql_columns_format_string_timestamp_format_type2(self):
        actual1 = select_sql_columns_format_string(['time'],['timestamp'], ['yyyy-MM-ddTHH:mm:ss.SSSSSSSZ'])
        expected1 = "to_timestamp(time) as time"
        assert actual1 == expected1
        

    # def test_select_sql_columns_format_string_timestamp_long_format(self):
    #     with self.assertRaises(Exception) as context:
    #         checkSurrogateKey(surrogateKey="")
    #     expected = "Surrogate Key is a blank string. Please ensure this is populated for Curated tables."
    #     self.assertTrue(expected in str(context.exception))
    
    # def test_select_sql_columns_format_string_date(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     assert actual == expected

    # def test_select_sql_columns_format_string_array_unstructured(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     assert actual == expected

    # def test_select_sql_columns_format_string_exploded_format(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     assert actual == expected

    # def test_select_sql_columns_format_string_other(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     assert actual == expected



# class TestSelectSqlExplodedOptionString():
#     def test_selectSqlExplodedOptionStringNoReplace(self):
#         actual1 = selectSqlExplodedOptionString(totalColumnList=['age'],totalColumnTypeList=['int'], totalColumnFormatList=[''])
#         expected1 = ""
#         actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age'],totalColumnTypeList=['string','int'], totalColumnFormatList=['',''])
#         expected2 = ""
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_selectSqlExplodedOptionStringSingleReplaceLevel1(self):
#         actual1 = selectSqlExplodedOptionString(totalColumnList=['result'],totalColumnTypeList=['array','array'], totalColumnFormatList=['EXPLODE:result'])
#         expected1 = "lateral view explode(result) as result_exploded"
#         actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id'],totalColumnTypeList=['string','int','int'], totalColumnFormatList=['','','EXPLODE:result'])
#         expected2 = "lateral view explode(result) as result_exploded"
#         assert actual1 == expected1
        # assert actual2 == expected2

#     def test_selectSqlExplodedOptionStringMultiReplaceLevel1(self):
#         actual1 = selectSqlExplodedOptionString(totalColumnList=['result','output'],totalColumnTypeList=['array','array'], totalColumnFormatList=['EXPLODE:result','EXPLODE:output'])
#         expected1 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
#         actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','result','output'],totalColumnTypeList=['string','int','array','array'], totalColumnFormatList=['','','EXPLODE:result','EXPLODE:output'])
#         expected2 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_selectSqlExplodedOptionStringSingleReplaceLevel2(self):
#         actual1 = selectSqlExplodedOptionString(totalColumnList=['id'],totalColumnTypeList=['int'], totalColumnFormatList=['EXPLODE:result.id'])
#         expected1 = "lateral view explode(result) as result_exploded"
#         actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id'],totalColumnTypeList=['string','int','int'], totalColumnFormatList=['','','EXPLODE:result.id'])
#         expected2 = "lateral view explode(result) as result_exploded"
#         assert actual1 == expected1
#         assert actual2 == expected2

#     def test_selectSqlExplodedOptionStringMultiReplaceMixedLevels(self):
#         actual1 = selectSqlExplodedOptionString(totalColumnList=['id','output'],totalColumnTypeList=['id','array'], totalColumnFormatList=['EXPLODE:result.id','EXPLODE:output'])
#         expected1 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
#         actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id','output'],totalColumnTypeList=['string','int','int','array'], totalColumnFormatList=['','','EXPLODE:result.id','EXPLODE:output'])
#         expected2 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
#         assert actual1 == expected1
#         assert actual2 == expected2


# class TestFormatAttributeTargetDataFormatList():
#     def test_formatAttributeTargetDataFormatListNoReplace(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= [''])
#         expected1 = ['']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','',''])
#         expected2 = ['','','']
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_formatAttributeTargetDataFormatListSingleReplaceLevel1(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result'])
#         expected1 = ['result_exploded']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result'])
#         expected2 = ['','','result_exploded']
#         assert actual1 == expected1
#         assert actual2 == expected2

#     def test_formatAttributeTargetDataFormatListSingleReplaceLevel2(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result.id'])
#         expected1 = ['result_exploded.id']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result.id'])
#         expected2 = ['','','result_exploded.id']
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_formatAttributeTargetDataFormatListMultiReplaceLevel1(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:output'])
#         expected1 = ['result_exploded','output_exploded']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result','EXPLODE:output'])
#         expected2 = ['','','result_exploded','output_exploded']
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_formatAttributeTargetDataFormatListMultiReplaceLevel2(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result.id','EXPLODE:output.value'])
#         expected1 = ['result_exploded.id','output_exploded.value']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result.id','EXPLODE:output.value'])
#         expected2 = ['','','result_exploded.id','output_exploded.value']
#         assert actual1 == expected1
#         assert actual2 == expected2
    
#     def test_formatAttributeTargetDataFormatListMultiReplaceMixedLevels(self):
#         actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:result.id'])
#         expected1 = ['result_exploded','result_exploded.id']
#         actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:result.id','EXPLODE:output.value'])
#         expected2 = ['result_exploded','result_exploded.id','output_exploded.value']
#         actual3 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result','EXPLODE:output.value'])
#         expected3 = ['','','result_exploded','output_exploded.value']
#         assert actual1 == expected1
#         assert actual2 == expected2
#         assert actual3 == expected3
        
#     # def test_formatAttributeTargetDataFormatListNestedSingleReplace(self):
#     #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
#     #     expected = True
#     #     assert actual == expected

#     # def test_formatAttributeTargetDataFormatListNestedMultiReplace(self):
#     #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
#     #     expected = True
#     #     assert actual == expected

#     # def test_formatAttributeTargetDataFormatListMultiLayerReplace(self):
#     #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
#     #     expected = True
#     #     assert actual == expected
