CREATE TABLE [control].[MarkdownTargets]
(
    [MarkdownTargetId]     INT IDENTITY (1, 1)  NOT NULL,
    [MarkdownTargetName]   NVARCHAR(100)        NOT NULL,   -- e.g., AzureDevOps, Confluence, GitHubWiki
    [BatchName]            NVARCHAR(255)        NOT NULL,   -- e.g., Daily
    [PATSecretName]        NVARCHAR(200)        NOT NULL,   -- Key Vault secret name for PAT/token
    [URLSecretName]        NVARCHAR(200)        NOT NULL,   -- Key Vault secret name for base URL
    [WikiPagePath]         NVARCHAR(400)        NOT NULL,   -- e.g., /Mermaid
    [Description]          NVARCHAR(500)        NULL,       -- Optional documentation
    [CreatedOn]            DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    [Enabled]              BIT                  NOT NULL
    PRIMARY KEY CLUSTERED 
(
	[MarkdownTargetId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
);