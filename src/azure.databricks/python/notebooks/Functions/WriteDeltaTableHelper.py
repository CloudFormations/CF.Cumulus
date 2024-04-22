# Databricks notebook source
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# COMMAND ----------

class DeltaHelper(object):
    """
    DocString
    """
    def __init__(self, spark: SparkSession = spark) -> None:
        return
 
    def createSchema(self, schemaName: str) -> None:
        """
        Summary:
            Create the schema for the Dataset being processed. Currently supports "cleansed" storage layer.
        
        Args:
            schemaName (str): Name of the schema to be created

        """
        createSchemaSQL = f"""
        CREATE SCHEMA IF NOT EXISTS {schemaName}
        """
        print(createSchemaSQL)
        spark.sql(createSchemaSQL)
        return
    
    def createTable(
            self, 
            tempViewName: str,
            containerName: str,
            schemaName: str, 
            tableName: str,
            abfssPath: str, 
            pfSQL: str
        ) -> None:
        """
        Summary:
            Create the table for the Dataset being processed. Currently supports "cleansed" storage layer.
        
        Args:
            tempViewName (str): Name of the temporary view created in Databricks for the Dataset
            containerName (str): Name of the ADLS storage container
            abfssPath (str): Name of the ADLS storage account
            schemaName (str): Name of the schema to create the table in
            tableName (str): Name of the target table. This will be created if it does not already exist using the schema of the source dataframe
            pfSQL (str): SQL Statement based on the partition fields for the Delta table

        """
        if containerName == "cleansed":
            createTableSQL = f"""
            CREATE TABLE IF NOT EXISTS {schemaName}.{tableName} 
            LOCATION '{abfssPath}{schemaName}/{tableName}'
            {pfSQL}AS SELECT * FROM {tempViewName}
            """
        else: 
            raise Exception(f'Container name ''{containerName}'' not supported.')
        print(createTableSQL)
        spark.sql(createTableSQL)
        return
    
    def partitionFieldsSQL(self, partitionFields: dict = []) -> str:
        """
        Summary:
            Create the SQL statement to partition dataset by the partition fields specified in the Transformation payload.
        
        Args:
            partitionFields (dict): Dictionary of Attributes in the dataset to partition the Delta table by.
        
        Returns:
            pfSQL (str): Spark SQL partition by clause containing the provided Attributes.
        """
        pfSQL = ''
        if len(partitionFields) > 0:
            pfSQL = "\nPARTITIONED BY (" + ",".join(f"{pf}" for pf in partitionFields) + ")\n"
        return pfSQL

    def checkDfSize(self, df: DataFrame) -> tuple[bool,dict]:
        """
        Summary:
            Confirm that the dataset provided is not empty (non-zero row count).
        
        Args:
            df (DataFrame): PySpark DataFrame of the data to be loaded.

        Returns:
            state (bool): Boolean state of the check, True if non-empty DataFrame
            output (dict): Output message to log that no rows were in the DataFrame for processing
        """
        if df.count() > 0:
            state = True
            output = {}
        else:
            status = False
            output = {"message": "No New Rows to Process"}
        return state, output
        
    def mergeSQL(self, tgt, df: DataFrame, pkFields: dict, partitionFields: dict = []) -> None:
        """
        Summary:
           Perform a Merge query for Incremental loading into the target Delta table for the Dataset.
        
        Args:
            df (DataFrame): PySpark DataFrame of the data to be loaded.
            pkFields (dict): Dictionary of the primary key fields.
            partitionFields (dict): Dictionary of the partition by fields.

        """
        (
            tgt.alias("tgt")
            .merge(
                source=df.alias("src"),
                condition="\nAND ".join(f"src.{pk} = tgt.{pk}" for pk in pkFields + partitionFields),
            )
            .whenNotMatchedInsertAll()
            .whenMatchedUpdateAll()
            .execute()
        )
        return
    
    def insertSQL(self, df: DataFrame, schemaName: str, tableName: str) -> None:
        """
        Summary:
           Perform an Insert query for appending data to the existing target Delta table for the Dataset.
        
        Args:
            df (DataFrame): PySpark DataFrame of the data to be loaded.
            schemaName (str): Name of the schema the dataset belongs to.
            tableName (str): Name of the target table for the dataset.

        """
        df.write.format("delta").mode("append").insertInto(f"{schemaName}.{tableName}")
        return

    def overwriteSQL(self, df: DataFrame, schemaName: str, tableName: str) -> None:
        """
        Summary:
           Perform an Overwrite query for the Dataset to replace data in an target Delta table.
        
        Args:
            df (DataFrame): PySpark DataFrame of the data to be loaded.
            schemaName (str): Name of the schema the dataset belongs to.
            tableName (str): Name of the target table for the dataset.

        """
        df.write.format("delta").mode("overwrite").insertInto(f"{schemaName}.{tableName}")
        return
    
    def getOperationMetrics(self, schemaName: str, tableName: str,output: dict) -> dict:
        """
        Summary:
           Query the history of the Delta table to get the operational metrics of the merge, append, insert transformation.
        
        Args:
            schemaName (str): Name of the schema the dataset belongs to.
            tableName (str): Name of the target table for the dataset.
            output (dict): Dictionary of metrics to be saved for logging purposes. 

        """
        operationMetrics = (
            spark.sql(f"DESCRIBE HISTORY {schemaName}.{tableName}")
            .orderBy(col("version").desc())
            .limit(1)
            .collect()[0]["operationMetrics"]
        )
        for metric, value in operationMetrics.items():
            output[f"mergeMetrics.{metric}"] = int(value)
        return output


    def writeToDelta(
        self,
        df: DataFrame,
        tempViewName: str,
        abfssPath: str,
        containerName: str,
        schemaName: str,
        tableName: str,
        pkFields: dict,
        partitionFields: dict = [],
        writeMode: str = "merge",
    ) -> tuple[dict, DataFrame]:
        """_summary_

        Args:
            df (DataFrame): _description_
            abfssPath (str): Underlying storage path for saving the table
            schemaName (str): Name of the schema to create the table in
            tableName (str): Name of the target table. This will be created if it does not already exist using the schema of the source dataframe
            pKList (dict): Primary Key fields for merging the DataFrame into the Table
            partitionFields (dict): Fields to partition target table by. Defaults to none
            writeMode (str): Either "insert" or "merge" 

        Returns:
            tuple[dict, DataFrame]: _description_
        """

        pfSQL = self.partitionFieldsSQL(partitionFields = partitionFields)
        print(pfSQL)

        self.createSchema(schemaName = schemaName)

        # folder hierarchy in transformed storage sourceName/tableName, partitioned by partition column where appropriate
        self.createTable(tempViewName = tempViewName, containerName = containerName, schemaName = schemaName, tableName = tableName, abfssPath = abfssPath, pfSQL = pfSQL)
        

        # wrap in function, from >
        dfSchema = df.schema.jsonValue()["fields"]

        fields = "\n,".join(f"`{field['name']}` {field['type']}" for field in dfSchema)

        tempDF = spark.createDataFrame(data=[],schema=df.schema)

        tempDF.createOrReplaceTempView('df')

        tgt = DeltaTable.forName(spark, f"{schemaName}.{tableName}")

        # < until

        dfDataFound, output = self.checkDfSize(df=df)

        # if dfDataFound :
        if writeMode.lower() == "merge":
            self.mergeSQL(df=df, pkFields=pkFields, partitionFields=partitionFields)
        elif writeMode.lower() == "insert":
            self.insertSQL(df, schemaName, tableName)
        elif writeMode.lower() == "overwrite":
            self.overwriteSQL(df, schemaName, tableName)

        output = self.getOperationMetrics(schemaName=schemaName, tableName=tableName, output=output)
        return output, df
