# Профиль Salt

Профиль создаёт `src/states` и `src/pillar` поверх IaC-базы; `tests` намеренно содержит только `.gitkeep`. `build` не создаётся, поскольку Salt не имеет сборки. `verify` проверяет контракт шаблона, а `tests` запускает salt-lint в Docker и не запускает state.apply или внешние операции.
