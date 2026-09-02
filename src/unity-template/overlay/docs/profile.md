# Профиль Unity

Профиль создаёт Unity-клиент на C# с Runtime и EditMode assembly definitions в `src/{{PROJECT_NAME}}`. Ему соответствует `tests/{{PROJECT_NAME}}`; `build/{{PROJECT_NAME}}` обязателен с момента генерации и содержит `.gitkeep` до появления артефактов приложения. Профиль не добавляет сервер или отдельную .NET solution.

Для запуска EditMode-тестов задайте `UNITY_EDITOR_IMAGE` с совместимым GameCI-образом и выполните `docker compose -f tools/docker/tests.yaml run --rm tests`. Для сборки дополнительно задайте `UNITY_BUILD_TARGET`: образ должен содержать модуль выбранной платформы, а `build` создаёт player через Unity BuildPipeline в `build/{{PROJECT_NAME}}`. Лицензия передаётся только через переменные окружения. Версия редактора фиксируется в `src/{{PROJECT_NAME}}/ProjectSettings/ProjectVersion.txt`.
