# claude-plugins

Personal Claude Code plugins

## Plugins

### `presentation-skill`

Build polished slide decks (`.pptx`) using pptxgenjs.

- Runs an intake questionnaire before generating any slides
- Enforces presentation design principles (slides as backdrops, not documents)
- Handles internal vs. external presentations differently
- Produces image placeholder briefs ready for an image-gen agent
- Visual QA loop using LibreOffice + pdftoppm

**Skill:** `/presentation-skill:build-deck`

### `security-review`

General-purpose security review agent backed by [Trivy](https://trivy.dev) and the [`gh` CLI](https://cli.github.com).

Three invocation modes:
1. **Pre-install review** — scan a local directory or GitHub repo before installing
2. **Orchestrator sub-agent** — automated step in a coding plan, returns structured `PASS/WARN/FAIL`
3. **PR review** — augment a pull request review with Trivy CVE scan + diff analysis

**Skills:** `/security-review:security-review`, `/security-review:trivy-scan`

---

## Installation

```bash
# Add this marketplace
/plugin marketplace add ambantis/claude-plugins

# Install individual plugins
/plugin install presentation-skill@ambantis-claude-plugins
/plugin install security-review@ambantis-claude-plugins
```

### First-time setup for `presentation-skill`

The presentation skill uses a local Node.js project for slide generation.
After installing, run `npm ci` in the plugin directory:

```bash
cd ~/.claude/plugins/cache/presentation-skill
npm ci
```

### First-time setup for `security-review`

Requires Trivy and the trivy-mcp plugin. Run the prereq check:

```bash
bash ~/.claude/plugins/cache/security-review/scripts/check_prereqs.sh
```

Follow the instructions it prints for anything missing.

---

## Prerequisites

| Plugin | System dependency |
|---|---|
| `presentation-skill` | Node.js ≥ 22 (Volta recommended), LibreOffice, Poppler (`pdftoppm`), Python + `markitdown` |
| `security-review` | [Trivy](https://trivy.dev/docs/getting-started/installation/), `trivy plugin install mcp`, `gh` CLI |

---

## License

MIT — see [LICENSE](LICENSE).
