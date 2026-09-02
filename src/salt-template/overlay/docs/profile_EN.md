# Salt Profile

This profile creates `src/states` and `src/pillar` on the IaC base; `tests` deliberately contains only `.gitkeep`. `build` is absent because Salt has no build. `verify` checks the template contract, while `tests` runs salt-lint in Docker and does not run state.apply or external operations.
