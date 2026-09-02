# Development

| Action | Command | Side effects |
| --- | --- | --- |
| Test | `docker compose -f tools/docker/tests.yaml run --rm template-tests` | Local Docker image/cache; catalog linters |
| Verify | `docker compose -f tools/docker/verify.yaml run --rm template-verify` | Local Docker image/cache; template unittests |
| Build | `docker compose -f tools/docker/build.yaml run --rm template-build` | Local Docker image/cache; the catalog has no build |
| Workspace | `docker compose -f tools/docker/compose.yaml up -d workspace` | Local workspace container |

On Windows, Linux, and macOS, run checks only with the Docker Compose commands above. The same Compose commands are available through `make -f make/Makefile <target>` as a Linux/macOS convenience facade; `tools/scripts/*.sh` are invoked by containers and are not a public launch method. Validation does not run git init, deploy, apply, migrations, or contact infrastructure. Docker may download the test environment image on its first run.

The catalog check generates all ten profiles in temporary directories, validates schema v2 `pathRequirements`, and does not touch saved user `temp` or `.tmp` directories. The Windows bind-mount regression writes both generators' diagnostic output to separate unique directories under ignored `.cache/template-bind-mount`; the container's `/tmp` remains the reference filesystem. Generators always compose in a private temporary directory and publish to the requested destination only after validation succeeds.
