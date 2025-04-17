CREATE TABLE [ingest].[Attributes] (
    [AttributeId]               INT            IDENTITY (1, 1) NOT NULL,
    [DatasetFK]                 INT            NULL,
    [AttributeName]             NVARCHAR (50)  NOT NULL,
    [AttributeSourceDataType]   NVARCHAR (50)  NULL,
    [AttributeTargetDataType]   NVARCHAR (50)  NULL,
    [AttributeTargetDataFormat] VARCHAR (100)  NULL,
    [AttributeDescription]      NVARCHAR (500) NULL,
    [PkAttribute]               BIT            NOT NULL,
    [PartitionByAttribute]      BIT            NOT NULL,
    [Enabled]                   BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([AttributeId] ASC),
    FOREIGN KEY ([DatasetFK]) REFERENCES [ingest].[Datasets] ([DatasetId])
);


GO

