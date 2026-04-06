"use strict";
// design_system.js — shared design constants and helpers
// All build_deck.js files import from here for consistency.

// ── Palette ───────────────────────────────────────────────────────────────────
// These are defaults. build_deck.js may override for topic-specific palettes.
// Never use # prefix — pptxgenjs will corrupt the file.
const PALETTE = {
  // Default: navy/teal (professional, technical)
  primary:     "1A2B4A",   // deep navy
  accent:      "0D9488",   // teal
  accentLight: "14B8A6",   // lighter teal
  accentMint:  "CCFBF1",   // mint (callout backgrounds)
  white:       "FFFFFF",
  offWhite:    "F8FAFC",
  slate:       "475569",
  slateLight:  "94A3B8",
  charcoal:    "1E293B",
  red:         "EF4444",   // for warnings / problems
  green:       "22C55E",   // for solutions / success
  amber:       "F59E0B",   // for caution / highlights
};

// ── Typography ────────────────────────────────────────────────────────────────
const FONTS = {
  title: "Trebuchet MS",
  body:  "Calibri",
};

// ── Font sizes ────────────────────────────────────────────────────────────────
const SIZE = {
  slideTitle:    36,
  chapterTitle:  40,
  sectionHeader: 22,
  body:          15,
  caption:       11,
  stat:          52,
};

// ── Shadow factory ────────────────────────────────────────────────────────────
// Always use a factory — pptxgenjs mutates shadow objects in place.
const makeShadow = () => ({
  type: "outer", blur: 8, offset: 3, angle: 135,
  color: "000000", opacity: 0.18
});

// ── Slide helpers ─────────────────────────────────────────────────────────────

/**
 * Add a dark chapter-break slide (title only, or title + subtitle).
 * Used as section signposts — sparse by design.
 */
function addChapterSlide(pres, title, subtitle = null) {
  const slide = pres.addSlide();
  slide.background = { color: PALETTE.primary };

  // Left accent bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.18, h: 5.625,
    fill: { color: PALETTE.accent }, line: { color: PALETTE.accent }
  });

  slide.addText(title, {
    x: 0.5, y: subtitle ? 1.8 : 2.2, w: 9, h: 1.2,
    fontFace: FONTS.title, fontSize: SIZE.chapterTitle, bold: true,
    color: PALETTE.white, align: "center", margin: 0
  });

  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.5, y: 3.2, w: 9, h: 0.6,
      fontFace: FONTS.body, fontSize: SIZE.body + 5,
      color: PALETTE.accentLight, align: "center", italic: true, margin: 0
    });
  }

  return slide;
}

/**
 * Add a light content slide with title + divider.
 * This is the standard workhorse layout.
 */
function addContentSlide(pres, title) {
  const slide = pres.addSlide();
  slide.background = { color: PALETTE.offWhite };

  // Top accent bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.08,
    fill: { color: PALETTE.accent }, line: { color: PALETTE.accent }
  });

  // Title
  slide.addText(title, {
    x: 0.5, y: 0.18, w: 9, h: 0.72,
    fontFace: FONTS.title, fontSize: SIZE.slideTitle, bold: true,
    color: PALETTE.primary, align: "left", margin: 0
  });

  // Divider
  slide.addShape(pres.shapes.LINE, {
    x: 0.5, y: 0.95, w: 9, h: 0,
    line: { color: PALETTE.slateLight, width: 0.75 }
  });

  return slide;
}

/**
 * Add an image placeholder box with a detailed brief for the image-gen agent.
 * Replace with slide.addImage() once real images are generated.
 */
function addImagePlaceholder(slide, pres, x, y, w, h, brief) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w, h,
    fill: { color: "E2E8F0" },
    line: { color: PALETTE.slateLight, width: 1, dashType: "dash" },
    shadow: makeShadow()
  });
  slide.addText([
    { text: "📷  IMAGE PLACEHOLDER\n", options: { bold: true, color: PALETTE.slate } },
    { text: brief,                      options: { color: PALETTE.slate, fontSize: SIZE.caption } }
  ], {
    x, y, w, h,
    fontFace: FONTS.body, fontSize: SIZE.caption + 2,
    align: "center", valign: "middle", margin: 12
  });
}

/**
 * Add a large stat callout card.
 */
function addStatCallout(slide, pres, x, y, w, h, stat, label) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w, h,
    fill: { color: PALETTE.primary }, line: { color: PALETTE.primary },
    shadow: makeShadow()
  });
  slide.addText(stat, {
    x, y: y + 0.1, w, h: h * 0.55,
    fontFace: FONTS.title, fontSize: SIZE.stat, bold: true,
    color: PALETTE.accentLight, align: "center", valign: "bottom", margin: 0
  });
  slide.addText(label, {
    x, y: y + h * 0.6, w, h: h * 0.35,
    fontFace: FONTS.body, fontSize: SIZE.caption + 2,
    color: PALETTE.white, align: "center", valign: "top", margin: 0
  });
}

module.exports = {
  PALETTE, FONTS, SIZE, makeShadow,
  addChapterSlide, addContentSlide, addImagePlaceholder, addStatCallout,
};
