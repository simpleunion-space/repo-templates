using NUnit.Framework;
using {{PROJECT_NAME}}.Runtime;

namespace {{PROJECT_NAME}}.Tests
{
    /// <summary>
    /// Verifies that the generated Unity assembly is configured.
    /// </summary>
    public sealed class TemplateIntegrityTests
    {
        /// <summary>
        /// Checks the initial project marker.
        /// </summary>
        [Test]
        public void ProjectNameIsConfigured()
        {
            Assert.That(TemplateMarker.ProjectName, Is.EqualTo("{{PROJECT_NAME}}"));
        }
    }
}
