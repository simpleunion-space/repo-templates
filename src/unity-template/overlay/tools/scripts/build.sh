#!/usr/bin/env sh
set -eu

: "${UNITY_BUILD_TARGET:?Set UNITY_BUILD_TARGET to a Unity build target.}"

UNITY_EXECUTABLE=${UNITY_EXECUTABLE:-/opt/Unity/Editor/Unity}
export UNITY_BUILD_OUTPUT="/workspace/build/{{PROJECT_NAME}}/{{PROJECT_NAME}}"

"$UNITY_EXECUTABLE" \
    -batchmode \
    -nographics \
    -quit \
    -projectPath "/workspace/src/{{PROJECT_NAME}}" \
    -buildTarget "$UNITY_BUILD_TARGET" \
    -executeMethod "{{PROJECT_NAME}}.Editor.TemplateBuild.Build" \
    -logFile "/workspace/build/{{PROJECT_NAME}}/unity-build.log"
