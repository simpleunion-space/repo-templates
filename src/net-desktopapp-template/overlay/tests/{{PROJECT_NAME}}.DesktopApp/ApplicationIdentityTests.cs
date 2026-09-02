using Xunit;

namespace {{PROJECT_NAME}}.DesktopApp.Tests;

/// <summary>
/// Verifies the desktop application's initial identity.
/// </summary>
public sealed class ApplicationIdentityTests
{
    /// <summary>
    /// Verifies that the desktop application uses the core project name.
    /// </summary>
    [Fact]
    public void NameUsesTheCoreProjectName()
    {
        Assert.Equal("{{PROJECT_NAME}}", DesktopApp.ApplicationIdentity.Name);
    }
}
