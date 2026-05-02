using Microsoft.AspNetCore.Mvc;
using BC = BCrypt.Net.BCrypt;

using Services;
using Microsoft.AspNetCore.Identity;
using System.Net.Security;
using Microsoft.AspNetCore.Components.Forms;
using MySqlX.XDevAPI.Common;


namespace Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountController : ControllerBase
    {
        
        private readonly AccountService _account;
        private readonly TokenService _token;
        private readonly IEmailService _mail;
        public AccountController(AccountService account, TokenService token, IEmailService mail)
        {
            _account = account;
            _token = token;
            _mail = mail;
        }

        public record LoginAccountDTO(string Username, string Password);
        [HttpPost("login-account")]
        public async Task<IActionResult> LoginAccountAPI([FromBody] LoginAccountDTO body)
        {
            var result = await _account.LoginAccount(body.Username);

            Console.WriteLine(result.ToString());

            if(result == null || result.Count == 0 || result.ToString() == "[]")
            {
                return NotFound(new
                {
                    message = "Invalid username"
                });
            }

            var user = result.FirstOrDefault()!;

            if(user["is_locked"]!.ToString() == "1")
            {
                return Unauthorized(new
                {
                   message = "Account is locked" 
                });
            }

            if(!BC.Verify(body.Password, user["password"]!.ToString()))
            {

                await _account.LoginFailed(body.Username);

                return Unauthorized(new
                {
                    message = "Incorrect password"
                });
            }

            await _account.ResetFailAttempt(body.Username);

            string refreshToken = _token.CreateRefreshToken(user["user_id"]!.ToString());

            Response.Cookies.Append("refreshToken", refreshToken, new CookieOptions {
                HttpOnly = true,
                Secure = true, 
                SameSite = SameSiteMode.None, 
                Expires = DateTimeOffset.UtcNow.AddYears(99)
            });

            return Ok(new
            {
                role = user["role"]!.ToString()
            });
        }
    
        public record SendRegistrationInvitationDTO(string Gmails, string UserId, string Course, string Role);
        [HttpPost("send-registration-invitation")]
        public async Task<IActionResult> SendRegistrationInvitationAPI([FromBody] SendRegistrationInvitationDTO body)
        {

            var result = await _account.SendRegistrationInvitation(body.Gmails, body.UserId, body.Course, body.Role);

            if(result.ToString() == "[]")
            {
                return Ok(new
                {
                    message = "No gmail invited, they might already received an invitation already or gmail already used"
                });
            }

            var tasks = result.Select(async gmail =>
            {
                string stringGmail = gmail!.ToString();

                if (!stringGmail.Contains("@")) {
                    return;
                }

                string registrationKey = _token.CreateRegistrationToken(stringGmail, body.Role, body.Course);

                await _mail.SendInviteEmailAsync(stringGmail, registrationKey);
            });

            await Task.WhenAll(tasks);

            return Ok(new
            {
                message = "Successfully sent an registration invitation"
            });
        }
    
        public record RegisterDTO(string RegistrationToken, string Username, string Password);
        [HttpPost("register-account")]
        public async Task<IActionResult> RegisterAPI([FromBody] RegisterDTO body) 
        {

            var payload = _token.DecodeRegistrationToken(body.RegistrationToken);

            if(payload == null)
            {
                return Unauthorized(new
                {
                    message = "Invalid registration token"
                });
            }

            string hashedPassword = BC.HashPassword(body.Password);

            var result = await _account.CreateAccount(body.Username, hashedPassword, payload.Gmail, payload.Role, payload.Course);

            if(result != null)
            {
                return Conflict(new
                {
                    message = result
                });
            }

            return Ok(new
            {
                message = "Account successfully created"
            });
        }

        public record RecoverAccountDTO(string Input);
        [HttpPost("recover-account")]
        public async Task<IActionResult> RecoverAccountAPI([FromBody] RecoverAccountDTO body)
        {
            var result = await _account.RecoverAccount(body.Input);

            if(result == null)
            {
                return StatusCode(500);
            }

            if(result["success"].ToString() == "0")
            {
                return Conflict(new
                {
                    message = result["message"].ToString()
                });
            }

            string recoveryToken = _token.CreateRecoveryToken(result["user_id"].ToString(), result["uuid"].ToString());

            await _mail.SendRecoveryEmailAsync(result["gmail"].ToString(), recoveryToken);

            return Ok(new {
                message = result["message"]
            });
        }

        public record ResetPasswordDTO(string ResetToken, string NewPassword);
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPasswordAPI([FromBody] ResetPasswordDTO body)
        {
            var payload = _token.DecodeRecoveryToken(body.ResetToken);

            if(payload == null)
            {
                return StatusCode(403, new
                {
                    message = "Request Forbidden"
                });
            }

            string hashedPassword = BC.HashPassword(body.NewPassword);

            var result = await _account.ResetPassword(payload.UserId, payload.Code, hashedPassword);

            if(result == null)
            {
                return StatusCode(500);
            }

            if(result["is_reset"].ToString() == "0")
            {
                return StatusCode(403, new
                {
                    message = result["message"].ToString()
                });
            }

            return Ok(new
            {
                message = result["message"].ToString()                
            });
        }

    }
}
