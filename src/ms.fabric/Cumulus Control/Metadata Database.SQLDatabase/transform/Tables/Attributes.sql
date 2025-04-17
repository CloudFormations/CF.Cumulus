CREATE TABLE [transform].[Attributes] (
    [AttributeId]             INT            IDENTITY (1, 1) NOT NULL,
    [DatasetFK]               INT            NOT NULL,
    [AttributeName]           NVARCHAR (100) NOT NULL,
    [AttributeTargetDataType] NVARCHAR (50)  NULL,
    [AttributeDescription]    NVARCHAR (200) NULL,
    [BKAttribute]             BIT            NOT NULL,
    [SurrogateKeyAttribute]   BIT            NOT NULL,
    [PartitionByAttribute]    BIT            NOT NULL,
    [Enabled]                 BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([AttributeId] ASC),
    FOREIGN KEY ([DatasetFK]) REFERENCES [transform].[Datasets] ([DatasetId])
);


GO

