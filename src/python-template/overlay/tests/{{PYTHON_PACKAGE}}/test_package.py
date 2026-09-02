"""Template integrity checks."""

from {{PYTHON_PACKAGE}} import project_name


def test_project_name_is_configured() -> None:
    """The generated package exposes its selected identifier."""
    assert project_name() == "{{PROJECT_NAME}}"
