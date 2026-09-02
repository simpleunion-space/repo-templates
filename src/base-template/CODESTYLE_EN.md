# Code Style

Formatting is defined by project configuration files. Use UTF-8, LF, a final newline, and space indentation unless a profile defines a narrower rule.

A behavior change includes corresponding test and documentation updates. Generated, vendor, and third-party material is not edited by hand; change its source or generation process.

Stack-specific rules, analyzers, naming conventions, and formatters belong only in a profile overlay. Do not copy them into the neutral base-template.

A profile with testable components matches `src/<component>` and `tests/<component>`; a profile without project tests retains only `tests/.gitkeep`. Add `build/<component>` only for a required profile rule or as an actual build result.
