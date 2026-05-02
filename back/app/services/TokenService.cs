using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Services
{
    public class TokenService
    {

        private readonly string _accessTokenKey = Environment.GetEnvironmentVariable("ACCESS_TOKEN_KEY")!;
        private readonly DateTime _accessTokenDuration = DateTime.UtcNow.AddDays(1); /*days*/
        private readonly string _refreshTokenKey = Environment.GetEnvironmentVariable("REFRESH_TOKEN_KEY")!;
        private readonly DateTime _refreshTokenDuration = DateTime.UtcNow.AddMonths(6); /*months*/
        private readonly string _registrationTokenKey = Environment.GetEnvironmentVariable("REGISTRATION_TOKEN_KEY")!;
        private readonly DateTime _RegistrationKeyDuration = DateTime.UtcNow.AddDays(7);
        private readonly string _recoveryTokenKey = Environment.GetEnvironmentVariable("RECOVERY_TOKEN_KEY")!;
        private readonly DateTime _RecoveryKeyDuration = DateTime.UtcNow.AddDays(7);

        public string CreateAccessToken(string userId, string role, bool isModerator, string fullName, string studentId, string course, string gmail, string profilePicture)
        {

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_accessTokenKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim("user_id", userId.ToString()),
                new Claim(ClaimTypes.Role, role),
                new Claim("is_moderator", isModerator.ToString()),
                new Claim("full_name", fullName),
                new Claim("student_id", studentId),
                new Claim("course", course),
                new Claim("gmail", gmail),
                new Claim("profile_pic", profilePicture)
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = _accessTokenDuration,
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }

        public string CreateRefreshToken(string userId)
        {

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_refreshTokenKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim("user_id", userId.ToString()),
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = _refreshTokenDuration,
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }
    

        public string CreateRegistrationToken(string gmail, string role, string course)
        {
            // 1. Define the Security Key
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_registrationTokenKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // 2. Add your specific data as Claims
            var claims = new List<Claim>
            {
                new Claim("gmail", gmail),
                new Claim("role", role),
                new Claim("course", course)
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddDays(7),
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }
        public record RegistrationPayload(string Gmail, string Role, string Course);
        public RegistrationPayload? DecodeRegistrationToken(string token)
        {
            if (string.IsNullOrWhiteSpace(token)) return null;

            if (token.StartsWith("Bearer "))
                token = token.Substring(7).Trim();

            var handler = new JwtSecurityTokenHandler();

            try
            {
                var jwtToken = handler.ReadJwtToken(token);

                string gmail = jwtToken.Claims.FirstOrDefault(c => c.Type == "gmail")?.Value ?? "";
                string role = jwtToken.Claims.FirstOrDefault(c => c.Type == "role")?.Value ?? "";
                string course = jwtToken.Claims.FirstOrDefault(c => c.Type == "course")?.Value ?? "";

                return new RegistrationPayload(gmail, role, course);
            }
            catch (Exception)
            {
                return null;
            }
        }



        public string CreateRecoveryToken(string userId, string code)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_registrationTokenKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim("userId", userId),
                new Claim("code", code),
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(1),
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }

        public record RecoveryPayload(string UserId, string Code);
        public RecoveryPayload? DecodeRecoveryToken(string token)
        {
            if (string.IsNullOrWhiteSpace(token)) return null;

            if (token.StartsWith("Bearer "))
                token = token.Substring(7).Trim();

            var handler = new JwtSecurityTokenHandler();

            try
            {
                var jwtToken = handler.ReadJwtToken(token);

                string userId = jwtToken.Claims.FirstOrDefault(c => c.Type == "userId")?.Value ?? "";
                string code = jwtToken.Claims.FirstOrDefault(c => c.Type == "code")?.Value ?? "";

                return new RecoveryPayload(userId, code);
            }
            catch (Exception)
            {
                return null;
            }
        }
    }
}