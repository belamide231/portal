using System.Data;
using MySql.Data.MySqlClient;
using System.Text.Json.Nodes;
using Org.BouncyCastle.Crypto;
using Mysqlx.Resultset;


namespace Services
{
    
    public class AccountService
    {
        
        private readonly MySqlConnection _connection;

        public AccountService(MySqlConnection connection)
        {
            _connection = connection;
        }

        public async Task<JsonArray> LoginAccount(string username)
        {
            string sql = """
                SELECT
                    JSON_ARRAYAGG(
                        JSON_OBJECT(
                            "password", ft.password,
                            "role", ft.ROLE,
                            "is_moderator", CAST(ft.is_moderator AS CHAR),
                            "user_id", ft.user_id,
                            "full_name", ft.full_name,
                            "student_id", ft.student_id,
                            "course", ft.course,
                            "profile_picture", ft.profile_picture,
                            "is_locked", CAST((CURRENT_TIMESTAMP() < lock_expiration) AS CHAR)
                        )
                    )
                FROM (
                    SELECT 
                        t1.password, t1.ROLE, t1.is_moderator, t1.lock_expiration, t2.*
                    FROM tbl_users_account t1
                    JOIN tbl_users_profile t2
                        ON t1.user_id = t2.user_id
                    WHERE t1.username = @username
                ) ft;
            """;

            try
            {
                if (_connection.State == ConnectionState.Closed)
                {
                    await _connection.OpenAsync();
                }

                using var cmd = new MySqlCommand(sql, _connection);
                cmd.Parameters.AddWithValue("@username", username);

                var result = await cmd.ExecuteScalarAsync();

                if (result == null || result == DBNull.Value)
                {
                    return new JsonArray();
                }

                return JsonNode.Parse(result!.ToString()!)!.AsArray();
            }
            catch (Exception err)
            {
                Console.WriteLine($"Database error {err.Message}");
                return [];
            }
            finally
            {
                if (_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        }


        public async Task LoginFailed(string username)
        {
            string sql = """
                UPDATE tbl_users_account
                SET fail_attempt = (fail_attempt + 1)
                WHERE username = @username
                AND lock_expiration < CURRENT_TIMESTAMP();

                UPDATE tbl_users_account
                SET lock_expiration = (CURRENT_TIMESTAMP() + INTERVAL 10 MINUTE), fail_attempt = 0
                WHERE username = @username
                AND fail_attempt >= 3;
            """;

            try
            {
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                var cmd = new MySqlCommand(sql, _connection);

                cmd.Parameters.AddWithValue("@username", username);

                await cmd.ExecuteNonQueryAsync();
            } 
            catch(Exception err)
            {
                Console.WriteLine($"Database error {err.Message}");
            }
            finally
            {
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();        
                }
            }
        }


        public async Task<JsonArray> SendRegistrationInvitation(string gmails, string userId, string course, string role)
        {
            
            string sql = """
                INSERT INTO tbl_invited_gmails(gmail, sender_id, course, ROLE, sent_stamp, identifier)
                WITH RECURSIVE stamp AS (
                    SELECT CURRENT_TIMESTAMP() current
                ),
                clean_string AS (
                    SELECT REGEXP_REPLACE(@gmails, '[\r\n]+', ' ') AS str
                ),
                gmails AS (
                    SELECT 
                        SUBSTRING_INDEX(str, ' ', 1) AS gmail, 
                        SUBSTRING(str, LOCATE(' ', str) + 1) AS rest
                    FROM clean_string
                    UNION ALL
                    SELECT 
                        SUBSTRING_INDEX(rest, ' ', 1),
                        IF(LOCATE(' ', rest) > 0, SUBSTRING(rest, LOCATE(' ', rest) + 1), '')
                    FROM gmails
                    WHERE rest != "" 
                )
                SELECT mt.gmail, @user_id sender_id, @course course, @role ROLE, stamp.CURRENT sent_stamp, @identifier identifier
                FROM gmails mt
                JOIN stamp 
                WHERE mt.gmail != ""
                AND LOCATE("@", mt.gmail) != 0
                AND mt.gmail NOT IN (
                    SELECT 
                        gmail
                    FROM tbl_users_account
                )
                AND mt.gmail NOT IN (
                    SELECT
                        gmail
                    FROM tbl_invited_gmails
                );

                SELECT 
                    COALESCE(JSON_ARRAYAGG(gmail), '[]') gmails
                FROM (
                    SELECT 
                        gmail
                    FROM tbl_invited_gmails
                    WHERE identifier = @identifier
                ) dt;
            """;

            try
            {
                
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                var cmd = new MySqlCommand(sql, _connection);

                string identifier = Guid.NewGuid().ToString();

                cmd.Parameters.AddWithValue("@gmails", gmails);
                cmd.Parameters.AddWithValue("@user_id", userId);
                cmd.Parameters.AddWithValue("@course", course);
                cmd.Parameters.AddWithValue("@role", role);
                cmd.Parameters.AddWithValue("@identifier", identifier);

                var result = await cmd.ExecuteScalarAsync();

                if (result == null || result == DBNull.Value)
                {
                    return [];
                }

                return JsonNode.Parse(result!.ToString()!)!.AsArray();

            } 
            catch(Exception err)
            {

                Console.WriteLine($"Database error {err.Message}");
                return [];
            }
            finally
            {
                
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        }

        public async Task<dynamic> CreateAccount(string username, string password, string gmail, string role, string course)
        {
            
            try
            {
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                string sql = """
                    SET @message = (
                        SELECT
                            CASE 
                                WHEN f.is_username_used = 1 THEN "Try another username"
                                WHEN f.is_gmail_used = 1 THEN "Gmail is already used"
                                WHEN f.is_gmail_invited = 0 THEN "Gmail is not invited"
                                ELSE NULL
                            END message
                        FROM (
                            SELECT EXISTS (
                                SELECT 
                                    1
                                FROM tbl_users_account
                                WHERE username = @username
                            ) is_username_used, EXISTS (
                                SELECT
                                    1
                                FROM tbl_users_account
                                WHERE gmail = @gmail
                            ) is_gmail_used, EXISTS (
                                SELECT 
                                    1
                                FROM tbl_invited_gmails
                                WHERE gmail = @gmail
                            ) is_gmail_invited
                        ) f
                    );

                    INSERT INTO tbl_users_account(username, password, ROLE, gmail)
                    SELECT 
                        dummy.*
                    FROM (
                        SELECT @message message
                    ) dt
                    LEFT JOIN (SELECT @username, @password, @role, @gmail) dummy
                        ON 1 = 1
                    WHERE dt.message IS NULL;

                    INSERT INTO tbl_users_profile(user_id, full_name, course)
                    SELECT 
                        dummy.*
                    FROM (
                        SELECT @message message
                    ) dt
                    LEFT JOIN (
                        SELECT (
                            SELECT user_id FROM tbl_users_account WHERE username = @username
                        ) user_id, @gmail, @course) dummy
                        ON 1 = 1
                    WHERE dt.message IS NULL;

                    DELETE 
                    FROM tbl_invited_gmails 
                    WHERE gmail = @gmail
                    AND @message IS NULL;

                    SELECT @message;
                """;

                var cmd = new MySqlCommand(sql, _connection);

                cmd.Parameters.AddWithValue("@username", username);
                cmd.Parameters.AddWithValue("@password", password);
                cmd.Parameters.AddWithValue("@gmail", gmail);
                cmd.Parameters.AddWithValue("@role", role);
                cmd.Parameters.AddWithValue("@course", course);

                var result = await cmd.ExecuteScalarAsync();

                return result == DBNull.Value ? null! : result?.ToString()!;
            }
            catch(Exception err)
            {
                Console.WriteLine($"Database error {err.Message}");
                return "Database Error";
            }
            finally
            {
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        } 

        public async Task<dynamic> RecoverAccount(string input)
        {
            string sql = """
                DELETE FROM tbl_users_update WHERE update_stamp < CURRENT_TIMESTAMP() - INTERVAL 1 HOUR;

                SET @user_id = COALESCE((
                    SELECT
                        user_id
                    FROM tbl_users_account
                    WHERE (username = @input
                    OR gmail = @input)
                    LIMIT 1
                ), "0");

                SET @gmail = (
                    SELECT 
                        gmail
                    FROM tbl_users_account
                    WHERE user_id = @user_id
                );
                
                SET @uuid = UUID();

                INSERT INTO tbl_users_update(user_id, update_type, code)
                SELECT @user_id, "change-password", @uuid
                WHERE @user_id != "0";

                SELECT 
                    JSON_OBJECT(
                        "message", ft.message,
                        "uuid", ft.uuid,
                        "user_id", ft.user_id,
                        "gmail", ft.gmail,
                        "success", ft.success
                    ) result
                FROM (
                    SELECT 
                        CASE 
                            WHEN @user_id = "0" THEN "Username or Gmail did not exists"
                            ELSE "We sent you an email for your account recovery"
                        END message, 
                        @uuid uuid, 
                        @user_id user_id, 
                        @gmail gmail, 
                        (@user_id != "0") success
                ) ft;
            """;

            try
            {
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                var cmd = new MySqlCommand(sql, _connection);

                cmd.Parameters.AddWithValue("@input", input);

                var result = await cmd.ExecuteScalarAsync();

                return JsonNode.Parse(result!.ToString()!)!.AsObject();
            } 
            catch(Exception err)
            {
                Console.WriteLine($"Database error {err.Message}");
                return null!;
            }
            finally
            {
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        }

        public async Task ResetFailAttempt(string userId)
        {

            string sql = """
                UPDATE tbl_users_account 
                SET fail_attempt = 0 
                WHERE username = @username;
            """;

            try
            {
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                var cmd = new MySqlCommand(sql, _connection);

                cmd.Parameters.AddWithValue("@username", userId);

                await cmd.ExecuteNonQueryAsync();
            }
            catch(Exception ex)
            {
                Console.WriteLine($"Database error {ex.Message}");
            }
            finally
            {
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        }
    
        public async Task<dynamic> ResetPassword(string userId, string code, string newPassword)
        {

            string sql = """
                DELETE FROM tbl_users_update WHERE update_stamp < CURRENT_TIMESTAMP() - INTERVAL 1 HOUR;

                SET @requesting = EXISTS(SELECT 1 FROM tbl_users_update WHERE user_id = @user_id AND code = @code AND update_type = "change-password");

                UPDATE tbl_users_account SET password = @new_password, fail_attempt = 0, lock_expiration = CURRENT_TIMESTAMP() WHERE user_id = @user_id AND @requesting IS TRUE;

                DELETE FROM tbl_users_update WHERE code = @code AND user_id = @user_id AND update_type = "change-password";

                SELECT
                    JSON_OBJECT(
                        "message", CASE 
                            WHEN @requesting IS TRUE THEN "Password is reset"
                            ELSE "Invalid resetting password, reset token can only be use once."
                        END,
                        "is_reset", (@requesting IS TRUE)
                    ) result;
            """;
            
            try
            {
                if(_connection.State != ConnectionState.Open)
                {
                    await _connection.OpenAsync();
                }

                var cmd = new MySqlCommand(sql, _connection);

                cmd.Parameters.AddWithValue("@user_id", userId);
                cmd.Parameters.AddWithValue("@code", code);
                cmd.Parameters.AddWithValue("@new_password", newPassword);

                var result = await cmd.ExecuteScalarAsync();

                return JsonNode.Parse(result!.ToString()!)!.AsObject();
            }
            catch(Exception err)
            {
                Console.WriteLine($"Database error {err.Message}");
                return null!;
            }
            finally
            {
                if(_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
            }
        }
    }
}