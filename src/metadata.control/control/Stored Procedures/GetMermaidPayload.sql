CREATE PROCEDURE [control].[GetMermaidPayload] (
	@MarkdownTargetId INT
)
AS
BEGIN
    DECLARE @CountRows INT;

    SELECT @CountRows = COUNT(*)
    FROM [control].[MarkdownTargets]
    WHERE MarkdownTargetId = @MarkdownTargetId

    IF @CountRows = 0
    BEGIN
        RAISERROR('No results returned for the provided Markdown Target Id. Confirm Markdown Target Page is present and enabled.',16,1)
        RETURN 0;
    END

    IF @CountRows > 1
    BEGIN
        RAISERROR('Multiple results returned for the provided Markdown Target Id. Confirm Markdown Target Page is present and enabled, with no duplicates.',16,1)
        RETURN 0;
    END

    SELECT *
    FROM [control].[MarkdownTargets]
    WHERE MarkdownTargetId = @MarkdownTargetId

END