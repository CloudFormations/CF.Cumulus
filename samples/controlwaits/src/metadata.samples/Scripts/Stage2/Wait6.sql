BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 6',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage2',
	@ParameterName = 'WaitTime',
	@ParameterValue = '2';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 3',
    @StageName = 'Stage1',
    @ParameterName = 'WaitTime',
    @ParameterValue = '5',
    @DependantPipelineName = 'Wait 6',
    @DependantStageName = 'Stage2',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '2'

EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Intentional Error',
    @StageName = 'Stage1',
    @ParameterName = 'RaiseErrors',
    @ParameterValue = 'true',
    @DependantPipelineName = 'Wait 6',
    @DependantStageName = 'Stage2',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '2'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 6 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH