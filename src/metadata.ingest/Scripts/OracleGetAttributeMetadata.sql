/* 

ORACLE GET DATASET ATTRIBUTES METADATA

How the script works:
For the provided schema name (OWNER) and table name (TABLE_NAME), the script gets the required metadata about the table, and populates INSERT statements for each attribute in the table.
The metadata includes the Attribute name, source data type info, target data type info and primary key and partition by markers, required for merging data into the Cleansed Delta Table.

Before running
- Confirm that you have access to the Oracle instance and schema with the credentials you are using.
- Ensure that a record for this Dataset is populated in the ingest.Datasets table. This is essential for passing the DatasetId as a Foreign Key value in each Attribute you wish to populate in the metadata ingest.Attributes table.

User input:
Please update references to the OWNER and TABLE_NAME at every occurrence.
Copy the QueryString Column produced as the output of the query, and use paste to a SSMS window to insert the results to the Metadata DB ingest.Attributes table.
Update the reference to the TABLE_NAME in the VALUES clause of the statement pasted to SSMS.
For example INSERT INTO ingest.Attributes (...) VALUES ('[TABLE_NAME]',...)
You need to replace '[TABLE_NAME]' with the DatasetId found for the Dataset in ingest.Datasets table, e.g. 1, if this is your first insert.
You can validate the DatasetId with the following query:
SELECT DatasetId
FROM ingest.DatasetId
WHERE SchemaName = 'OWNER' 
AND TableName = 'TABLE_NAME';

Run the insert!

Notes:
This script dynamically populates on assumptions and known data types. Before executing, please verify the following:
- Data Types are specified correctly, with no null values in the AttributeTargetDataType column. 
- AttributeTargetDataFormat is correct. This mostly relates to Date and Time formats, which can pop up in a variety of ways. When dealing with RDMS sources, these are usually populated correctly, but is cautionary for other source formats, such as CSVs which rely on user input more frequently.
- Any PkAttributes are selected correctly
- PartitionBy attributes are selected, as you deem fit in the Delta Table.
- THIS SCRIPT IS DESIGNED TO SPEED UP THE METADATA INGESTION PROCESS. IT STILL REQUIRES HUMAN OBSERVATION TO ENSURE VALUES ARE CORRECTLY SPECIFIED. 

*/
-- Script written in PLSQL so must be commented out for successful deployment
/* 
WITH pk_columns AS (
    SELECT acc.COLUMN_NAME, acc.TABLE_NAME
    FROM ALL_CONS_COLUMNS acc
    JOIN ALL_CONSTRAINTS ac 
        ON acc.OWNER = ac.OWNER 
        AND acc.CONSTRAINT_NAME = ac.CONSTRAINT_NAME
    WHERE ac.CONSTRAINT_TYPE = 'P'
      AND ac.OWNER = 'FSC'
      AND acc.TABLE_NAME = 'ADMIN_UNITS'
),
cte AS (
    SELECT 
        col.column_name, 
        CASE 
            WHEN col.DATA_TYPE = 'NVARCHAR2' THEN col.DATA_TYPE || '(' || TO_CHAR(col.CHAR_LENGTH) || ')'
            WHEN col.DATA_TYPE = 'NUMBER' THEN col.DATA_TYPE || '(' || TO_CHAR(col.DATA_PRECISION) || ',' || TO_CHAR(col.DATA_SCALE) || ')'
            ELSE col.DATA_TYPE
        END AS DATA_TYPE_FORMATTED,
        CASE 
            WHEN col.DATA_TYPE = 'NUMBER' THEN col.DATA_TYPE || '(' || TO_CHAR(col.DATA_PRECISION) || ',' || TO_CHAR(col.DATA_SCALE) || ')'
            ELSE col.DATA_TYPE
        END AS DATA_TYPE_JOIN,
        CASE 
            WHEN pk.COLUMN_NAME IS NOT NULL THEN 1
            ELSE 0
        END AS PkAttribute,
        CASE 
            WHEN col.column_name LIKE '%FK' THEN 1
            ELSE 0
        END AS PartitionByAttribute,
        col.DATA_TYPE, 
        col.TABLE_NAME, 
        col.COLUMN_ID AS ORDINAL_POSITION
    FROM ALL_TAB_COLUMNS col
    LEFT JOIN pk_columns pk 
        ON col.COLUMN_NAME = pk.COLUMN_NAME
        AND col.TABLE_NAME = pk.TABLE_NAME
    WHERE col.OWNER = 'FSC'
      AND col.TABLE_NAME = 'ADMIN_UNITS'
),
cte2 AS (
        SELECT 
        'NVARCHAR2' AS AttributeSourceDataType,
        'STRING' AS AttributeTargetDataType,
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'VARCHAR2' AS AttributeSourceDataType, 
        'STRING' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER(2,0)' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER(4,0)' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER(8,0)' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER(10,0)' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'DATE' AS AttributeSourceDataType, 
        'TIMESTAMP' AS AttributeTargetDataType, 
        'yyyy-MM-dd HH:mm:ss' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'RAW' AS AttributeSourceDataType, 
        'INTEGER' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'CHAR' AS AttributeSourceDataType, 
        'BOOLEAN' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'BLOB' AS AttributeSourceDataType, 
        'BINARY' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    UNION ALL
    SELECT 
        'NUMBER(8,2)' AS AttributeSourceDataType, 
        'decimal(8,2)' AS AttributeTargetDataType, 
        '' AS AttributeTargetDataFormat
    FROM DUAL
    )
SELECT 
    'INSERT INTO ingest.Attributes ([DatasetFK],[AttributeName],[AttributeSourceDataType],[AttributeTargetDataType], [AttributeTargetDataFormat],[PkAttribute],[PartitionByAttribute],[Enabled]) VALUES (' || '''[' || TABLE_NAME || ']' || ''',''' || COLUMN_NAME || ''',''' || DATA_TYPE_FORMATTED || ''',''' ||
    AttributeTargetDataType || ''',''' ||
    AttributeTargetDataFormat || ''',' ||
    TO_CHAR(PkAttribute) || ',' ||
    TO_CHAR(PartitionByAttribute)  || ',' ||
    '1);' AS QueryString,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE_FORMATTED,
    AttributeTargetDataType,
    AttributeTargetDataFormat,
    NULL AS AttributeDescription,
    PkAttribute,
    PartitionByAttribute,
    1 AS Enabled
FROM cte 
LEFT JOIN cte2
    ON cte.DATA_TYPE_JOIN = cte2.AttributeSourceDataType
ORDER BY TABLE_NAME, ORDINAL_POSITION;


*/