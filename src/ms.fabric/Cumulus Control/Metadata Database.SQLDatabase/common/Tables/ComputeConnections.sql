CREATE TABLE [common].[ComputeConnections] (
    [ComputeConnectionId]   INT            IDENTITY (1, 1) NOT NULL,
    [ConnectionTypeFK]      INT            NOT NULL,
    [ConnectionDisplayName] NVARCHAR (50)  NOT NULL,
    [ConnectionLocation]    NVARCHAR (200) NULL,
    [ComputeLocation]       NVARCHAR (200) NULL,
    [ComputeSize]           NVARCHAR (200) NOT NULL,
    [ComputeVersion]        NVARCHAR (100) NOT NULL,
    [CountNodes]            INT            NOT NULL,
    [ResourceName]          NVARCHAR (100) NULL,
    [LinkedServiceName]     NVARCHAR (200) NOT NULL,
    [EnvironmentName]       NVARCHAR (10)  NULL,
    [Enabled]               BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([ComputeConnectionId] ASC),
    CONSTRAINT [chkComputeConnectionDisplayNameNoSpaces] CHECK (NOT [ConnectionDisplayName] like '% %'),
    CONSTRAINT [FK__Connectio__Conne__361223C6] FOREIGN KEY ([ConnectionTypeFK]) REFERENCES [common].[ConnectionTypes] ([ConnectionTypeId])
);


GO

