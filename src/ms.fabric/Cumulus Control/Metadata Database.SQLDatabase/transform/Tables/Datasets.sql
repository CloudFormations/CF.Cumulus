CREATE TABLE [transform].[Datasets] (
    [DatasetId]               INT            IDENTITY (1, 1) NOT NULL,
    [ComputeConnectionFK]     INT            NOT NULL,
    [CreateNotebookFK]        INT            NULL,
    [BusinessLogicNotebookFK] INT            NULL,
    [SchemaName]              NVARCHAR (100) NOT NULL,
    [DatasetName]             NVARCHAR (100) NOT NULL,
    [VersionNumber]           INT            NOT NULL,
    [VersionValidFrom]        DATETIME2 (7)  NULL,
    [VersionValidTo]          DATETIME2 (7)  NULL,
    [LoadType]                CHAR (1)       NOT NULL,
    [LoadStatus]              INT            NULL,
    [LastLoadDate]            DATETIME2 (7)  NULL,
    [Enabled]                 BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([DatasetId] ASC),
    FOREIGN KEY ([BusinessLogicNotebookFK]) REFERENCES [transform].[Notebooks] ([NotebookId]),
    FOREIGN KEY ([CreateNotebookFK]) REFERENCES [transform].[Notebooks] ([NotebookId])
);


GO

