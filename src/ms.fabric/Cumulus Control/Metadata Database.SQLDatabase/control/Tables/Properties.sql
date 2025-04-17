CREATE TABLE [control].[Properties] (
    [PropertyId]    INT            IDENTITY (1, 1) NOT NULL,
    [PropertyName]  VARCHAR (128)  NOT NULL,
    [PropertyValue] NVARCHAR (MAX) NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [ValidFrom]     DATETIME       CONSTRAINT [DF_Properties_ValidFrom] DEFAULT (getdate()) NOT NULL,
    [ValidTo]       DATETIME       NULL,
    CONSTRAINT [PK_Properties] PRIMARY KEY CLUSTERED ([PropertyId] ASC, [PropertyName] ASC)
);


GO

