# Repository Template Catalog

This catalog contains a neutral base template and profile overlays under `src`. A new repository is created from `base-template` plus exactly one final profile.

## Templates

| Directory | Purpose |
| --- | --- |
| src/base-template | Shared documentation, safety rules, and basic structure. |
| src/net-template | .NET 10 solution, library, and unit tests. |
| src/net-consoleapp-template | A .NET console application on the net library. |
| src/net-webapp-template | A .NET Razor Pages application on the net library. |
| src/net-desktopapp-template | A cross-platform Avalonia application on the net library. |
| src/python-template | A src Python package with pytest and Ruff. |
| src/unity-template | A C# Unity client with EditMode tests. |
| src/iac-base-template | A tool-neutral IaC base. |
| src/ansible-template | Ansible on top of the IaC base. |
| src/salt-template | Salt on top of the IaC base. |

## Create a project

On Windows, run `make/New-RepositoryFromTemplate.ps1`; on Linux and macOS, run `make/New-RepositoryFromTemplate.sh`. Both generators take a profile, name, and empty destination directory; they compose and validate the result in a private temporary directory, then publish the completed tree without overwriting user files. Neither initializes Git nor runs external commands. Linux and macOS can use `make -f make/Makefile generate-bash`; Windows can use `generate-powershell`.

## Validate the catalog

Run `docker compose -f tools/docker/verify.yaml run --rm template-verify` for catalog unittests and `docker compose -f tools/docker/tests.yaml run --rm template-tests` for linters. Validation compares PowerShell and Bash output in temporary directories without building generated projects.

Every generated repository requires `src`, `make`, `tests`, and `tools`; `docs` and `build` are optional. An optional directory is created only when it has real files, and `.gitkeep` is not content. .NET, Python, and Unity maintain matching src/tests components; IaC, Ansible, and Salt leave tests empty with `.gitkeep`. `build/<component>` is required only for .NET, Python, and Unity profiles. The template catalog itself is an exception: its single catalog check is `tests/test_templates.py` and does not mirror `src`. Docker Compose is the single source of behaviour for `verify`, `build`, `tests`, and the local `workspace`: on Windows, Linux, and macOS, run checks with Compose commands, while `tools/scripts/*.sh` are internal container entrypoints.

See AGENTS_EN.md for agent operating rules.
