BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Intentional Error',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage1',
	@ParameterName = 'RaiseErrors',
	@ParameterValue = 'true';
    

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Intentional Error pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH