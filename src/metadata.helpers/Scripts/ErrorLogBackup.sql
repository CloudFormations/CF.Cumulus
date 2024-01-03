IF OBJECT_ID(N'[dbo].[ErrorLogBackup]') IS NOT NULL DROP TABLE [dbo].[ErrorLogBackup];

IF OBJECT_ID(N'[control].[ErrorLog]') IS NOT NULL --check for new deployments
BEGIN
	SELECT 
		*
	INTO
		[dbo].[ErrorLogBackup]
	FROM
		[control].[ErrorLog];
END;