BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 8',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage3',
	@ParameterName = 'WaitTime',
	@ParameterValue = '10';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 4',
    @StageName = 'Stage2',
    @ParameterName = 'WaitTime',
    @ParameterValue = '1',
    @DependantPipelineName = 'Wait 8',
    @DependantStageName = 'Stage3',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '10'

EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 6',
    @StageName = 'Stage2',
    @ParameterName = 'WaitTime',
    @ParameterValue = '2',
    @DependantPipelineName = 'Wait 8',
    @DependantStageName = 'Stage3',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '10'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 8 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH