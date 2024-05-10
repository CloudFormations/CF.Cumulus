
    EXEC [ingest].[AddAuditAttribute] 
        @AttributeName = 'PipelineRunId',
        @LayerName = 'Raw',
        @AttributeDataType = 'STRING',
        @AttributeDataFormat = '',
        @AttributeDescription = NULL,
        @Enabled = 1;

    EXEC [ingest].[AddAuditAttribute] 
        @AttributeName = 'PipelineRunId',
        @LayerName = 'Cleansed',
        @AttributeDataType = 'STRING',
        @AttributeDataFormat = '',
        @AttributeDescription = NULL,
        @Enabled = 1;

    EXEC [ingest].[AddAuditAttribute] 
        @AttributeName = 'PipelineExecutionDateTime',
        @LayerName = 'Raw',
        @AttributeDataType = 'TIMESTAMP',
        @AttributeDataFormat = 'yyyy-MM-dd HH:mm:ss',
        @AttributeDescription = NULL,
        @Enabled = 1;

    EXEC [ingest].[AddAuditAttribute] 
        @AttributeName = 'PipelineExecutionDateTime',
        @LayerName = 'Cleansed',
        @AttributeDataType = 'TIMESTAMP',
        @AttributeDataFormat = 'yyyy-MM-dd HH:mm:ss',
        @AttributeDescription = NULL,
        @Enabled = 1;


