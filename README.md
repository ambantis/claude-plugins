# claude-plugins

## Introduction

A collection of Claude Code plugins for presentation building and security
review. Each plugin adds skills that Claude Code can invoke during a
conversation.

To add this plugin repository and install individual plugins:

```bash
/plugin marketplace add ambantis/claude-plugins
/plugin install presentation-skill@ambantis-code-plugins
/plugin install security-review@ambantis-code-plugins
```

After installing a plugin, follow its **Getting Started** section below to
set up system dependencies.

---

## Plugins

### presentation-skill

#### Capabilities

Build polished slide decks (`.pptx`) from a conversation with Claude Code.

- Runs an intake questionnaire to establish audience, thesis, and narrative arc
- Generates `.pptx` files using [pptxgenjs](https://gitbrent.github.io/PptxGenJS/) (Node.js)
- Enforces presentation design principles — slides as backdrops, not documents
- Handles internal vs. external presentations differently (About Me, legal disclaimer, context-setting)
- Produces image placeholder briefs ready for an image-generation agent
- Content QA via [markitdown](https://github.com/microsoft/markitdown) (text extraction and verification)
- Visual QA loop — converts slides to images so the agent can inspect layout, overflow, and spacing

**Skill:** `/presentation-skill:build-deck`

#### Getting Started

The presentation skill requires four system dependencies:

| Dependency | Purpose |
|---|---|
| Node.js ≥ 22 | Runs pptxgenjs to generate the `.pptx` file |
| [uv](https://docs.astral.sh/uv/) | Manages Python + markitdown for content QA (no system Python needed) |
| Microsoft PowerPoint (macOS) or LibreOffice | Visual QA step 1 — converts `.pptx` to PDF |
| Poppler (`pdftoppm`) | Visual QA step 2 — converts PDF to per-slide JPEG images |

##### macOS

```bash
# Node.js (via Volta — recommended)
curl https://get.volta.sh | bash
volta install node@22

# uv (manages Python + markitdown automatically)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Visual QA: if Microsoft PowerPoint is already installed, no action needed.
# Otherwise, install LibreOffice:
brew install --cask libreoffice

# Poppler (provides pdftoppm)
brew install poppler
```

##### Ubuntu / Debian

```bash
# Node.js (via Volta — recommended)
curl https://get.volta.sh | bash
volta install node@22

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# LibreOffice
sudo apt-get install -y libreoffice

# Poppler (provides pdftoppm)
sudo apt-get install -y poppler-utils
```

##### Red Hat / Fedora

```bash
# Node.js (via Volta — recommended)
curl https://get.volta.sh | bash
volta install node@22

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# LibreOffice
sudo dnf install -y libreoffice-impress

# Poppler (provides pdftoppm)
sudo dnf install -y poppler-utils
```

##### Arch Linux

```bash
# Node.js (via Volta — recommended)
curl https://get.volta.sh | bash
volta install node@22

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# LibreOffice
sudo pacman -S libreoffice-still

# Poppler (provides pdftoppm)
sudo pacman -S poppler
```

##### Install plugin dependencies

After system dependencies are in place, install project dependencies:

```bash
cd ~/.claude/plugins/cache/presentation-skill
npm ci
uv sync
```

---

### security-review

#### Capabilities

Security review plugin backed by [Trivy](https://trivy.dev) and the [`gh` CLI](https://cli.github.com).

- **Pre-install marketplace review** — discovers all scripts, hooks, and installation requirements in a plugin; presents an analysis plan; dispatches parallel subagents to evaluate each
- **Script analysis** — static analysis of a shell or Python script: pattern matching for network calls, credential access, and dangerous patterns, plus LLM reasoning about intent
- **Sandboxed installation scan** — installs a package into an isolated `uv` virtualenv and runs Trivy against it before touching the system
- **Orchestrator sub-agent** — automated security step in a coding plan, returns structured `PASS` / `WARN` / `FAIL`
- **PR review** — augment a pull request review with a Trivy CVE scan and diff analysis for secrets and risky patterns

**Skills:** `/security-review:evaluate-marketplace`, `/security-review:evaluate-script`, `/security-review:evaluate-installation`, `/security-review:trivy-scan`, `/security-review:security-review`

#### Getting Started

The security review skill requires two system dependencies:

| Dependency | Purpose |
|---|---|
| [Trivy](https://trivy.dev) | CVE and secret scanning |
| [`gh` CLI](https://cli.github.com) | PR diff retrieval and review posting |

##### macOS

```bash
brew install trivy gh
gh auth login
```

##### Ubuntu / Debian

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin
sudo apt-get install -y gh
gh auth login
```

##### Red Hat / Fedora

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin
sudo dnf install -y gh
gh auth login
```

##### Arch Linux

```bash
sudo pacman -S trivy github-cli
gh auth login
```

##### Verify setup

```bash
bash ~/.claude/plugins/cache/security-review/scripts/check_prereqs.sh
```

---

## License

MIT — see [LICENSE](LICENSE).
