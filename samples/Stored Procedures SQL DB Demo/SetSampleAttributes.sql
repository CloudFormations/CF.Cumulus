CREATE PROCEDURE [samples].[SetSampleAttributes]

AS
BEGIN


DECLARE @Attributes TABLE
		(
		[DatasetDisplayName] [nvarchar](100) NOT NULL,
		[VersionNumber] [bit] NOT NULL,
		[DatasetFK] [int] NULL,
		[AttributeName] [nvarchar](50) NOT NULL,
		[AttributeSourceDataType] [nvarchar](50) NULL,
		[AttributeTargetDataType] [nvarchar](50) NULL,
		[AttributeTargetDataFormat] [varchar](100) NULL,
		[AttributeDescription] [nvarchar](500) NULL,
		[PkAttribute] [bit] NOT NULL,
		[PartitionByAttribute] [bit] NOT NULL,
		[Enabled] [bit] NOT NULL
		)
	
	INSERT @Attributes
		(
		[DatasetDisplayName],
		[VersionNumber],
		[DatasetFK],
		[AttributeName],
		[AttributeSourceDataType],
		[AttributeTargetDataType],
		[AttributeTargetDataFormat],
		[AttributeDescription],
		[PkAttribute],
		[PartitionByAttribute],
		[Enabled]
		) 
	VALUES

  ('SalesOrderHeader',1,0,'SalesOrderID','int','INTEGER','NULL','',1,0,1),
  ('SalesOrderHeader',1,0,'RevisionNumber','tinyint','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'OrderDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('SalesOrderHeader',1,0,'DueDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('SalesOrderHeader',1,0,'ShipDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('SalesOrderHeader',1,0,'Status','tinyint','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'OnlineOrderFlag','bit','BOOLEAN','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'SalesOrderNumber','nvarchar(25)','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'PurchaseOrderNumber','nvarchar(25)','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'AccountNumber','nvarchar(15)','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'CustomerID','int','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'ShipToAddressID','int','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'BillToAddressID','int','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'ShipMethod','nvarchar(50)','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'CreditCardApprovalCode','varchar','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'SubTotal','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'TaxAmt','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'Freight','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'TotalDue','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'Comment','nvarchar(-1)','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'rowguid','uniqueidentifier','STRING','NULL','',0,0,1),
  ('SalesOrderHeader',1,0,'ModifiedDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),

  ('SalesOrderDetail',1,0,'SalesOrderID','int','INTEGER','NULL','',1,0,1),
  ('SalesOrderDetail',1,0,'SalesOrderDetailID','int','INTEGER','NULL','',1,0,1),
  ('SalesOrderDetail',1,0,'OrderQty','smallint','INTEGER','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'ProductID','int','INTEGER','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'UnitPrice','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'UnitPriceDiscount','money','INTEGER','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'LineTotal','numeric','INTEGER','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'rowguid','uniqueidentifier','STRING','NULL','',0,0,1),
  ('SalesOrderDetail',1,0,'ModifiedDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),

  ('Product',1,0,'ProductID','int','INTEGER','','',1,0,1),
  ('Product',1,0,'Name','nvarchar(50)','STRING','','',0,0,1),
  ('Product',1,0,'ProductNumber','nvarchar(25)','STRING','','',0,0,1),
  ('Product',1,0,'Color','nvarchar(15)','STRING','','',0,0,1),
  ('Product',1,0,'StandardCost','money','INTEGER','','',0,0,1),
  ('Product',1,0,'ListPrice','money','INTEGER','','',0,0,1),
  ('Product',1,0,'Size','nvarchar(5)','STRING','','',0,0,1),
  ('Product',1,0,'Weight','decimal(8,2)','decimal(8comma2)','','',0,0,1),
  ('Product',1,0,'ProductCategoryID','int','INTEGER','','',0,0,1),
  ('Product',1,0,'ProductModelID','int','INTEGER','','',0,0,1),
  ('Product',1,0,'SellStartDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('Product',1,0,'SellEndDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('Product',1,0,'DiscontinuedDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1),
  ('Product',1,0,'ThumbNailPhoto','varbinary','BINARY','','',0,0,1),
  ('Product',1,0,'ThumbnailPhotoFileName','nvarchar(50)','STRING','','',0,0,1),
  ('Product',1,0,'rowguid','uniqueidentifier','STRING','','',0,0,1),
  ('Product',1,0,'ModifiedDate','datetime','TIMESTAMP','yyyy-MM-dd HH:mm:ss','',0,0,1);

	UPDATE a
	SET a.DatasetFK = d.DatasetId
	FROM @Attributes AS a
	INNER JOIN [ingest].[Datasets] AS d
	ON 	a.DatasetDisplayName = d.DatasetDisplayName
	AND	a.VersionNumber = d.VersionNumber

MERGE INTO [ingest].[Attributes] AS tgt
	USING 
		@Attributes AS src
			ON 	tgt.[AttributeName] = src.[AttributeName]
			AND tgt.[DatasetFK] = src.[DatasetFK]
	WHEN MATCHED THEN
		UPDATE
		SET
			tgt.[AttributeSourceDataType] = src.[AttributeSourceDataType],
			tgt.[AttributeTargetDataType] = src.[AttributeTargetDataType],
			tgt.[AttributeTargetDataFormat] = src.[AttributeTargetDataFormat],
			tgt.[AttributeDescription] = src.[AttributeDescription],
			tgt.[PkAttribute] = src.[PkAttribute],
			tgt.[PartitionByAttribute] = src.[PartitionByAttribute],
			tgt.[Enabled] = src.[Enabled]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[DatasetFK],
			[AttributeName],
			[AttributeSourceDataType],
			[AttributeTargetDataType],
			[AttributeTargetDataFormat],
			[AttributeDescription],
			[PkAttribute],
			[PartitionByAttribute],
			[Enabled]
			)
		VALUES
			(
			src.[DatasetFK],
			src.[AttributeName],
			src.[AttributeSourceDataType],
			src.[AttributeTargetDataType],
			src.[AttributeTargetDataFormat],
			src.[AttributeDescription],
			src.[PkAttribute],
			src.[PartitionByAttribute],
			src.[Enabled]
			);
END;