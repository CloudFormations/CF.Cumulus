BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 4',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage2',
	@ParameterName = 'WaitTime',
	@ParameterValue = '1';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 1',
    @StageName = 'Stage1',
    @ParameterName = 'WaitTime',
    @ParameterValue = '3',
    @DependantPipelineName = 'Wait 4',
    @DependantStageName = 'Stage2',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '1'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 4 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH