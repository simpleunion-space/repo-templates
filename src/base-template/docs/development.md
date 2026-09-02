# Разработка

| Действие | Команда | Побочные эффекты |
| --- | --- | --- |
| Verify | `docker compose -f tools/docker/verify.yaml run --rm verify` | Локальный образ/cache; проверка контракта шаблона |
| Test | `docker compose -f tools/docker/tests.yaml run --rm tests` | Локальный образ/cache; тесты и линтеры проекта |
| Build | `docker compose -f tools/docker/build.yaml run --rm build` | Локальный образ/cache и фактические build-артефакты, если профиль их создаёт |
| Run | `docker compose -f tools/docker/compose.yaml up -d workspace` | Локальный workspace-контейнер |

На Windows, Linux и macOS запускайте проверки только приведёнными командами Docker Compose. `make -f make/Makefile <цель>` — удобный фасад к тем же Compose-командам для Linux и macOS; `tools/scripts/*.sh` — внутренние entrypoint-ы контейнеров, а не публичные команды. Compose не выполняет git init, deploy, apply, миграции или операции с инфраструктурой.

`src`, `make`, `tests` и `tools` обязательны. `docs` и `build` опциональны и не создаются без настоящего содержимого; профиль может объявить `build/<component>` обязательным.
