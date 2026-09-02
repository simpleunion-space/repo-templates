# Профиль .NET

Профиль создаёт .NET 10 solution с библиотекой и xUnit-проектом. Центральные версии пакетов находятся в Directory.Packages.props, общие свойства сборки — в Directory.Build.props.

Компонент `src/{{PROJECT_NAME}}.Core` имеет симметричный `tests/{{PROJECT_NAME}}.Core`. `build/{{PROJECT_NAME}}.Core` обязателен с момента генерации и содержит `.gitkeep` до первой сборки; затем туда записываются артефакты библиотеки. `verify` проверяет структуру шаблона, `build` собирает библиотеку, а `tests` запускает format-check и xUnit. Профили `net-consoleapp`, `net-webapp` и `net-desktopapp` наследуют эту библиотеку.
