# Development

| Action | Command | Side effects |
| --- | --- | --- |
| Verify | `docker compose -f tools/docker/verify.yaml run --rm verify` | Local image/cache; template-contract validation |
| Test | `docker compose -f tools/docker/tests.yaml run --rm tests` | Local image/cache; project tests and linters |
| Build | `docker compose -f tools/docker/build.yaml run --rm build` | Local image/cache and actual build artifacts when the profile creates them |
| Run | `docker compose -f tools/docker/compose.yaml up -d workspace` | Local workspace container |

On Windows, Linux, and macOS, run checks only with the Docker Compose commands above. `make -f make/Makefile <target>` is a Linux/macOS convenience facade over those same Compose commands; `tools/scripts/*.sh` are internal container entrypoints, not public commands. Compose does not run git init, deploy, apply, migrations, or infrastructure operations.

`src`, `make`, `tests`, and `tools` are required. `docs` and `build` are optional and are not created without real content; a profile may declare `build/<component>` required.
