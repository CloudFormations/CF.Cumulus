CREATE TABLE [transform].[Notebooks] (
    [NotebookId]     INT            IDENTITY (1, 1) NOT NULL,
    [NotebookTypeFK] INT            NOT NULL,
    [NotebookName]   NVARCHAR (100) NOT NULL,
    [NotebookPath]   NVARCHAR (500) NOT NULL,
    [Enabled]        BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([NotebookId] ASC),
    FOREIGN KEY ([NotebookTypeFK]) REFERENCES [transform].[NotebookTypes] ([NotebookTypeId])
);


GO

