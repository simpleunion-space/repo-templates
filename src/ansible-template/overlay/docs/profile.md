# Профиль Ansible

Профиль создаёт `src/playbooks`, `src/roles` и `src/inventories` поверх IaC-базы; `tests` намеренно содержит только `.gitkeep`. `build` не создаётся, поскольку Ansible не имеет сборки. `verify` проверяет контракт шаблона, а `tests` запускает фиксированную версию ansible-lint в Docker и не выполняет playbook, deploy или изменения инфраструктуры.
