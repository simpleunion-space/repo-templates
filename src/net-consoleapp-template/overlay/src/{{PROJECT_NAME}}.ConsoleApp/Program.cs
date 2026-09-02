using {{PROJECT_NAME}}.Core;

namespace {{PROJECT_NAME}}.ConsoleApp;

/// <summary>
/// Provides the console entry point for the generated application.
/// </summary>
public static class Program
{
    /// <summary>
    /// Creates the initial message from the shared core library.
    /// </summary>
    public static string CreateMessage() => TemplateMarker.ProjectName;

    /// <summary>
    /// Writes the initial message to standard output.
    /// </summary>
    public static void Main()
    {
        Console.WriteLine(CreateMessage());
    }
}
