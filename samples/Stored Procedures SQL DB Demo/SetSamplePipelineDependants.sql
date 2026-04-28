CREATE PROCEDURE [samples].[SetSamplePipelineDependants]
AS
BEGIN
	-- EXEC [samples].[AddPipelineDependant]
	-- 	@PipelineName = 'Intentional Error',
	-- 	@DependantPipelineName = 'Wait 5';

	-- EXEC [samples].[AddPipelineDependant]
	-- 	@PipelineName = 'Intentional Error',
	-- 	@DependantPipelineName = 'Wait 6';

	-- EXEC [samples].[AddPipelineDependant]
	-- 	@PipelineName = 'Wait 6',
	-- 	@DependantPipelineName = 'Wait 9';

	-- EXEC [samples].[AddPipelineDependant]
	-- 	@PipelineName = 'Wait 9',
	-- 	@DependantPipelineName = 'Wait 10';

	EXEC [samples].[AddPipelineDependant]
		@PipelineName = 'Wait 1',
		@DependantPipelineName = 'Wait 2';
END;