using {{PROJECT_NAME}}.Core;

namespace {{PROJECT_NAME}}.DesktopApp;

/// <summary>
/// Provides the application identity from the shared core library.
/// </summary>
public static class ApplicationIdentity
{
    /// <summary>
    /// Gets the generated project name.
    /// </summary>
    public static string Name => TemplateMarker.ProjectName;
}
