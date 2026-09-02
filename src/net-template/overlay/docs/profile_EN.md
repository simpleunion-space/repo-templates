# .NET Profile

This profile creates a .NET 10 solution with a library and an xUnit project. Central package versions live in Directory.Packages.props and shared build properties live in Directory.Build.props.

The `src/{{PROJECT_NAME}}.Core` component has a matching `tests/{{PROJECT_NAME}}.Core` directory. `build/{{PROJECT_NAME}}.Core` is required from generation and contains `.gitkeep` until the first build; library artifacts are then written there. `verify` checks the template structure, `build` compiles the library, and `tests` runs format validation and xUnit. The `net-consoleapp`, `net-webapp`, and `net-desktopapp` profiles inherit this library.
