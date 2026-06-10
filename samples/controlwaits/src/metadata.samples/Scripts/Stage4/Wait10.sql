BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 10',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage4',
	@ParameterName = 'WaitTime',
	@ParameterValue = '5';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 8',
    @StageName = 'Stage3',
    @ParameterName = 'WaitTime',
    @ParameterValue = '10',
    @DependantPipelineName = 'Wait 10',
    @DependantStageName = 'Stage4',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '5'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 10 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH