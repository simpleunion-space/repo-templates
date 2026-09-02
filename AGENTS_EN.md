# Repository Guidelines

This repository maintains templates rather than a finished product. Changes in base-template must stay technology-neutral; stack-specific settings belong only in the matching profile.

Before editing, read the root README, the profile manifest, and its paired bilingual document. Update Russian and English versions in the same task. Do not add nested Git repositories, real secrets, production configuration, or delivery artifacts.

After changing a generator, manifest, base, or profile overlay, run `docker compose -f tools/docker/verify.yaml run --rm template-verify` and `docker compose -f tools/docker/tests.yaml run --rm template-tests`. On Windows, Linux, and macOS, launch checks only through Docker Compose; containers invoke `tools/scripts/*.sh`. Use `make/New-RepositoryFromTemplate.ps1` or `make/New-RepositoryFromTemplate.sh` only with an empty temporary directory when testing generation. Compose creates only a local test image/cache; catalog scripts do not run git init, deploy, apply, or infrastructure operations.

`pathRequirements` in a manifest is the source of truth for required and optional paths. Preserve all required files in `src`, `make`, `tests`, and `tools`; do not create `docs` or `build` without real content. .NET, Python, and Unity are the exception: they declare required component directories in `build`.

`verify.sh` checks the template contract, `build.sh` creates project artifacts only for profiles that support builds, and `tests.sh` runs project tests and linters. IaC, Ansible, and Salt do not receive test component directories.

Preserve existing working-tree changes first. Explicit confirmation is required for data deletion, Git history rewrites, publishing, deploy/apply, migrations, and operations against external infrastructure.
