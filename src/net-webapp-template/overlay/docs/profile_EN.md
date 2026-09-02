# .NET Web App Profile

This profile inherits `src/{{PROJECT_NAME}}.Core` from `net` and adds the runnable `src/{{PROJECT_NAME}}.WebApp` Razor Pages application with a `/health` endpoint. The application has matching tests and build directories.

`build` compiles the library and web application into `build`; `tests` performs format validation and runs xUnit, including an HTTP check for `/health`.
