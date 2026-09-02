# IaC Base Profile

This profile does not choose Ansible, Salt, or another tool. It creates `src/modules` and `src/environments`, while required `tests` deliberately contains only `.gitkeep`. `build` remains optional and absent: IaC has no build command. `verify` performs an offline template-contract check, and `tests` has no project test suite.

Before the first apply operation, document the selected tool, its validate and plan commands, secret source, state boundaries, and safe rollback order. Apply must not be the default action and is not added to the Makefile.
