BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 9',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage4',
	@ParameterName = 'WaitTime',
	@ParameterValue = '1';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 7',
    @StageName = 'Stage3',
    @ParameterName = 'WaitTime',
    @ParameterValue = '6',
    @DependantPipelineName = 'Wait 9',
    @DependantStageName = 'Stage4',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '1'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 9 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH