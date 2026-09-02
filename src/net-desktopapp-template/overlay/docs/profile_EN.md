# .NET Desktop App Profile

This profile inherits `src/{{PROJECT_NAME}}.Core` from `net` and adds the cross-platform Avalonia application `src/{{PROJECT_NAME}}.DesktopApp`. The Avalonia version is pinned in `Directory.Packages.props`.

`build` compiles the library and desktop application into `build`, while `tests` runs format validation and xUnit tests without opening a GUI.
