# Repository Guidelines

Read the README, development document, and Git status first. Preserve a user's uncommitted work and do not revert it without an explicit request.

Default to read-only analysis and local verification. For every Russian Markdown document that is added or changed, update its English pair in the same task.

Do not perform deploy or apply operations, migrations, data deletion, shared-resource cleanup, artifact publishing, Git history rewrites, or external infrastructure changes without explicit confirmation. Do not add real secrets to Git; use safe configuration examples only.

Document the project's actual commands in docs/development_EN.md. On Windows, Linux, and macOS, run checks only through Compose files or `make -f make/Makefile <target>` as a facade over them; `tools/scripts/*.sh` are internal container entrypoints. Do not declare commands allowed when they do not exist in the project or need external side effects.

Preserve the required `src`, `make`, `tests`, and `tools`. `docs` and `build` are optional: do not add them without real content, and record profile requirements in `pathRequirements`.

`verify.sh` checks the template contract, `build.sh` creates artifacts only where applicable, and `tests.sh` runs project tests and linters.
