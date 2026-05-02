using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
namespace Services
{
public interface IEmailService
    {
        Task SendInviteEmailAsync(string recipientEmail, string token);
        Task SendRecoveryEmailAsync(string recipientEmail, string token);
    }

    public class EmailService : IEmailService
    {
        private readonly string _smtpServer;
        private readonly int _smtpPort;
        
        private readonly string _gmail; 
        private readonly string _code; 

        public EmailService()
        {
            _smtpServer = Environment.GetEnvironmentVariable("SERVER")!;
            _smtpPort = Convert.ToInt32(Environment.GetEnvironmentVariable("PORT"));
            _gmail = Environment.GetEnvironmentVariable("GMAIL")!; 
            _code = Environment.GetEnvironmentVariable("PASSWORD")!;
        }

        public async Task SendInviteEmailAsync(string recipientEmail, string token)
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("School Admin", _gmail));
            message.To.Add(new MailboxAddress("", recipientEmail));
            message.Subject = "Invitation to Join - Cebu Eastern Portal";

            string registerLink = $"http://localhost:4200/login/sign-up?registrationToken={token}";
            string logoUrl = "https://media.licdn.com/dms/image/v2/C560BAQHvM32-NWHqIw/company-logo_200_200/company-logo_200_200/0/1630638187217/cebu_eastern_college_logo?e=2147483647&v=beta&t=ePZD5KtCgIjyXJY1Y4Px7ASx52Ipvw2V7t66J0WmqJU";

            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                <div style='background-color: #f4f6f9; padding: 40px 20px; font-family: ""Segoe UI"", Tahoma, Geneva, Verdana, sans-serif;'>
                    <div style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 6px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);'>
                        
                        <div style='background-color: #0C0C84; padding: 30px; text-align: center;'>
                            <img src='{logoUrl}' alt='Cebu Eastern College Logo' style='max-width: 120px; height: auto; margin-bottom: 15px; padding: 5px; border-radius: 100%; background-color: #ffffff;' />
                            <h1 style='color: #ffffff; margin: 0; font-size: 22px; letter-spacing: 1px; text-transform: uppercase;'>Cebu Eastern College</h1>
                        </div>
                        
                        <div style='padding: 40px 30px; text-align: left;'>
                            <h2 style='color: #2c3e50; margin-top: 0; font-size: 20px; border-bottom: 2px solid #f4f6f9; padding-bottom: 12px;'>Official Portal Invitation</h2>
                            
                            <p style='color: #444444; font-size: 15px; line-height: 1.6; margin-top: 25px;'>
                                Greetings,
                            </p>
                            <p style='color: #444444; font-size: 15px; line-height: 1.6;'>
                                You are hereby invited to access the official <strong>Cebu Eastern College Portal</strong>. This secure platform is designated for your academic and administrative needs.
                            </p>
                            <p style='color: #444444; font-size: 15px; line-height: 1.6; margin-bottom: 30px;'>
                                To activate your account and establish your credentials, please proceed by clicking the secure link provided below.
                            </p>
                            
                            <div style='text-align: center; margin: 40px 0 20px 0;'>
                                <a href='{registerLink}' style='background-color: #0C0C84; color: #ffffff; padding: 14px 32px; text-decoration: none; border-radius: 4px; font-weight: 600; font-size: 15px; display: inline-block;'>Proceed to Registration</a>
                            </div>

                            <p style='color: #d9534f; font-size: 14px; font-weight: 600; text-align: center; margin-bottom: 30px;'>
                                For your security, this invitation link will expire in 1 hour.
                            </p>
                            
                            <p style='color: #444444; font-size: 14px; line-height: 1.6; margin-bottom: 30px;'>
                                <strong>If you were not expecting this invitation, simply ignore this email.</strong> No account will be created.
                            </p>
                            
                            <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #eeeeee;'>
                                <p style='color: #666666; font-size: 13px; margin-bottom: 5px;'>If the button above is unresponsive, please copy and paste the following URL into your web browser:</p>
                                <a href='{registerLink}' style='color: #0C0C84; font-size: 13px; word-break: break-all;'>{registerLink}</a>
                            </div>
                        </div>
                        
                        <div style='background-color: #f8fafc; padding: 20px 30px; text-align: left; border-top: 1px solid #e2e8f0;'>
                            <p style='color: #888888; font-size: 11px; line-height: 1.5; margin: 0;'>
                                <strong>Confidentiality Notice:</strong> This email and any corresponding links are confidential and intended solely for the use of the assigned recipient. If you have received this communication in error, please disregard it.<br><br>
                                © {DateTime.Now.Year} Cebu Eastern College. All rights reserved.
                            </p>
                        </div>
                        
                    </div>
                </div>" 
            };

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            try
            {
                await client.ConnectAsync(_smtpServer, _smtpPort, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(_gmail, _code);
                await client.SendAsync(message);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SMTP ERROR]: Could not send to {recipientEmail}. Details: {ex.Message}");
                throw; 
            }
            finally
            {
                await client.DisconnectAsync(true);
            }
        }

        public async Task SendRecoveryEmailAsync(string recipientEmail, string token)
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("School Admin", _gmail));
            message.To.Add(new MailboxAddress("", recipientEmail));
            
            message.Subject = "Password Reset Request - Cebu Eastern Portal";

            string resetPasswordLink = $"http://localhost:4200/login/reset-password?resetToken={token}";
            string logoUrl = "https://media.licdn.com/dms/image/v2/C560BAQHvM32-NWHqIw/company-logo_200_200/company-logo_200_200/0/1630638187217/cebu_eastern_college_logo?e=2147483647&v=beta&t=ePZD5KtCgIjyXJY1Y4Px7ASx52Ipvw2V7t66J0WmqJU";

            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                <div style='background-color: #f4f6f9; padding: 40px 20px; font-family: ""Segoe UI"", Tahoma, Geneva, Verdana, sans-serif;'>
                    <div style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 6px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);'>
                        
                        <div style='background-color: #0C0C84; padding: 30px; text-align: center;'>
                            <img src='{logoUrl}' alt='Cebu Eastern College Logo' style='max-width: 120px; height: auto; margin-bottom: 15px; padding: 5px; border-radius: 100%; background-color: #ffffff;' />
                            <h1 style='color: #ffffff; margin: 0; font-size: 22px; letter-spacing: 1px; text-transform: uppercase;'>Cebu Eastern College</h1>
                        </div>
                        
                        <div style='padding: 40px 30px; text-align: left;'>
                            <h2 style='color: #2c3e50; margin-top: 0; font-size: 20px; border-bottom: 2px solid #f4f6f9; padding-bottom: 12px;'>Account Password Reset</h2>
                            
                            <p style='color: #444444; font-size: 15px; line-height: 1.6; margin-top: 25px;'>
                                Greetings,
                            </p>
                            <p style='color: #444444; font-size: 15px; line-height: 1.6;'>
                                We received a request to reset the password associated with your <strong>Cebu Eastern College Portal</strong> account.
                            </p>
                            <p style='color: #444444; font-size: 15px; line-height: 1.6; margin-bottom: 30px;'>
                                To choose a new password and recover access to your account, please click the secure link provided below. 
                            </p>
                            
                            <div style='text-align: center; margin: 40px 0 20px 0;'>
                                <a href='{resetPasswordLink}' style='background-color: #0C0C84; color: #ffffff; padding: 14px 32px; text-decoration: none; border-radius: 4px; font-weight: 600; font-size: 15px; display: inline-block;'>Reset Password</a>
                            </div>

                            <p style='color: #d9534f; font-size: 14px; font-weight: 600; text-align: center; margin-bottom: 30px;'>
                                For your security, this link will expire in 1 hour.
                            </p>
                            
                            <p style='color: #444444; font-size: 14px; line-height: 1.6; margin-bottom: 30px;'>
                                <strong>If this wasn't you, simply ignore this email.</strong> Your account remains secure and no changes will be made.
                            </p>

                            <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #eeeeee;'>
                                <p style='color: #666666; font-size: 13px; margin-bottom: 5px;'>If the button above is unresponsive, please copy and paste the following URL into your web browser:</p>
                                <a href='{resetPasswordLink}' style='color: #0C0C84; font-size: 13px; word-break: break-all;'>{resetPasswordLink}</a>
                            </div>
                        </div>
                        
                        <div style='background-color: #f8fafc; padding: 20px 30px; text-align: left; border-top: 1px solid #e2e8f0;'>
                            <p style='color: #888888; font-size: 11px; line-height: 1.5; margin: 0;'>
                                <strong>Security Notice:</strong> This email and any corresponding links are confidential. Do not share this link with anyone. Cebu Eastern College will never ask for your password via email.<br><br>
                                © {DateTime.Now.Year} Cebu Eastern College. All rights reserved.
                            </p>
                        </div>
                        
                    </div>
                </div>" 
            };

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            try
            {
                await client.ConnectAsync(_smtpServer, _smtpPort, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(_gmail, _code);
                await client.SendAsync(message);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SMTP ERROR]: Could not send to {recipientEmail}. Details: {ex.Message}");
                throw; 
            }
            finally
            {
                await client.DisconnectAsync(true);
            }
        }
    }
}