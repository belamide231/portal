using Microsoft.AspNetCore.Http;

namespace MyApp.Namespace
{
    public class CookieService
    {
        // This method returns the settings for your Refresh Token
        public CookieOptions GetAccessTokenOptions()
        {
            return new CookieOptions
            {
                HttpOnly = true,      // Security: JS cannot touch this
                Secure = true,        // Security: Only works over HTTPS
                SameSite = SameSiteMode.Lax, // "Not Strict": Better for cross-page navigation
                // Note: By not setting 'Expires', it becomes a SESSION cookie.
            };            
        }


        public CookieOptions GetRefreshTokenOptions()
        {
            return new CookieOptions
            {
                HttpOnly = true,      // Security: JS cannot touch this
                Secure = true,        // Security: Only works over HTTPS
                SameSite = SameSiteMode.Lax, // "Not Strict": Better for cross-page navigation
                // Note: By not setting 'Expires', it becomes a SESSION cookie.
            };
        }
    }
}