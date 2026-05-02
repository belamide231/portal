using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class MediaController : ControllerBase
    {
        
        [HttpGet("get-media/{*fileName}")]
        public IActionResult GetMedia(string fileName)
        {

            string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", fileName);

            if (!System.IO.File.Exists(path))
            {
                return NotFound();
            }

            // Dynamic content type detection
            string contentType = fileName.EndsWith(".mp4", StringComparison.OrdinalIgnoreCase) 
                ? "video/mp4" 
                : "image/jpeg";

            return PhysicalFile(path, contentType, enableRangeProcessing: true);
        }
    }
}
