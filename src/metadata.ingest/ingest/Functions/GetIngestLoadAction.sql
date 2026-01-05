CREATE FUNCTION [ingest].[GetIngestLoadAction]
    (
        @DatasetId INT,
        @IngestStage VARCHAR(10)
    )
    RETURNS VARCHAR(1)
    AS 
    BEGIN
    DECLARE @LoadStatus INT
    DECLARE @LoadType VARCHAR(1)
    DECLARE @LoadAction VARCHAR(1)
    DECLARE @RawLastLoadDate DATETIME2
    DECLARE @CleansedLastLoadDate DATETIME2
    DECLARE @ExtensionType NVARCHAR(20)

    -- Defensive check for valid @IngestStage parameter: RAISERROR not allowed in UDF
    -- IF @IngestStage NOT IN ('Raw','Cleansed')
    -- BEGIN
    --     RAISERROR('Ingest Stage specified not supported. Please specify either Raw or Cleansed action', 16, 1)
    -- END

    SELECT 
        @LoadStatus = LoadStatus,
        @LoadType = LoadType,
        @ExtensionType = ExtensionType
    FROM 
        ingest.[Datasets]
    WHERE
        DatasetId = @DatasetId

    -- U = Unpack, used for Excel data sources. Therefore, always perform a full load.
    IF @LoadType = 'U'
    BEGIN
        SET @LoadType = 'F'
    END

    -- PRINT @LoadStatus

    -- No load of any kind for this dataset
    -- next raw load: full
    -- next incremental load (if bronze type <> Delta): error
    -- next incremental load (if bronze type = Delta): full
    IF @LoadStatus = 0 
    BEGIN
        IF @IngestStage = 'Raw'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Cleansed' AND @ExtensionType <> 'Delta'
        BEGIN
            SET @LoadAction = 'X'
            --RAISERROR('No Raw Full load completed. Please confirm this has not failed before proceeding with this cleansed load operation.',16,1)
        END
        IF @IngestStage = 'Cleansed' AND @ExtensionType = 'Delta'
        BEGIN
            SET @LoadAction = 'F'
        END
    END

    -- raw no loads
    -- next raw load: full
    -- next incremental load (if bronze type <> Delta): error
    -- next incremental load (if bronze type = Delta): full
    IF ( (2 & @LoadStatus) <> 2 )
    BEGIN
        IF @IngestStage = 'Raw'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Cleansed' AND @ExtensionType <> 'Delta'
        BEGIN
            SET @LoadAction = 'X'
            -- RAISERROR('No Raw Full load completed. Please confirm this has not failed before proceeding with this cleansed load operation.',16,1)
        END
        IF @IngestStage = 'Cleansed' AND @ExtensionType = 'Delta'
        BEGIN
            SET @LoadAction = 'F'
        END
    END

    -- raw full, cleansed null, 
    -- next raw load: incremental (if LoadType = 'I')
    -- next cleansed load: full
    -- set raw comparison date = rawlastloaddate, cleansed comparison date = cleansedlastfullloaddate (nullable)
    IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) <> 4 ) AND ( (8 & @LoadStatus) <> 8)
    BEGIN
        IF @IngestStage = 'Raw' AND @LoadType = 'F'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Raw' AND @LoadType = 'I'
        BEGIN
            SET @LoadAction = 'I'
        END
        IF @IngestStage = 'Cleansed'
        BEGIN
            SET @LoadAction = 'F'
        END
    END

    -- raw full, cleased full
    -- next raw load: incremental (if LoadType = 'I')
    -- next cleansed load: full
    -- set raw comparison date = rawlastloaddate, cleansed comparison date = cleansedlastfullloaddate (nullable)
    IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) <> 4 ) AND ( (8 & @LoadStatus) = 8)
    BEGIN
        IF @IngestStage = 'Raw' AND @LoadType = 'F'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Raw' AND @LoadType = 'I'
        BEGIN
            SET @LoadAction = 'I'
        END
        IF @IngestStage = 'Cleansed'
        BEGIN
            SET @LoadAction = 'F'
        END
    END

    -- raw full, raw incremental and cleansed null
    -- next raw load: incremental (if LoadType = 'I')
    -- next cleansed load: full
    IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) = 4 ) AND ( (8 & @LoadStatus) <> 8)
    BEGIN
        IF @IngestStage = 'Raw' AND @LoadType = 'F'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Raw' AND @LoadType = 'I'
        BEGIN
            SET @LoadAction = 'I'
        END
        IF @IngestStage = 'Cleansed'
        BEGIN
            SET @LoadAction = 'F'
        END
    END



    -- raw full, raw incremental and cleansed full
    -- next raw load: incremental  (if LoadType = 'I')
    -- next cleansed load: incremental  (if LoadType = 'I')
    IF ( (2 & @LoadStatus) = 2 ) AND ( (4 & @LoadStatus) = 4 ) AND ( (8 & @LoadStatus) = 8)
    BEGIN
        IF @IngestStage = 'Raw' AND @LoadType = 'F'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Raw' AND @LoadType = 'I'
        BEGIN
            SET @LoadAction = 'I'
        END
        IF @IngestStage = 'Cleansed' AND @LoadType = 'F'
        BEGIN
            SET @LoadAction = 'F'
        END
        IF @IngestStage = 'Cleansed' AND @LoadType = 'I'
        BEGIN
            SET @LoadAction = 'I'
        END

    END

    RETURN @LoadAction;
    END