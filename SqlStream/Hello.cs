namespace SqlStream;

using System;
using System.Data.SqlClient;
using System.IO;
using System.Text;

public class Hello
{
    public static void ExecuteSqlFromFile(string connectionString, string fileName, params string[] parameters)
    {
        fileName = Path.Join("sql", fileName);
        string sql = File.ReadAllText(fileName);

        if (parameters.Length > 0)
        {
            for (int i = 0; i < parameters.Length; i++)
            {
                sql = sql.Replace($"@Parameter{i + 1}", parameters[i]);
            }
        }

        using SqlConnection connection = new SqlConnection(connectionString);
        connection.Open();
        connection.InfoMessage += (sender, e) =>
        {
            Console.WriteLine(e.Message);
        };

        // Set the FireInfoMessageEventOnUserErrors property to true
        connection.FireInfoMessageEventOnUserErrors = true;

        using var command = new SqlCommand(sql, connection);
        command.CommandType = System.Data.CommandType.Text;
        command.ExecuteNonQuery();
    }

    public static void QueryChanges(string connectionString, string tableName, string primaryKeyColumn)
    {
        using SqlConnection connection = new SqlConnection(connectionString);
        connection.Open();
        while (true)
        {
            string queryChangesSql = @"
                    DECLARE @LastSyncVersion BIGINT;
                    SET @LastSyncVersion = 0;

                    DECLARE @MessageBody NVARCHAR(MAX);

                    SELECT @MessageBody = (
                        SELECT
                            CT.SYS_CHANGE_VERSION,
                            CT.SYS_CHANGE_OPERATION,
                            T.*
                        FROM
                            CHANGETABLE(CHANGES " + tableName + @", @LastSyncVersion) AS CT
                        JOIN " + tableName + @" AS T
                        ON T." + primaryKeyColumn + @" = CT." + primaryKeyColumn + @"
                        FOR XML PATH('Change'), ROOT('Changes'), TYPE
                    ).value('.', 'NVARCHAR(MAX)');

                    SELECT @MessageBody AS Changes";

            using (SqlCommand command = new SqlCommand(queryChangesSql, connection))
            {
                var changes = command.ExecuteScalar();
                if (changes != null)
                {
                    Console.WriteLine("Changes: " + changes);
                }
            }

            // Wait for a short period before checking again
            Thread.Sleep(5000); // Check every 5 seconds
        }
    }
}

