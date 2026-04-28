/*
CREATE USER [cumulusfactorydev] 
FROM EXTERNAL PROVIDER
*/

CREATE ROLE [db_cumulususer]
GO

GRANT 
	EXECUTE, 
	SELECT,
	CONTROL,
	ALTER
ON SCHEMA::[control] TO [db_cumulususer]
GO

GRANT 
	EXECUTE, 
	SELECT,
	CONTROL,
	ALTER
ON SCHEMA::[dbo] TO [db_cumulususer]
GO

/*
ALTER ROLE [db_cumulususer] 
ADD MEMBER [cumulusfactorydev];
*/