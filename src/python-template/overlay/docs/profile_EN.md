# Python Profile

This profile creates a src package with pyproject.toml, pytest, and Ruff. Development dependencies are listed in the dev dependency group; before the first delivery, establish a reproducible dependency-installation mechanism for the selected environment.

The `src/{{PYTHON_PACKAGE}}` component has a matching `tests/{{PYTHON_PACKAGE}}` directory. `build/{{PYTHON_PACKAGE}}` is required from generation and contains `.gitkeep` until the first build; package artifacts are then written there. `verify` checks the template contract, `build` creates a wheel and sdist, and `tests` runs Ruff and pytest.
