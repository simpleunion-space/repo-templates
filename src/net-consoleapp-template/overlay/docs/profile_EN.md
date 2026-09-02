# .NET Console App Profile

This profile inherits the `src/{{PROJECT_NAME}}.Core` library from `net` and adds the runnable `src/{{PROJECT_NAME}}.ConsoleApp` console application. Both components have matching tests and build directories.

`build` compiles the library and application into `build`, while `tests` runs format validation, xUnit tests, and a console-application smoke run. On Windows, Linux, and macOS, run checks only through `docker compose -f tools/docker/tests.yaml run --rm tests`; `tools/scripts/tests.sh` is the container's internal entrypoint.
