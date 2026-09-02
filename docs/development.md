# Разработка

| Действие | Команда | Побочные эффекты |
| --- | --- | --- |
| Test | `docker compose -f tools/docker/tests.yaml run --rm template-tests` | Локальный Docker image/cache; линтеры каталога |
| Verify | `docker compose -f tools/docker/verify.yaml run --rm template-verify` | Локальный Docker image/cache; unittest шаблонов |
| Build | `docker compose -f tools/docker/build.yaml run --rm template-build` | Локальный Docker image/cache; у каталога нет сборки |
| Workspace | `docker compose -f tools/docker/compose.yaml up -d workspace` | Локальный контейнер workspace |

На Windows, Linux и macOS запускайте проверки только приведёнными командами Docker Compose. Те же Compose-команды доступны через `make -f make/Makefile <цель>` как удобный фасад для Linux и macOS; `tools/scripts/*.sh` вызываются контейнерами и не являются публичным способом запуска. Проверка не выполняет git init, deploy, apply, миграции или обращения к инфраструктуре. Docker может загрузить образ тестового окружения при первом запуске.

Каталоговая проверка генерирует все десять профилей во временных каталогах, проверяет `pathRequirements` schema v2 и не затрагивает сохранённые пользовательские `temp` и `.tmp`. Регрессия Windows bind mount записывает диагностические результаты обоих генераторов в отдельные уникальные каталоги игнорируемого `.cache/template-bind-mount`; контейнерный `/tmp` остаётся эталонной файловой системой. Генераторы всегда собирают результат во внутреннем temporary-каталоге и публикуют его в назначение только после успешной проверки.
