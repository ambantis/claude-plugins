# Contributing

## Versioning

Plugin versions are managed **exclusively in `.claude-plugin/marketplace.json`** and
must not be duplicated in individual `plugin.json` files. This follows the
[Claude Code docs recommendation](https://code.claude.com/docs/en/plugin-marketplaces#version-resolution-and-release-channels)
for relative-path plugins.

When releasing a change:

1. Bump the `version` field in the relevant plugin entry in
   `.claude-plugin/marketplace.json`.
2. Do **not** add a `version` field to `plugins/<name>/.claude-plugin/plugin.json`.
3. Follow [semantic versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`):
   - **MAJOR** — breaking changes (incompatible behavior or removed skills)
   - **MINOR** — new features or skills (backward-compatible)
   - **PATCH** — bug fixes (backward-compatible)
