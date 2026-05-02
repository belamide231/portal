using MySql.Data.MySqlClient;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

using Services;

namespace Middlewares
{
    // The data structure used by both the Middleware and the Attribute
    public record UserInformation(
        string UserId, string Role, string FullName, 
        string StudentId, string Course, string Gmail, string ProfilePic
    );

    public class AuthExtractor
    {
        private readonly RequestDelegate _next;
        public AuthExtractor(RequestDelegate next)
        {
            _next = next;
        }
        public async Task InvokeAsync(HttpContext context, MySqlConnection connection, TokenService token)
        {
            string accessToken = context.Request.Cookies["accessToken"];

            if (!string.IsNullOrEmpty(accessToken))
            {
                VerifyAccessToken(context, accessToken);
            }

            string refreshToken = context.Request.Cookies["refreshToken"];

            if (context.Items["UserInformation"] == null)
            {

                VerifyRefreshToken(context, connection, refreshToken, token);
            }

            await _next(context);
        }

        private void VerifyAccessToken(HttpContext context, string accessToken)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes("timoy231_must_be_longer_for_security_123_access_token");

                tokenHandler.ValidateToken(accessToken, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ClockSkew = TimeSpan.Zero 
                }, out SecurityToken validatedToken);

                var jwtToken = (JwtSecurityToken)validatedToken;

                var user = new UserInformation(
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "user_id")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "role")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "full_name")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "student_id")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "course")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "gmail")?.Value,
                    jwtToken.Claims.FirstOrDefault(c => c.Type == "profile_pic")?.Value
                );

                context.Items["UserInformation"] = user;
            }
            catch { }
        }


        private void VerifyRefreshToken(HttpContext context, MySqlConnection connection, string refreshToken, TokenService token)
        {
            try
            {
                if (string.IsNullOrEmpty(refreshToken)) return;

                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes("timoy231_must_be_longer_for_security_123_refresh_token");

                tokenHandler.ValidateToken(refreshToken, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ClockSkew = TimeSpan.Zero 
                }, out SecurityToken validatedToken);

                var jwtToken = (JwtSecurityToken)validatedToken;
                var user_id = jwtToken.Claims.FirstOrDefault(c => c.Type == "user_id")?.Value;

                // Ensure the connection is actually open
                if (connection.State != System.Data.ConnectionState.Open)
                {
                    connection.Open();
                }

                string sql = "CALL get_access_data(@par_user_id);";
                using var cmd = new MySqlCommand(sql, connection);
                cmd.Parameters.AddWithValue("@par_user_id", user_id);
                
                using var reader = cmd.ExecuteReader();
        
                if(reader.Read())
                {
                    // Create the record from DB data
                    var user = new UserInformation(
                        reader["user_id"].ToString(),
                        reader["role"].ToString(),
                        reader["full_name"].ToString(),
                        reader["student_id"].ToString(),
                        reader["course"].ToString(),
                        reader["gmail"].ToString(),
                        reader["profile_picture"].ToString()
                    );

                    string newRefreshToken = token.CreateRefreshToken(user_id);
                    string newAccessToken = token.CreateAccessToken(
                        user_id, 
                        reader["role"].ToString(), 
                        Convert.ToBoolean(reader["is_moderator"]),
                        reader["full_name"].ToString(), 
                        reader["student_id"].ToString(), 
                        reader["course"].ToString(), 
                        reader["gmail"].ToString(), 
                        reader["profile_picture"].ToString());

                        // Define cookie options for security
                        var cookieOptions = new CookieOptions
                        {
                            HttpOnly = true,   // Prevents JavaScript access (Security)
                            Secure = true,     // Only sent over HTTPS
                            SameSite = SameSiteMode.Strict,
                            Expires = DateTime.UtcNow.AddDays(1) // Match your TokenService duration
                        };

                        // 1. Overwrite the Access Token cookie
                        context.Response.Cookies.Append("accessToken", newAccessToken, cookieOptions);

                        // 2. Overwrite the Refresh Token cookie (with a longer expiry)
                        var refreshCookieOptions = new CookieOptions
                        {
                            HttpOnly = true,
                            Secure = true,
                            SameSite = SameSiteMode.Strict,
                            Expires = DateTime.UtcNow.AddMonths(6)
                        };
                        context.Response.Cookies.Append("refreshToken", newRefreshToken, refreshCookieOptions);

                        // 3. Keep the user data in context for the current request
                        context.Items["UserInformation"] = user;

                        Console.WriteLine("Tokens successfully refreshed and cookies updated.");

                    context.Items["UserInformation"] = user;
                }
                else 
                {
                    Console.WriteLine($"Database hit but NO USER found for ID: {user_id}");
                }

            } 
            catch (Exception ex) 
            { 
                // NEVER leave catch empty while debugging!
                Console.WriteLine($"VerifyRefreshToken Error: {ex.Message}");
            }
        }
    }
}