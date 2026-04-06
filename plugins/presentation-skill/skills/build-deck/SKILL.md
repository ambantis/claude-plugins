---
name: presentation
description: >
  Build polished slide decks (.pptx) using pptxgenjs. Use this skill whenever
  a user asks to create a presentation, deck, or slides — or when a topic and
  audience have been established and slides are the next logical output. Triggers
  include: "build me a presentation", "create a slide deck", "make slides for",
  "I need a deck", "turn this into a presentation". Always run the intake
  questionnaire (in PRESENTATION_STYLE.md) before generating any slides.
  Read PRESENTATION_STYLE.md before doing anything else in this skill.
---

# Presentation Skill

Generates `.pptx` slide decks using a self-contained Node.js project.
Dependencies are scoped to this directory — nothing installs globally.

**Read `PRESENTATION_STYLE.md` before starting.** It contains the design
principles, the intake questionnaire, and the anti-patterns to avoid. Do not
skip it.

---

## Directory Layout

```
presentation-skill/
├── SKILL.md                  ← this file
├── PRESENTATION_STYLE.md     ← design principles + intake questionnaire
├── package.json              ← pptxgenjs, react-icons, sharp, react, react-dom
├── package-lock.json         ← lockfile (Trivy scans this)
├── .node-version             ← pins Node 24 (Volta-compatible)
├── .gitignore
├── src/
│   ├── build_deck.js         ← slide generator (Claude Code populates this)
│   └── design_system.js      ← palette, fonts, layout helpers (shared)
└── output/                   ← generated .pptx files land here (gitignored)
```

---

## Step 0 — Security Check (optional but recommended)

Before running `npm ci` for the first time, or after any `package.json` change,
run a Trivy scan on the lockfile:

```bash
trivy fs --scanners vuln,secret \
  --severity HIGH,CRITICAL \
  ~/.claude/skills/presentation-skill
```

If Trivy reports HIGH or CRITICAL CVEs, consult
`~/.claude/skills/security-review/SKILL.md` before proceeding.

If Trivy is not yet set up, see `~/.claude/skills/trivy-scan/SKILL.md`.

---

## Step 1 — Install Dependencies

Dependencies are local to this project — they do not install globally.

```bash
cd ~/.claude/skills/presentation-skill

# First time, or after package.json changes
npm ci
```

Verify the install:

```bash
npm run install-check
# Should print: deps ok
```

---

## Step 2 — Run the Intake Questionnaire

**Read `PRESENTATION_STYLE.md` now if you haven't already.**

Work through the intake questionnaire with the user before writing any slide
code. Do not proceed until all required questions are answered:

- Internal or external presentation?
- Audience?
- Single thesis (one sentence)?
- Narrative arc?
- Talk length?
- 3–5 key ideas?
- Visuals already in mind?
- (External only) About Me, legal disclaimer, context-setting content?

Confirm the proposed narrative arc with the user before proceeding to Step 3.

---

## Step 3 — Generate the Deck

### 3a. Configure `src/build_deck.js`

Edit the `CONFIG` block at the top of `src/build_deck.js`:

```javascript
const CONFIG = {
  title:    "<thesis from intake Q3>",
  author:   "Alexandros Bantis",
  fileName: "<topic-date>.pptx",   // e.g. "agentic-systems-2026-04.pptx"
};
```

### 3b. Design principles to follow while writing slide code

These come from `PRESENTATION_STYLE.md` — they are non-negotiable:

- **No sentences on slides.** Titles, short labels, stats, code, and visuals only.
- **One idea per slide.** If you can't decide which visual to use, the slide
  has two ideas — split it.
- **Chapter-break slides are title-only.** Use `addChapterSlide()` from
  `design_system.js`. Sparse by design.
- **Every content slide needs a visual.** Use `addImagePlaceholder()` with a
  detailed image brief if real images aren't available yet.
- **External presentations** must include: About Me slide, legal disclaimer
  slide, 2–4 context-setting slides before the problem statement.
- **Vary layouts.** Don't repeat the same column pattern more than twice in a
  row. Use stat callouts, two-column, full-bleed placeholder, and diagram
  slides to maintain visual rhythm.

### 3c. Build the deck

```bash
cd ~/.claude/skills/presentation-skill
node src/build_deck.js
# Output: output/<filename>.pptx
```

---

## Step 4 — QA Loop

**Assume there are problems. Your job is to find them.**

### 4a. Content check

```bash
cd ~/.claude/skills/presentation-skill
python -m markitdown output/<filename>.pptx
```

Check: correct slide order, no missing titles, no leftover placeholder text,
thesis present in title and conclusion.

### 4b. Visual check — convert to images

```bash
cd ~/.claude/skills/presentation-skill

# Requires LibreOffice and poppler (pdftoppm)
python /mnt/skills/public/pptx/scripts/office/soffice.py \
  --headless --convert-to pdf output/<filename>.pptx

rm -f slide-*.jpg
pdftoppm -jpeg -r 120 output/<filename>.pdf slide

ls -1 "$PWD"/slide-*.jpg
```

Inspect every slide image. Look for:
- Text overflow or cutoff at box boundaries
- Overlapping elements
- Placeholder boxes too close to text
- Inconsistent margins (< 0.5" from edges)
- Low-contrast text or icons
- Accent lines under titles (anti-pattern — remove immediately)

### 4c. Fix and re-verify

After any fix:
1. Re-run `node src/build_deck.js`
2. Re-run the soffice + pdftoppm commands (must regenerate PDF before images
   reflect changes)
3. Re-inspect only the affected slides

Do not declare success until at least one full fix-and-verify cycle completes
with no new issues found.

---

## Step 5 — Deliver

```bash
# The .pptx is in output/ — present it to the user
ls ~/.claude/skills/presentation-skill/output/
```

If the user wants the file uploaded to Google Drive, use the `gws` CLI or the
Google Drive API. That workflow is outside this skill's scope — hand off the
file path.

---

## Dependency Reference

All scoped to `presentation-skill/node_modules/` — never global:

| Package | Purpose |
|---|---|
| `pptxgenjs` | Generates the `.pptx` file |
| `react-icons` | SVG icon library for slide icons |
| `react` + `react-dom` | Peer deps for react-icons rendering |
| `sharp` | Rasterizes SVG icons to PNG for embedding |

System dependencies (not in package.json — must be installed separately):
- `python` + `markitdown` — content QA (`pip install "markitdown[pptx]"`)
- `LibreOffice` — PDF conversion for visual QA
- `poppler` (`pdftoppm`) — PDF to JPEG for slide inspection

---

## Reference

- Design principles: `PRESENTATION_STYLE.md` (this directory)
- pptxgenjs API: https://gitbrent.github.io/PptxGenJS/
- pptxgenjs skill docs: `/mnt/skills/public/pptx/pptxgenjs.md`
- Canonical example deck: https://www.scylladb.com/tech-talk/scaling-up-machine-learning-experimentation-at-tubi-5x-and-beyond/
