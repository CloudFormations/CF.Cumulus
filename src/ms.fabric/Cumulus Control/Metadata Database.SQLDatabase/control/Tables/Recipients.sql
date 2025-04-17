CREATE TABLE [control].[Recipients] (
    [RecipientId]       INT            IDENTITY (1, 1) NOT NULL,
    [Name]              VARCHAR (255)  NULL,
    [EmailAddress]      NVARCHAR (500) NOT NULL,
    [MessagePreference] CHAR (3)       DEFAULT ('TO') NOT NULL,
    [Enabled]           BIT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Recipients] PRIMARY KEY CLUSTERED ([RecipientId] ASC),
    CONSTRAINT [MessagePreferenceValue] CHECK ([MessagePreference]='BCC' OR [MessagePreference]='CC' OR [MessagePreference]='TO'),
    CONSTRAINT [UK_EmailAddressMessagePreference] UNIQUE NONCLUSTERED ([EmailAddress] ASC, [MessagePreference] ASC)
);


GO

