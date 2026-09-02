# Профиль .NET Web App

Профиль наследует `src/{{PROJECT_NAME}}.Core` из `net` и добавляет запускаемое Razor Pages-приложение `src/{{PROJECT_NAME}}.WebApp` с endpoint `/health`. Для приложения создаются одноимённые каталоги tests и build.

`build` собирает библиотеку и web-приложение в `build`; `tests` выполняет format-check и запускает xUnit, включая HTTP-проверку `/health`.
