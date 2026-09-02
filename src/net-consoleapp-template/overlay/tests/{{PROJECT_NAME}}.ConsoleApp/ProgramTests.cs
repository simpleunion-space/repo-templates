using Xunit;

namespace {{PROJECT_NAME}}.ConsoleApp.Tests;

/// <summary>
/// Verifies the console application's initial contract.
/// </summary>
public sealed class ProgramTests
{
    /// <summary>
    /// Verifies that the console application exposes the core project name.
    /// </summary>
    [Fact]
    public void CreateMessageUsesTheCoreProjectName()
    {
        Assert.Equal("{{PROJECT_NAME}}", ConsoleApp.Program.CreateMessage());
    }
}
