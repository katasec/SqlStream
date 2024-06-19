

var connectionString = Environment.GetEnvironmentVariable("yodanprod");
// Console.WriteLine(connStr); 
// Environment.Exit(0);

string tableName = "People"; // Change this to your table name
string primaryKeyColumn = "id"; // Change this to your primary key column

SqlStream.Hello.ExecuteSqlFromFile(connectionString, "setup_service_broker.sql", connectionString);
//SqlStream.Hello.ExecuteSqlFromFile(connectionString, "enable_change_tracking_db.sql", connectionString);

// SqlStream.Hello.ExecuteSqlFromFile(connectionString, "enable_change_tracking_table.sql", connectionString, tableName);
// SqlStream.Hello.ExecuteSqlFromFile(connectionString, "create_or_update_job.sql", connectionString);
//
// SqlStream.Hello.QueryChanges(connectionString, tableName, primaryKeyColumn);