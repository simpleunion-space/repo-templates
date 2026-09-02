namespace {{PROJECT_NAME}}.Core;

/// <summary>
/// Identifies the initial template assembly until domain code replaces it.
/// </summary>
public static class TemplateMarker
{
    /// <summary>
    /// Gets the project identifier selected during template generation.
    /// </summary>
    public const string ProjectName = "{{PROJECT_NAME}}";
}
