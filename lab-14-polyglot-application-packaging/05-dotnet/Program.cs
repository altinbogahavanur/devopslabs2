var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Json(new {
    message = ".NET 8 ASP.NET Core API Basariyla Calisiyor!",
    framework = ".NET 8.0 Minimal API",
    os = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
    timestamp = DateTime.UtcNow
}));

app.MapGet("/health", () => Results.Json(new {
    status = "healthy",
    service = "dotnet-api"
}));

app.Run();
