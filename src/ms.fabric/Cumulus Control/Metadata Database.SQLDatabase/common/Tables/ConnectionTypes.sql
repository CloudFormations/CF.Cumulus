CREATE TABLE [common].[ConnectionTypes] (
    [ConnectionTypeId]          INT           IDENTITY (1, 1) NOT NULL,
    [SourceLanguageType]        VARCHAR (5)   NULL,
    [ConnectionTypeDisplayName] NVARCHAR (50) NOT NULL,
    [Enabled]                   BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([ConnectionTypeId] ASC)
);


GO

