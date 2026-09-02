# Ansible Profile

This profile creates `src/playbooks`, `src/roles`, and `src/inventories` on the IaC base; `tests` deliberately contains only `.gitkeep`. `build` is absent because Ansible has no build. `verify` checks the template contract, while `tests` runs a pinned ansible-lint version in Docker and does not run playbooks, deploy, or change infrastructure.
