# Dependency Reference

## Node.js packages

All scoped to `presentation-skill/node_modules/` — never global:

| Package | Purpose |
|---|---|
| `pptxgenjs` | Generates the `.pptx` file |
| `react-icons` | SVG icon library for slide icons |
| `react` + `react-dom` | Peer deps for react-icons rendering |
| `sharp` | Rasterizes SVG icons to PNG for embedding |

## Python packages

Managed by `uv` via `pyproject.toml` — no system Python required:

| Package | Purpose |
|---|---|
| `markitdown[pptx]` | Extracts text/structure from `.pptx` files for content QA |

Install with `uv sync`. Invoke with `uv run python -m markitdown`.

## System dependencies

- `LibreOffice` — PDF conversion for visual QA
- `poppler` (`pdftoppm`) — PDF to JPEG for slide inspection

## External references

- pptxgenjs API: https://gitbrent.github.io/PptxGenJS/
- Canonical example deck: https://www.scylladb.com/tech-talk/scaling-up-machine-learning-experimentation-at-tubi-5x-and-beyond/
