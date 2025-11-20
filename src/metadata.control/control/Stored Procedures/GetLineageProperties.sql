CREATE PROCEDURE control.GetLineageProperties 
AS
BEGIN
    DECLARE @MarkdownTargetType VARCHAR(250);
    DECLARE @PATSecretName VARCHAR(250);
    DECLARE @URLSecretName VARCHAR(250);
    DECLARE @OverrideCustomMarkdownTargetType BIT;

    SELECT 
        @MarkdownTargetType = PropertyValue
    FROM control.LineageProperties
WHERE PropertyName = 'MarkdownTargetType';

    SELECT 
        @PATSecretName = PropertyValue
    FROM control.LineageProperties
    WHERE PropertyName = 'PATSecretName';

    SELECT 
        @URLSecretName = PropertyValue
    FROM control.LineageProperties
    WHERE PropertyName = 'URLSecretName';

    SELECT 
        @OverrideCustomMarkdownTargetType = PropertyValue
    FROM control.LineageProperties
    WHERE PropertyName = 'OverrideCustomMarkdownTargetType';
    

    IF @MarkdownTargetType NOT IN ('AzureDevOps', 'Local', 'GitHub') 
        AND @OverrideCustomMarkdownTargetType = 0
    BEGIN
        RAISERROR('Invalid Markdown target selected. Please review your site is supported, otherwise set the "OverrideCustomMarkdownTargetType" property to 1.',16,1)
        RETURN 0;
    END

    SELECT
        @MarkdownTargetType AS MarkdownTargetType,
        @PATSecretName AS PatSecretName,
        @URLSecretName AS URLSecretName
END;