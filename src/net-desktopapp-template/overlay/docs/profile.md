# Профиль .NET Desktop App

Профиль наследует `src/{{PROJECT_NAME}}.Core` из `net` и добавляет кроссплатформенное Avalonia-приложение `src/{{PROJECT_NAME}}.DesktopApp`. Версия Avalonia закреплена в `Directory.Packages.props`.

`build` собирает библиотеку и desktop-приложение в `build`, а `tests` запускает format-check и xUnit-тесты без открытия графического интерфейса.
