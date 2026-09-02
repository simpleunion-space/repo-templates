using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;

namespace {{PROJECT_NAME}}.Editor
{
    public static class TemplateBuild
    {
        private const string BootstrapScene = "Assets/{{PROJECT_NAME}}/Scenes/Bootstrap.unity";

        public static void Build()
        {
            var output = Environment.GetEnvironmentVariable("UNITY_BUILD_OUTPUT");
            if (string.IsNullOrWhiteSpace(output))
            {
                throw new InvalidOperationException("UNITY_BUILD_OUTPUT must be set.");
            }

            if (!File.Exists(BootstrapScene))
            {
                throw new FileNotFoundException("The template build scene is missing.", BootstrapScene);
            }

            Directory.CreateDirectory(Path.GetDirectoryName(output)!);
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = new[] { BootstrapScene },
                locationPathName = output,
                target = EditorUserBuildSettings.activeBuildTarget,
                options = BuildOptions.None
            });

            if (report.summary.result != BuildResult.Succeeded)
            {
                throw new InvalidOperationException($"Unity build failed: {report.summary.result}.");
            }
        }
    }
}
