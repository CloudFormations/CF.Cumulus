CREATE TABLE [common].[Connections] (
    [ConnectionId]          INT            IDENTITY (1, 1) NOT NULL,
    [ConnectionTypeFK]      INT            NOT NULL,
    [ConnectionDisplayName] NVARCHAR (50)  NOT NULL,
    [ConnectionLocation]    NVARCHAR (200) NULL,
    [ConnectionPort]        NVARCHAR (50)  NULL,
    [SourceLocation]        NVARCHAR (200) NOT NULL,
    [ResourceName]          NVARCHAR (100) NULL,
    [LinkedServiceName]     NVARCHAR (200) NOT NULL,
    [Username]              NVARCHAR (100) NOT NULL,
    [KeyVaultSecret]        NVARCHAR (100) NOT NULL,
    [Enabled]               BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([ConnectionId] ASC),
    CONSTRAINT [chkConnectionDisplayNameNoSpaces] CHECK (NOT [ConnectionDisplayName] like '% %'),
    CONSTRAINT [FK__Connectio__Conne__361203C5] FOREIGN KEY ([ConnectionTypeFK]) REFERENCES [common].[ConnectionTypes] ([ConnectionTypeId])
);


GO

