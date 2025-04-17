CREATE TABLE [ingest].[Datasets] (
    [DatasetId]                       INT            IDENTITY (1, 1) NOT NULL,
    [ConnectionFK]                    INT            NOT NULL,
    [MergeComputeConnectionFK]        INT            NULL,
    [DatasetDisplayName]              NVARCHAR (50)  NOT NULL,
    [SourcePath]                      NVARCHAR (100) NOT NULL,
    [SourceName]                      NVARCHAR (100) NOT NULL,
    [ExtensionType]                   NVARCHAR (20)  NULL,
    [VersionNumber]                   INT            NOT NULL,
    [VersionValidFrom]                DATETIME2 (7)  NULL,
    [VersionValidTo]                  DATETIME2 (7)  NULL,
    [LoadType]                        CHAR (1)       NOT NULL,
    [LoadStatus]                      INT            NULL,
    [LoadClause]                      NVARCHAR (MAX) NULL,
    [RawLastFullLoadDate]             DATETIME2 (7)  NULL,
    [RawLastIncrementalLoadDate]      DATETIME2 (7)  NULL,
    [CleansedPath]                    NVARCHAR (100) NOT NULL,
    [CleansedName]                    NVARCHAR (100) NOT NULL,
    [CleansedLastFullLoadDate]        DATETIME2 (7)  NULL,
    [CleansedLastIncrementalLoadDate] DATETIME2 (7)  NULL,
    [Enabled]                         BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([DatasetId] ASC),
    CONSTRAINT [chkDatasetDisplayNameNoSpaces] CHECK (NOT [DatasetDisplayName] like '% %')
);


GO

