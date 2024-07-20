/* 

DYNAMICS GET DATASET ATTRIBUTES METADATA

How the script works:
You will be required to use XrmToolkit with the SQL CDS 4 tool to run SQL queries against entities within the Dynamics workspace.
For the provided table name (via the variable @EntityLogicalName), the script gets the required metadata about the table, and populates INSERT statements for each attribute in the table.
Please note that the table name is the LOGICAL NAME within dynamics. Not the DISPLAY NAME seen in PowerApps.
The metadata includes the Attribute name, source data type info, target data type info and primary key and partition by markers, required for merging data into the Cleansed Delta Table.

Before running
- Confirm that you have access to the Dynamics workspace instance.
- Connect to the Dynamics workspace in XrmToolkit.
- Confirm that you have access to the required table by running a simple "select top 10 * from TableName" in a SQL Query Window within SQL CDS 4.
- Ensure that a record for this Dataset is populated in the ingest.Datasets table. This is essential for passing the DatasetId as a Foreign Key value in each Attribute you wish to populate in the metadata ingest.Attributes table.

User input:
Please update references to the @EntityLogicalName upon each execution
Copy the QueryString Column produced as the output of the query, and use paste to a SSMS window to insert the results to the Metadata DB ingest.Attributes table.
Update the reference to the DatasetFK in the VALUES clause of the statement pasted to SSMS.
For example INSERT INTO ingest.Attributes (...) VALUES ('[DatasetFK]',...)
You need to replace '[DatasetFK]' with the DatasetId found for the Dataset in ingest.Datasets table, e.g. 1, if this is your first insert.
You can validate the DatasetId with the following query:
SELECT DatasetId
FROM ingest.DatasetId
WHERE TableName = 'TableName';

Run the insert!

Notes:
This script dynamically populates on assumptions and known data types. Before executing, please verify the following:
- Data Types are specified correctly, with no null values in the AttributeTargetDataType column. 
- AttributeTargetDataFormat is correct. This mostly relates to Date and Time formats, which can pop up in a variety of ways. When dealing with RDMS sources, these are usually populated correctly, but is cautionary for other source formats, such as CSVs which rely on user input more frequently.
- Any PkAttributes are selected correctly
- PartitionBy attributes are selected, as you deem fit in the Delta Table.
- THIS SCRIPT IS DESIGNED TO SPEED UP THE METADATA INGESTION PROCESS. IT STILL REQUIRES HUMAN OBSERVATION TO ENSURE VALUES ARE CORRECTLY SPECIFIED. 

*/
-- Script contains DECLARE statements not allowed in Repo Scripts, so must be commented out for successful deployment
/* 
with cte as(
select 
    logicalname, 
    attributetype,
    case when description is null then '' else REPLACE(description,'''','''''') end as [description], 
    case when isprimaryid = 1 then '1' else '0' end as [pkattribute],
    '0' as [partitionbyattribute],
    '1' as [enabled]
from metadata.attribute as a 
where a.entitylogicalname = 'incident'
and isvalidforread = 1
),
cte2 as (
SELECT 
    'BigInt' AS AttributeSourceDataType, 
    'BIGINT' AS AttributeTargetDataType,
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Boolean' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Customer' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'DateTime' AS AttributeSourceDataType, 
    'TIMESTAMP' AS AttributeTargetDataType, 
    'yyyy-MM-dd HH:mm:ss' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Decimal' AS AttributeSourceDataType, 
    'DECIMAL' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Double' AS AttributeSourceDataType, 
    'DOUBLE' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'EntityName' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Integer' AS AttributeSourceDataType, 
    'INTEGER' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Lookup' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'ManagedProperty' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Memo' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Money' AS AttributeSourceDataType, 
    'DECIMAL' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Owner' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'PartyList' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Picklist' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'State' AS AttributeSourceDataType, 
    'INTEGER' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Status' AS AttributeSourceDataType, 
    'INTEGER' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'String' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Uniqueidentifier' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
UNION ALL
SELECT 
    'Virtual' AS AttributeSourceDataType, 
    'STRING' AS AttributeTargetDataType, 
    '' AS AttributeTargetDataFormat
)
select 'INSERT INTO ingest.Attributes 
    ([DatasetFK], [AttributeName], [AttributeSourceDataType], [AttributeTargetDataType], [AttributeTargetDataFormat], [AttributeDescription], [PkAttribute], [PartitionByAttribute], [Enabled]) 
    VALUES([DatasetFK],''' + cte.logicalname +''',''' + cte.attributetype + ''',''' + cte2.Attributetargetdatatype + ''',''' + cte2.Attributetargetdataformat + ''',''' + cte.description + ''',' + cte.pkattribute + ',' + cte.partitionbyattribute + ',' + cte.enabled + ')'
    
from cte
left join cte2 on cte.attributetype = cte2.attributesourcedatatype
*/