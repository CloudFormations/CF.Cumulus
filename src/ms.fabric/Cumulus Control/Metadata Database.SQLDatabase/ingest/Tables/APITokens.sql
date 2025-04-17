CREATE TABLE [ingest].[APITokens] (
    [APITokenId]                  INT            IDENTITY (1, 1) NOT NULL,
    [ConnectionFK]                INT            NULL,
    [IdentityToken]               NVARCHAR (MAX) NULL,
    [IdentityTokenExpiryDateTime] DATETIME2 (7)  NULL,
    [RefreshToken]                NVARCHAR (MAX) NULL,
    [RefreshTokenExpiryDateTime]  DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([APITokenId] ASC)
);


GO

