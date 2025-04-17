CREATE TABLE [ingest].[apirequestlogging] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [IdentityToken]        NVARCHAR (MAX) NULL,
    [IdentityTokenExpires] DATETIME2 (7)  NULL,
    [RefreshToken]         NVARCHAR (MAX) NULL,
    [RefreshTokenExpires]  DATETIME2 (7)  NULL
);


GO

