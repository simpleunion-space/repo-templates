using Xunit;

namespace {{PROJECT_NAME}}.Core.Tests;

/// <summary>
/// Verifies that the generated project identifier reaches the compiled assembly.
/// </summary>
public sealed class TemplateIntegrityTests
{
    /// <summary>
    /// Checks the initial marker.
    /// </summary>
    [Fact]
    public void ProjectNameIsConfigured()
    {
        Assert.Equal("{{PROJECT_NAME}}", Core.TemplateMarker.ProjectName);
    }
}
