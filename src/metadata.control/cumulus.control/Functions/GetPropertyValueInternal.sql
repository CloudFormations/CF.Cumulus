CREATE FUNCTION [cumulus.control].[GetPropertyValueInternal]
	(
	@PropertyName VARCHAR(128)
	)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @PropertyValue NVARCHAR(MAX)

	SELECT
		@PropertyValue = ISNULL([PropertyValue],'')
	FROM
		[cumulus.control].[CurrentProperties]
	WHERE
		[PropertyName] = @PropertyName

    RETURN @PropertyValue
END;
