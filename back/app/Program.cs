using MySql.Data.MySqlClient;
using Microsoft.Extensions.FileProviders;
using dotenv.net;

using Services;
using Middlewares;
using System.Security.Principal;

DotEnv.Load();

var builder = WebApplication.CreateBuilder(args);

var connectionString = Environment.GetEnvironmentVariable("DB_CONNECTION");
var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET");

builder.Services.AddScoped<MySqlConnection>(sp => new MySqlConnection(connectionString));
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<IEmailService, EmailService>();

builder.Services.AddScoped<AccountService>();

builder.Services.AddControllers();
builder.Services.AddOpenApi();
// 1. Add the service
builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials());
});

var app = builder.Build();

// --- DEBUG: LOG THE PATHS TO CONSOLE ---
string physicalWwwroot = Path.Combine(app.Environment.ContentRootPath, "wwwroot");

// --- 4. Configure HTTP Pipeline ---

// 1. Static Files must be FIRST to bypass Auth Middleware
// This enables standard wwwroot serving
app.UseStaticFiles(); 

// 2. Explicitly Map the Uploads folder to ensure it's browsable
// This maps http://localhost:5138/uploads to the physical folder
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(physicalWwwroot),
    RequestPath = "" // Leave empty so /uploads/images works directly
});

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseRouting();
app.UseCors("AllowAngular");

// app.UseMiddleware<AuthExtractor>();
// app.UseAuthentication();
// app.UseAuthorization();

app.MapControllers();

// app.MapHub<OnlineHub>("/online");

app.Run();