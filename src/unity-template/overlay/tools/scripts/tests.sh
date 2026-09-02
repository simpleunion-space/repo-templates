#!/usr/bin/env sh
set -eu

# shellcheck disable=SC1091
. "tests/{{PROJECT_NAME}}/unity-runner.env"
UNITY_EXECUTABLE=${UNITY_EXECUTABLE:-/opt/Unity/Editor/Unity}

"$UNITY_EXECUTABLE" \
    -batchmode \
    -nographics \
    -quit \
    -projectPath "/workspace/src/{{PROJECT_NAME}}" \
    -runTests \
    -testPlatform "$UNITY_TEST_PLATFORM" \
    -testResults "$UNITY_TEST_RESULTS" \
    -logFile "$UNITY_TEST_LOG"
