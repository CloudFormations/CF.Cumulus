BEGIN TRY

--Metadata as Code for Control Pipelines

--Pipelines
EXEC [samples].[AddWaitPipeline] 
    @PipelineName = 'Wait 5',
    @OrchestratorName = '$(ADFName)',
    @StageName = 'Stage2',
	@ParameterName = 'WaitTime',
	@ParameterValue = '3';
    
-- Pipeline Dependencies
EXEC [samples].[AddPipelineDependency]
    @PipelineName = 'Wait 2',
    @StageName = 'Stage1',
    @ParameterName = 'WaitTime',
    @ParameterValue = '6',
    @DependantPipelineName = 'Wait 5',
    @DependantStageName = 'Stage2',
    @DependantParameterName = 'WaitTime',
    @DependantParameterValue = '3'

END TRY
BEGIN CATCH
    PRINT '';
    PRINT '######################';
    PRINT CHAR(27) + '[31m' +'Error adding metadata for Wait 5 pipeline' + CHAR(27) + '[0m';
    PRINT '######################';
    PRINT '';
    THROW;
END CATCH