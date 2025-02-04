# Databricks notebook source
# MAGIC %md
# MAGIC # Initialise

# COMMAND ----------

# Set abfss initialisation
# Set abfss paths
# Check abfss exists

# COMMAND ----------

# MAGIC %md
# MAGIC # Code

# COMMAND ----------

def selectSqlColumnsFormatString(totalColumnList:list,totalColumnTypeList:list, totalColumnFormatList:list) -> list:
    
    totalColumnListLowercase = [x.lower() for x in totalColumnList]
    totalColumnTypeListLowercase = [x.lower() for x in totalColumnTypeList]
    # Note we do not want totalColumnFormatList in lowercase

    sqlFormat = [
        f"to_timestamp({str(col)},'{_format}') as {str(col)}" if _type == "timestamp" and _format != 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ'
        else f"to_timestamp({str(col)}) as {str(col)}" if (_type == "timestamp" and _format == 'yyyy-MM-ddTHH:mm:ss.SSSSSSSZ')
        else f"to_date({str(col)},'{_format}') as {str(col)}" if _type == "date" 
        else f"{str(_format)} as {str(col)}" if "_exploded" in _format and not "." in _format
        else f"cast({_format} as {_type}) as {str(col)}" if "_exploded" in _format and "." in _format
        else f"cast({str(col)} as {_type}) as {str(col)}"
        for col,_type,_format in zip(totalColumnListLowercase,totalColumnTypeListLowercase, totalColumnFormatList)
        ]
        
    totalColumnStr = ", ".join(sqlFormat)
    return totalColumnStr

def selectSqlExplodedOptionString(totalColumnList:list,totalColumnTypeList:list, totalColumnFormatList:list) -> list:

    totalColumnListLowercase = [x.lower() for x in totalColumnList]
    totalColumnTypeListLowercase = [x.lower() for x in totalColumnTypeList]
    totalColumnFormatListLowercase = [x.lower() for x in totalColumnFormatList]

    unstructuredFormat = [
        f'lateral view explode({(_format.split(".")[0]).replace("explode:","")}) as {(_format.split(".")[0]).replace("explode:","")}_exploded' if ("explode:" in _format and "." in _format)
        else f'lateral view explode({_format.replace("explode:","")}) as {_format.replace("explode:","")}_exploded' if ("explode:" in _format and not "." in _format)
        # else f"cast({str(col)} as {_type}) as {str(col)}"
        else ''
        for col,_type,_format in zip(totalColumnListLowercase,totalColumnTypeListLowercase, totalColumnFormatListLowercase)
        ]
        
    # deduplicate
    unstructuredFormatUnique =  list(dict.fromkeys(unstructuredFormat)) 

    # to string
    unstructuredFormatStr = (" ".join(unstructuredFormatUnique)).strip()
    return unstructuredFormatStr

def formatAttributeTargetDataFormatList(AttributeTargetDataFormat:list) -> list:

    AttributeTargetDataFormatLowercase = [x.lower() for x in AttributeTargetDataFormat]
    
    formatAttributeTargetDataFormat = [
        _str.replace("explode:","").replace('.','_exploded.') if ("explode:" in _str and "." in _str)
        else f'{_str.replace("explode:","")}_exploded' if ("explode:" in _str and not "." in _str)
        else ''
        for _str in AttributeTargetDataFormatLowercase]

    return formatAttributeTargetDataFormat

# COMMAND ----------

# MAGIC %md
# MAGIC # Unit Tests

# COMMAND ----------

# MAGIC %md
# MAGIC ## SQL Columns Format String

# COMMAND ----------

#separate test col and type name not empty

# COMMAND ----------

import unittest

class TestSelectSqlColumnsFormatString(unittest.TestCase):

    # def test_selectSqlColumnsFormatStringEmpty(self):
    #     actual = selectSqlColumnsFormatString([''],[''], [''])
    #     expected = raise Exception
    #     self.assertException(actual, expected)

    def test_selectSqlColumnsFormatStringInt1(self):
        actual = selectSqlColumnsFormatString(['age'],['int'], [''])
        expected = 'cast(age as int) as age'
        self.assertEqual(actual, expected)
    
    def test_selectSqlColumnsFormatStringIntWithFormat(self):
        actual = selectSqlColumnsFormatString(['age'],['int'], ['1'])
        expected = 'cast(age as int) as age'
        self.assertEqual(actual, expected)
    
    def test_selectSqlColumnsFormatStringInt2(self):
        actual = selectSqlColumnsFormatString(['age', 'number'],['int', 'int'], ['',''])
        expected = 'cast(age as int) as age, cast(number as int) as number'
        self.assertEqual(actual, expected)

    def test_selectSqlColumnsFormatStringString1(self):
        actual = selectSqlColumnsFormatString(['name'],['string'], [''])
        expected = 'cast(name as string) as name'
        self.assertEqual(actual, expected)
    
    def test_selectSqlColumnsFormatStringStringWithFormat(self):
        actual = selectSqlColumnsFormatString(['name'],['string'], ['txt'])
        expected = 'cast(name as string) as name'
        self.assertEqual(actual, expected)

    def test_selectSqlColumnsFormatStringString2(self):
        actual = selectSqlColumnsFormatString(['name', 'hobby'],['string', 'string'], ['',''])
        expected = 'cast(name as string) as name, cast(hobby as string) as hobby'
        self.assertEqual(actual, expected)

    def test_selectSqlColumnsFormatStringIntAndString(self):
        actual = selectSqlColumnsFormatString(['name', 'age'],['string', 'int'], ['',''])
        expected = 'cast(name as string) as name, cast(age as int) as age'
        self.assertEqual(actual, expected)
    
    def test_selectSqlColumnsFormatStringTimestampFormatType1(self):
        actual1 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyy-MM-dd'])
        expected1 = "to_timestamp(time,'yyyy-MM-dd') as time"
        actual2 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyy-MM-dd HH:mm'])
        expected2 = "to_timestamp(time,'yyyy-MM-dd HH:mm') as time"
        actual3 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyy-MM-dd HH'])
        expected3 = "to_timestamp(time,'yyyy-MM-dd HH') as time"
        actual4 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyy/MM/dd HH:mm:ss'])
        expected4 = "to_timestamp(time,'yyyy/MM/dd HH:mm:ss') as time"
        actual5 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyyMMdd HH:mm:ss'])
        expected5 = "to_timestamp(time,'yyyyMMdd HH:mm:ss') as time"
        actual6 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyMMd HH:mm:ss'])
        expected6 = "to_timestamp(time,'yyMMd HH:mm:ss') as time"
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
        self.assertEqual(actual3, expected3)
        self.assertEqual(actual4, expected4)
        self.assertEqual(actual5, expected5)
        self.assertEqual(actual6, expected6)

    def test_selectSqlColumnsFormatStringTimestampFormatType2(self):
        actual1 = selectSqlColumnsFormatString(['time'],['timestamp'], ['yyyy-MM-ddTHH:mm:ss.SSSSSSSZ'])
        expected1 = "to_timestamp(time) as time"
        

    # def test_selectSqlColumnsFormatStringTimestampLongFormat(self):
    #     with self.assertRaises(Exception) as context:
    #         checkSurrogateKey(surrogateKey="")
    #     expected = "Surrogate Key is a blank string. Please ensure this is populated for Curated tables."
    #     self.assertTrue(expected in str(context.exception))
    
    # def test_selectSqlColumnsFormatStringDate(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

    # def test_selectSqlColumnsFormatStringArrayUnstructured(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

    # def test_selectSqlColumnsFormatStringExplodedFormat(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

    # def test_selectSqlColumnsFormatStringOther(self):
    #     actual = checkSurrogateKey(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Explode Lateral View Format String

# COMMAND ----------

import unittest

class TestSelectSqlExplodedOptionString(unittest.TestCase):
    def test_selectSqlExplodedOptionStringNoReplace(self):
        actual1 = selectSqlExplodedOptionString(totalColumnList=['age'],totalColumnTypeList=['int'], totalColumnFormatList=[''])
        expected1 = ""
        actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age'],totalColumnTypeList=['string','int'], totalColumnFormatList=['',''])
        expected2 = ""
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_selectSqlExplodedOptionStringSingleReplaceLevel1(self):
        actual1 = selectSqlExplodedOptionString(totalColumnList=['result'],totalColumnTypeList=['array','array'], totalColumnFormatList=['EXPLODE:result'])
        expected1 = "lateral view explode(result) as result_exploded"
        actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id'],totalColumnTypeList=['string','int','int'], totalColumnFormatList=['','','EXPLODE:result'])
        expected2 = "lateral view explode(result) as result_exploded"
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)

    def test_selectSqlExplodedOptionStringMultiReplaceLevel1(self):
        actual1 = selectSqlExplodedOptionString(totalColumnList=['result','output'],totalColumnTypeList=['array','array'], totalColumnFormatList=['EXPLODE:result','EXPLODE:output'])
        expected1 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
        actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','result','output'],totalColumnTypeList=['string','int','array','array'], totalColumnFormatList=['','','EXPLODE:result','EXPLODE:output'])
        expected2 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_selectSqlExplodedOptionStringSingleReplaceLevel2(self):
        actual1 = selectSqlExplodedOptionString(totalColumnList=['id'],totalColumnTypeList=['int'], totalColumnFormatList=['EXPLODE:result.id'])
        expected1 = "lateral view explode(result) as result_exploded"
        actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id'],totalColumnTypeList=['string','int','int'], totalColumnFormatList=['','','EXPLODE:result.id'])
        expected2 = "lateral view explode(result) as result_exploded"
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)

    def test_selectSqlExplodedOptionStringMultiReplaceMixedLevels(self):
        actual1 = selectSqlExplodedOptionString(totalColumnList=['id','output'],totalColumnTypeList=['id','array'], totalColumnFormatList=['EXPLODE:result.id','EXPLODE:output'])
        expected1 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
        actual2 = selectSqlExplodedOptionString(totalColumnList=['name','age','id','output'],totalColumnTypeList=['string','int','int','array'], totalColumnFormatList=['','','EXPLODE:result.id','EXPLODE:output'])
        expected2 = "lateral view explode(result) as result_exploded lateral view explode(output) as output_exploded"
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)



# COMMAND ----------

# MAGIC %md
# MAGIC ## Explode Column Format String

# COMMAND ----------

import unittest

class TestFormatAttributeTargetDataFormatList(unittest.TestCase):
    def test_formatAttributeTargetDataFormatListNoReplace(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= [''])
        expected1 = ['']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','',''])
        expected2 = ['','','']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_formatAttributeTargetDataFormatListSingleReplaceLevel1(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result'])
        expected1 = ['result_exploded']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result'])
        expected2 = ['','','result_exploded']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)

    def test_formatAttributeTargetDataFormatListSingleReplaceLevel2(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result.id'])
        expected1 = ['result_exploded.id']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result.id'])
        expected2 = ['','','result_exploded.id']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_formatAttributeTargetDataFormatListMultiReplaceLevel1(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:output'])
        expected1 = ['result_exploded','output_exploded']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result','EXPLODE:output'])
        expected2 = ['','','result_exploded','output_exploded']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_formatAttributeTargetDataFormatListMultiReplaceLevel2(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result.id','EXPLODE:output.value'])
        expected1 = ['result_exploded.id','output_exploded.value']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result.id','EXPLODE:output.value'])
        expected2 = ['','','result_exploded.id','output_exploded.value']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
    
    def test_formatAttributeTargetDataFormatListMultiReplaceMixedLevels(self):
        actual1 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:result.id'])
        expected1 = ['result_exploded','result_exploded.id']
        actual2 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['EXPLODE:result','EXPLODE:result.id','EXPLODE:output.value'])
        expected2 = ['result_exploded','result_exploded.id','output_exploded.value']
        actual3 = formatAttributeTargetDataFormatList(AttributeTargetDataFormat= ['','','EXPLODE:result','EXPLODE:output.value'])
        expected3 = ['','','result_exploded','output_exploded.value']
        self.assertEqual(actual1, expected1)
        self.assertEqual(actual2, expected2)
        self.assertEqual(actual3, expected3)
        
    # def test_formatAttributeTargetDataFormatListNestedSingleReplace(self):
    #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

    # def test_formatAttributeTargetDataFormatListNestedMultiReplace(self):
    #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

    # def test_formatAttributeTargetDataFormatListMultiLayerReplace(self):
    #     actual = formatAttributeTargetDataFormatList(surrogateKey="StringValue")
    #     expected = True
    #     self.assertEqual(actual, expected)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Run tests

# COMMAND ----------

r = unittest.main(argv=[''], verbosity=2, exit=False)
assert r.result.wasSuccessful(), 'Test failed; see logs above'

# COMMAND ----------

