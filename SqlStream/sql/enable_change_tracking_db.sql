-- Enable Change Tracking on the database
IF NOT EXISTS (SELECT * FROM sys.change_tracking_databases WHERE database_id = DB_ID())
    BEGIN
        ALTER DATABASE [@DatabaseName] SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);
        PRINT 'Change Tracking enabled on the database.';
    END
ELSE
    BEGIN
        PRINT 'Change Tracking already enabled on the database.';
    END
