# Профиль .NET Console App

Профиль наследует библиотеку `src/{{PROJECT_NAME}}.Core` из `net` и добавляет запускаемое консольное приложение `src/{{PROJECT_NAME}}.ConsoleApp`. Для обоих компонентов создаются одноимённые каталоги tests и build.

`build` собирает библиотеку и приложение в `build`, а `tests` выполняет format-check, xUnit-тесты и smoke-запуск консольного приложения. На Windows, Linux и macOS проверки запускаются только через `docker compose -f tools/docker/tests.yaml run --rm tests`; `tools/scripts/tests.sh` — внутренний entrypoint контейнера.
