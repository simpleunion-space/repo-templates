using {{PROJECT_NAME}}.Core;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorPages();

var app = builder.Build();
app.UseStaticFiles();
app.MapGet("/health", () => Results.Ok(new { project = TemplateMarker.ProjectName }));
app.MapRazorPages();
app.Run();

/// <summary>
/// Exposes the web application entry point to integration tests.
/// </summary>
public partial class Program;
