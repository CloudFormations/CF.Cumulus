BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 1',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage1',
	@ParameterName = 'WaitTime',
	@ParameterValue = '3';
    

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 1 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH