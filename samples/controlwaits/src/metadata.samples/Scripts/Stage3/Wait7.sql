BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 7',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage3',
	@ParameterName = 'WaitTime',
	@ParameterValue = '6';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 4',
    @StageName = 'Stage2',
    @ParameterName = 'WaitTime',
    @ParameterValue = '1',
    @DependantPipelineName = 'Wait 7',
    @DependantStageName = 'Stage3',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '6'

EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 5',
    @StageName = 'Stage2',
    @ParameterName = 'WaitTime',
    @ParameterValue = '3',
    @DependantPipelineName = 'Wait 7',
    @DependantStageName = 'Stage3',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '6'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 7 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH