# Code Style

Formatting is defined by `.editorconfig` and `.gitattributes`. Use UTF-8, LF, a final newline, and space indentation.

Catalog scripts and tests must remain cross-platform: do not use GNU-only Bash options, and keep PowerShell and Bash generator output identical.

For .NET, Python, and Unity, maintain a matching `tests/<component>` for every `src/<component>`. IaC, Ansible, and Salt retain only `tests/.gitkeep`. Add `build/<component>` only when a profile manifest declares it required or it is an actual build result.
