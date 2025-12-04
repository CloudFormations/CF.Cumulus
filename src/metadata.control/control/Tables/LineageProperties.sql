CREATE TABLE [control].[LineageProperties] 
    (
    [PropertyId]        [int] IDENTITY (1, 1) NOT NULL,
    [PropertyName]    NVARCHAR(50) NOT NULL,
    [PropertyValue]    NVARCHAR(250) NOT NULL,
    [Description]       VARCHAR(MAX) NULL,
    [ValidFrom] [datetime] CONSTRAINT [DF_LineageProperties_ValidFrom] DEFAULT (GETDATE()) NOT NULL,
	[ValidTo] [datetime] NULL,
    [Enabled] BIT NOT NULL,
    CONSTRAINT [PK_LineageProperties] PRIMARY KEY CLUSTERED ([PropertyId] ASC, [PropertyName] ASC)
    );