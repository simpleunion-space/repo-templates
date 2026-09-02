# Каталог шаблонов репозиториев

Этот каталог содержит нейтральный базовый шаблон и профильные overlays в `src`. Новый репозиторий создаётся из `base-template` и одного конечного профиля.

## Шаблоны

| Каталог | Назначение |
| --- | --- |
| src/base-template | Общая документация, правила безопасности и базовая структура. |
| src/net-template | .NET 10 solution, библиотека и unit-тесты. |
| src/net-consoleapp-template | Консольное приложение .NET поверх библиотеки net. |
| src/net-webapp-template | Razor Pages-приложение .NET поверх библиотеки net. |
| src/net-desktopapp-template | Кроссплатформенное Avalonia-приложение поверх библиотеки net. |
| src/python-template | Python-пакет в src с pytest и Ruff. |
| src/unity-template | Unity-клиент на C# с EditMode-тестами. |
| src/iac-base-template | Инструмент-независимая база IaC. |
| src/ansible-template | Ansible поверх IaC-базы. |
| src/salt-template | Salt поверх IaC-базы. |

## Создание проекта

На Windows запустите `make/New-RepositoryFromTemplate.ps1`; на Linux и macOS — `make/New-RepositoryFromTemplate.sh`. Оба генератора принимают профиль, имя и пустой каталог назначения, собирают и проверяют результат во внутреннем temporary-каталоге, а затем публикуют готовое дерево без перезаписи пользовательских файлов. Они не инициализируют Git и не запускают внешние команды. Для Linux и macOS доступен фасад `make -f make/Makefile generate-bash`; для Windows — `generate-powershell`.

## Проверка каталога

Запустите `docker compose -f tools/docker/verify.yaml run --rm template-verify` для каталоговых unittest и `docker compose -f tools/docker/tests.yaml run --rm template-tests` для линтеров. Проверка сопоставляет результаты PowerShell и Bash во временных каталогах, не выполняя сборку созданных проектов.

Во всех генерируемых репозиториях обязательны `src`, `make`, `tests` и `tools`; `docs` и `build` опциональны. Опциональный каталог создаётся только при наличии настоящих файлов, а `.gitkeep` не считается содержимым. .NET, Python и Unity поддерживают одноимённые src/tests-компоненты; IaC, Ansible и Salt оставляют tests пустым с `.gitkeep`. `build/<component>` обязателен только у .NET, Python и Unity. Сам каталог шаблонов — исключение: его единая проверка расположена в `tests/test_templates.py` и не повторяет `src`. Docker Compose — единственный источник поведения для `verify`, `build`, `tests` и локального `workspace`: на Windows, Linux и macOS проверки запускаются командами Compose, а `tools/scripts/*.sh` служат внутренними entrypoint-ами контейнеров.

Подробные правила работы агентов описаны в AGENTS.md.
