# {{PROJECT_NAME}}

Briefly describe the purpose and boundaries of the project.

## Structure

- src contains required source material or project code grouped by component.
- tests contains required project tests; a profile may leave it empty with `.gitkeep`.
- make is the required Docker Compose facade for Linux and macOS.
- tools/scripts contains required verification scripts.
- tools/docker contains required Docker Compose entry points.
- docs is optional extended documentation: it exists only when it has real documents.
- build is optional build output: it is not created without actual artifacts unless a profile declares it required.

Path statuses are declared through `pathRequirements` in `.template/template.json`. A file inherits the status of its nearest marked directory, and an exact file rule can override it. `.gitkeep` preserves a required empty structure but does not make an optional directory non-empty.

## Working with the project

Use `make -f make/Makefile verify`, `build`, `tests`, `up`, and `down`, or the equivalent Compose commands in docs/development_EN.md. `verify` checks the generated template contract, `build` creates project artifacts, and `tests` runs project tests and linters. CI must run the same checks as local development.

## Configuration and secrets

Version only safe defaults and example files. Supply secrets through environment variables, a secret store, or protected CI variables.

## Documentation

See the documentation index in docs/README_EN.md, the rules in CODESTYLE_EN.md, and instructions in AGENTS_EN.md. Create MODEL_EN.md and ARCHITECTURE_EN.md only when the project has a stable domain model or a multi-component architecture.
