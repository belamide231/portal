using Microsoft.AspNetCore.SignalR;
using MySql.Data.MySqlClient;
using System.Data;

using Middlewares;

namespace MyApp.Namespace.Hubs
{
    public class OnlineHub : Hub
    {
        private readonly MySqlConnection _connection;

        public OnlineHub(MySqlConnection connection)
        {
            _connection = connection;
        }

        public override async Task OnConnectedAsync()
        {
            string connectionId = Context.ConnectionId;
            var httpContext = Context.GetHttpContext();

            // 1. Check if the AuthExtractor middleware provided UserInformation
            if (httpContext != null && httpContext.Items.TryGetValue("UserInformation", out var userObj))
            {
                if (userObj is UserInformation user)
                {
                    Console.WriteLine($"[ONLINE] UserID: {user.UserId} | ConnID: {connectionId}");

                    // Store user data in SignalR Context for the Disconnect event
                    Context.Items["UserData"] = user;

                    string sql = "INSERT INTO tbl_online_users(user_id, signal_id) VALUES(@userId, @signalId);";

                    try
                    {
                        // Open connection before executing
                        if (_connection.State != ConnectionState.Open)
                        {
                            await _connection.OpenAsync();
                        }

                        using var cmd = new MySqlCommand(sql, _connection);
                        cmd.Parameters.AddWithValue("@userId", user.UserId);
                        cmd.Parameters.AddWithValue("@signalId", connectionId);

                        // Use NonQuery for INSERT operations
                        await cmd.ExecuteNonQueryAsync();
                    }
                    catch (Exception error)
                    {
                        Console.WriteLine($"Mysql Connect Error: {error.Message}");
                    }
                    finally
                    {
                        // Always close the connection
                        await _connection.CloseAsync();
                    }
                }
            }
            else 
            {
                Console.WriteLine($"[ONLINE] Anonymous ConnID: {connectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            string connectionId = Context.ConnectionId;

            // Log the Offline event based on stored data
            if (Context.Items.TryGetValue("UserData", out var userObj) && userObj is UserInformation user)
            {
                Console.WriteLine($"[OFFLINE] UserID: {user.UserId} | ConnID: {connectionId}");
            }
            else
            {
                Console.WriteLine($"[OFFLINE] ConnID: {connectionId} (Anonymous)");
            }

            // Cleanup database: Remove the specific Signal ID from the online table
            string sql = "DELETE FROM tbl_online_users WHERE signal_id = @signalId;";

            try
            {
                if (_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                using var cmd = new MySqlCommand(sql, _connection);
                cmd.Parameters.AddWithValue("@signalId", connectionId);

                // Use NonQuery for DELETE operations
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception error)
            {
                Console.WriteLine($"Mysql Disconnect Error: {error.Message}");
            }
            finally
            {
                // Ensure connection is released back to the pool
                await _connection.CloseAsync();
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}