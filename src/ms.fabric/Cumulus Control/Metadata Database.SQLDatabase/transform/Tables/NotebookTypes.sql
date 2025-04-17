CREATE TABLE [transform].[NotebookTypes] (
    [NotebookTypeId]   INT            IDENTITY (1, 1) NOT NULL,
    [NotebookTypeName] NVARCHAR (100) NOT NULL,
    [Enabled]          BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([NotebookTypeId] ASC)
);


GO

