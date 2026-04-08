"use strict";
// build_deck.js — presentation generator
// Claude Code populates this file based on the intake questionnaire answers
// and the design principles in PRESENTATION_STYLE.md.
//
// Usage:
//   node src/build_deck.js
//
// Output:
//   output/<filename>.pptx

const path   = require("path");
const fs     = require("fs");
const pptxgen = require("pptxgenjs");

const {
  PALETTE, FONTS, SIZE, makeShadow,
  addChapterSlide, addContentSlide, addImagePlaceholder, addStatCallout,
} = require("./design_system");

// ── Configuration ─────────────────────────────────────────────────────────────
// Claude Code fills these in based on intake questionnaire answers.
const CONFIG = {
  title:    "Presentation Title",   // ← set from intake Q3 (thesis)
  author:   "Alexandros Bantis",
  fileName: "presentation.pptx",   // ← set from topic / date
};

// ── Main ──────────────────────────────────────────────────────────────────────
async function buildDeck() {
  const pres = new pptxgen();
  pres.layout  = "LAYOUT_16x9";
  pres.title   = CONFIG.title;
  pres.author  = CONFIG.author;

  // ── SLIDES GO HERE ──────────────────────────────────────────────────────────
  // Claude Code generates slide code here based on the agreed narrative arc.
  // Each slide follows the design principles in PRESENTATION_STYLE.md:
  //   - Slides are backdrops, not documents
  //   - No sentences on slides — visuals only
  //   - One idea per slide
  //   - Chapter-break slides are title-only signposts
  //
  // Example title slide:
  {
    const slide = pres.addSlide();
    slide.background = { color: PALETTE.primary };
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0, y: 0, w: 0.18, h: 5.625,
      fill: { color: PALETTE.accent }, line: { color: PALETTE.accent }
    });
    slide.addText(CONFIG.title, {
      x: 0.5, y: 1.8, w: 9, h: 1.4,
      fontFace: FONTS.title, fontSize: 44, bold: true,
      color: PALETTE.white, align: "center", margin: 0
    });
    slide.addText(CONFIG.author, {
      x: 0.5, y: 4.8, w: 9, h: 0.5,
      fontFace: FONTS.body, fontSize: 16,
      color: PALETTE.accentLight, align: "center", margin: 0
    });
  }

  // ── OUTPUT ──────────────────────────────────────────────────────────────────
  const outputDir = path.join(__dirname, "..", "output");
  fs.mkdirSync(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, CONFIG.fileName);

  await pres.writeFile({ fileName: outputPath });
  console.log(`✅ Written: ${outputPath}`);
}

buildDeck().catch(err => {
  console.error("❌ Build failed:", err.message);
  process.exit(1);
});
