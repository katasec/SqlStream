-- Enable Change Tracking on the table
IF NOT EXISTS (SELECT * FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('@TableName'))
    BEGIN
        ALTER TABLE [@TableName] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
        PRINT 'Change Tracking enabled on the table @TableName.';
    END
ELSE
    BEGIN
        PRINT 'Change Tracking already enabled on the table @TableName.';
    END
