IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'ProcessChangesJob')
    BEGIN
        EXEC msdb.dbo.sp_add_job @job_name = N'ProcessChangesJob';
        EXEC msdb.dbo.sp_add_jobstep @job_name = N'ProcessChangesJob', @step_name = N'ProcessChangesStep',
             @subsystem = N'TSQL', @command = N'
            DECLARE @TableName NVARCHAR(128), @PrimaryKeyColumn NVARCHAR(128);
            DECLARE @DialogHandle UNIQUEIDENTIFIER, @MessageBody NVARCHAR(MAX), @sync_version BIGINT;

            SET @sync_version = CHANGE_TRACKING_CURRENT_VERSION();

            DECLARE @LastSyncVersion BIGINT;
            SET @LastSyncVersion = 0;

            DECLARE tables_cursor CURSOR FOR
            SELECT s.name + ''.'' + t.name AS TableName, c.name AS PrimaryKeyColumn
            FROM sys.change_tracking_tables ct
            JOIN sys.tables t ON ct.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.columns c ON t.object_id = c.object_id
            WHERE c.is_identity = 1 OR c.is_primary_key = 1;

            OPEN tables_cursor;
            FETCH NEXT FROM tables_cursor INTO @TableName, @PrimaryKeyColumn;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DialogHandle = NEWID();

                BEGIN DIALOG CONVERSATION @DialogHandle
                    FROM SERVICE [ChangeService]
                    TO SERVICE ''ChangeService''
                    ON CONTRACT [ChangeContract]
                    WITH ENCRYPTION = OFF;

                SET @MessageBody = (
                    SELECT
                        CT.SYS_CHANGE_VERSION,
                        CT.SYS_CHANGE_OPERATION,
                        T.*
                    FROM
                        CHANGETABLE(CHANGES (' + @TableName + '), @LastSyncVersion) AS CT
                    JOIN ' + @TableName + ' AS T
                    ON T.' + @PrimaryKeyColumn + ' = CT.' + @PrimaryKeyColumn + '
                    FOR XML PATH(''Change''), ROOT(''Changes''), TYPE
                ).value(''.'', ''NVARCHAR(MAX)'');

                IF @MessageBody IS NOT NULL
                BEGIN
                    SEND ON CONVERSATION @DialogHandle
                        MESSAGE TYPE [ChangeMessage]
                        (@MessageBody);
                END

                END CONVERSATION @DialogHandle;

                FETCH NEXT FROM tables_cursor INTO @TableName, @PrimaryKeyColumn;
            END;

            CLOSE tables_cursor;
            DEALLOCATE tables_cursor;', 
        @database_name = N'AmeerDB';

        EXEC msdb.dbo.sp_add_jobschedule @job_name = N'ProcessChangesJob', @name = N'ProcessChangesSchedule',
             @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 5, @active_start_time = 080000;

        EXEC msdb.dbo.sp_add_jobserver @job_name = N'ProcessChangesJob', @server_name = @@SERVERNAME;

        PRINT 'SQL Agent Job ProcessChangesJob created.';
    END
ELSE
    BEGIN
        PRINT 'SQL Agent Job ProcessChangesJob already exists.';
    END
