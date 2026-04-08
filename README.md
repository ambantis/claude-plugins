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

General-purpose security review agent backed by [Trivy](https://trivy.dev)
and the [`gh` CLI](https://cli.github.com). Three invocation modes:

1. **Pre-install review** — scan a local directory or GitHub repo before installing a plugin or dependency
2. **Orchestrator sub-agent** — automated security step in a coding plan, returns structured `PASS` / `WARN` / `FAIL`
3. **PR review** — augment a pull request review with a Trivy CVE scan and diff analysis for secrets and risky patterns

**Skills:** `/security-review:security-review`, `/security-review:trivy-scan`

#### Getting Started

The security review skill requires three system dependencies:

| Dependency | Purpose |
|---|---|
| [Trivy](https://trivy.dev) | Vulnerability and secret scanning |
| trivy-mcp plugin | Enables Claude Code to invoke Trivy via MCP |
| [`gh` CLI](https://cli.github.com) | PR diff retrieval and review posting |

##### macOS

```bash
# Trivy
brew install trivy

# gh CLI
brew install gh
gh auth login
```

##### Ubuntu / Debian

```bash
# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin

# gh CLI
sudo apt-get install -y gh
gh auth login
```

##### Red Hat / Fedora

```bash
# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin

# gh CLI
sudo dnf install -y gh
gh auth login
```

##### Arch Linux

```bash
# Trivy
sudo pacman -S trivy

# gh CLI
sudo pacman -S github-cli
gh auth login
```

##### Configure Trivy MCP (all platforms)

```bash
# Install the trivy-mcp plugin
trivy plugin install mcp

# Register with Claude Code
claude mcp add trivy --scope user -- trivy mcp
```

##### Verify setup

```bash
bash ~/.claude/plugins/cache/security-review/scripts/check_prereqs.sh
```

The script checks all prerequisites and prints instructions for anything missing.

---

## License

MIT — see [LICENSE](LICENSE).
