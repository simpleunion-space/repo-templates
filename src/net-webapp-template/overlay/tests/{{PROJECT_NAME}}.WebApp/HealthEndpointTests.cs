using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace {{PROJECT_NAME}}.WebApp.Tests;

/// <summary>
/// Verifies the web application's public health endpoint.
/// </summary>
public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    /// <summary>
    /// Creates the test fixture.
    /// </summary>
    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    /// <summary>
    /// Verifies that the health endpoint returns a successful response.
    /// </summary>
    [Fact]
    public async Task HealthEndpointReturnsOk()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
