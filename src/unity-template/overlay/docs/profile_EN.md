# Unity Profile

This profile creates a C# Unity client with Runtime and EditMode assembly definitions in `src/{{PROJECT_NAME}}`. It has a matching `tests/{{PROJECT_NAME}}`; `build/{{PROJECT_NAME}}` is required from generation and contains `.gitkeep` until application artifacts appear. The profile does not add a server or a separate .NET solution.

Set `UNITY_EDITOR_IMAGE` to a compatible GameCI image and run `docker compose -f tools/docker/tests.yaml run --rm tests` for EditMode tests. For a build, also set `UNITY_BUILD_TARGET`: the image must include that platform module, and `build` creates a player through Unity BuildPipeline in `build/{{PROJECT_NAME}}`. Pass the license only through environment variables. The editor version is pinned in `src/{{PROJECT_NAME}}/ProjectSettings/ProjectVersion.txt`.
