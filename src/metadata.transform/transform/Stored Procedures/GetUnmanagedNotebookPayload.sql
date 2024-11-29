CREATE PROCEDURE [transform].[GetUnmanagedNotebookPayload]
	(
	@DatasetId INT
	)
AS
BEGIN

    -- Defensive check for results returned
    DECLARE @ResultRowCount INT

    SELECT 
        @ResultRowCount = COUNT(*)
	FROM 
		[transform].[Datasets] AS ds
	INNER JOIN
		[transform].[Notebooks] AS n
	ON 
		n.NotebookId = ds.BusinessLogicNotebookFK
	INNER JOIN 
		[transform].[NotebookTypes] AS nt
	ON 
		n.NotebookTypeFK = nt.NotebookTypeId
	INNER JOIN 
		[common].[ComputeConnections] AS ccn
	ON
		ds.ComputeConnectionFK = ccn.ComputeConnectionId
	INNER JOIN
		[common].[Connections] AS cn
	ON 
		cn.ConnectionDisplayName = 'PrimaryResourceGroup'
	INNER JOIN
		[common].[Connections] AS cn2
	ON 
		cn2.ConnectionDisplayName = 'PrimarySubscription'
	INNER JOIN
		[common].[Connections] AS cn3
	ON 
		cn3.ConnectionDisplayName = 'PrimaryDataLake' AND cn3.SourceLocation = 'curated'
	INNER JOIN
		[common].[Connections] AS cn4
	ON 
		cn4.ConnectionDisplayName = 'PrimaryDataLake' AND cn4.SourceLocation = 'cleansed'
	WHERE
        ds.DatasetId = @DatasetId
	AND 
		nt.NotebookTypeName = 'Unmanaged'
    AND
		ds.Enabled = 1
	AND
		n.Enabled = 1
	AND
		nt.Enabled = 1
	AND
		ccn.Enabled = 1

    IF @ResultRowCount = 0
    BEGIN
        RAISERROR('No results returned for the provided Dataset Id.  Confirm Dataset is enabled, and related Connections and Notebooks Parameters are enabled.',16,1)
        RETURN 0;
    END

    IF @ResultRowCount > 1
    BEGIN
        RAISERROR('Multiple results returned for the provided Dataset Id. Confirm that only a single active dataset is being referenced.',16,1)
        RETURN 0;
    END

	SELECT 
        [ccn].[ConnectionLocation] AS 'ComputeWorkspaceURL',
        [ccn].[ComputeLocation] AS 'ComputeClusterId',
        [ccn].[ComputeSize],
        [ccn].[ComputeVersion],
        [ccn].[CountNodes],
        [ccn].[LinkedServiceName] AS 'ComputeLinkedServiceName',
        [ccn].[ResourceName] AS 'ComputeResourceName',
        [cn].[SourceLocation] AS 'ResourceGroupName',
        [cn2].[SourceLocation] AS 'SubscriptionId',
        
        -- The following may not be required, but are available should data be written with unmanaged notebooks 
        -- to delta tables, without exposing KeyVault secrets to the repository
        [cn3].[ConnectionLocation] AS 'CuratedStorageName',
		[cn3].[SourceLocation] AS 'CuratedContainerName',
        [cn4].[ConnectionLocation] AS 'CleansedStorageName',
		[cn4].[SourceLocation] AS 'CleansedContainerName',
        [cn3].[Username] AS 'CuratedStorageAccessKey',
        [cn4].[Username] AS 'CleansedStorageAccessKey',

        ds.DatasetName,
        ds.SchemaName,
        n.NotebookPath AS 'NotebookFullPath'
    FROM 
		[transform].[Datasets] AS ds
	INNER JOIN
		[transform].[Notebooks] AS n
	ON 
		n.NotebookId = ds.BusinessLogicNotebookFK
	INNER JOIN 
		[transform].[NotebookTypes] AS nt
	ON 
		n.NotebookTypeFK = nt.NotebookTypeId
	INNER JOIN 
		[common].[ComputeConnections] AS ccn
	ON
		ds.ComputeConnectionFK = ccn.ComputeConnectionId
	INNER JOIN
		[common].[Connections] AS cn
	ON 
		cn.ConnectionDisplayName = 'PrimaryResourceGroup'
	INNER JOIN
		[common].[Connections] AS cn2
	ON 
		cn2.ConnectionDisplayName = 'PrimarySubscription'
	INNER JOIN
		[common].[Connections] AS cn3
	ON 
		cn3.ConnectionDisplayName = 'PrimaryDataLake' AND cn3.SourceLocation = 'curated'
	INNER JOIN
		[common].[Connections] AS cn4
	ON 
		cn4.ConnectionDisplayName = 'PrimaryDataLake' AND cn4.SourceLocation = 'cleansed'
	WHERE
        ds.DatasetId = @DatasetId
	AND 
		nt.NotebookTypeName = 'Unmanaged'
    AND
		ds.Enabled = 1
	AND
		n.Enabled = 1
	AND
		nt.Enabled = 1
	AND
		ccn.Enabled = 1

END
GO


