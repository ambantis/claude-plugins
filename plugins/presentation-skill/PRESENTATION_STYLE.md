# Presentation Style Guide

---

## Core Philosophy

**Slides are a backdrop, not a document.**

The audience's attention is a zero-sum resource. Text on a slide competes directly with the speaker's voice — and text always wins. While the audience reads, they stop listening. Therefore:

> If it's a sentence, it shouldn't be on the slide.
> If it's on the slide, it should be a visual.

Slides carry **anchors**. The speaker's voice carries **the argument**. A reader who only sees the slides should get labels and cues. A listener who only hears the speaker should get the full idea. That asymmetry is intentional and correct.

---

## What Belongs on a Slide

**Allowed:**
- A title — one line, names the topic so the audience knows where they are
- A short label or stat that can't be conveyed visually (e.g. "p99: 3ms", "20M+ MAU")
- Code — because code cannot be spoken
- A visual: photo, diagram, architecture drawing, chart, cultural reference image

**Not allowed:**
- Sentences or paragraphs of prose
- Bullet points that summarize what the speaker is about to say
- Anything the speaker intends to read aloud

---

## Narrative Structure

Every presentation should have a clear arc, announced with explicit chapter-break slides:

1. **Context / Problem** — what is the world, and what is broken or hard?
2. **Solution** — what did we do about it?
3. **How it works** — the technical or conceptual substance
4. **Lessons / Takeaways** — what should the audience walk away knowing?
5. **Conclusion** — restate the thesis; end with the same energy you opened with

Chapter-break slides are intentionally sparse — title only, or title + one image. They are signposts, not content slides.

**Thesis rule:** Know the single memorable thesis before building the deck. Every slide should be traceable back to it. State it early, earn it through the middle, restate it at the end.

---

## Visuals

Every content slide should have a visual element. If no visual comes to mind, that is a signal the slide may not need to exist, or that two ideas are being conflated into one.

Good visual choices:
- A photo or cultural reference that makes the idea emotionally sticky (e.g. a police lineup for "the usual suspects")
- An architecture or flow diagram
- A single large stat or number (60pt+) that anchors a claim
- A before/after comparison
- A data chart (kept clean — one insight per chart)

Avoid decorative visuals that don't reinforce the spoken argument.

---

## Pacing and Idea Density

- One idea per slide. If a slide is trying to make two points, split it.
- The cost of a slide is not production time — it is **idea density from the audience's perspective**. Administrative slides (legal disclaimer, agenda) are free because they carry no cognitive load.
- Aim for roughly one slide per minute of speaking time as a starting heuristic, but let the idea count drive slide count, not the clock.

---

## Internal vs. External Presentations

### Internal Presentations
- Audience shares domain context — skip company/product background
- Can go deeper faster on technical substance
- No "About Me" slide needed unless presenting to a new audience
- No legal disclaimer required

### External Presentations
Must include, in order near the top of the deck:

1. **About Me slide** — current role and company, 1–2 sentences of relevant background, one personal touch (optional but humanizing)
2. **Legal disclaimer slide** — standalone slide with the text:
   *"The views expressed here are my own and do not represent those of my current employer."*
3. **Context-setting section** — the audience does not know your employer's domain. Spend 2–4 slides establishing:
   - What the company/product does
   - The scale or constraints that make the problem interesting
   - Why this problem is hard (before introducing the solution)

---

## Intake Questionnaire

Before building any deck, ask the presenter the following questions. Do not proceed to slide creation until these are answered.

### Always ask:

1. **Do you have a company template deck?**
   _(If yes, ask for the file path. This will be used to derive the color palette, fonts, and layout conventions. If no, the default design system is used.)_

2. **Internal or external presentation?**
   _(Determines whether About Me, legal disclaimer, and context-setting slides are needed)_

3. **Who is the audience?**
   _(Engineering peers, technical leadership, business stakeholders, conference attendees, mixed?)_

4. **What is the single thesis — the one thing the audience should remember?**
   _(If the presenter can't state this in one sentence, the deck isn't ready to be built)_

5. **What is the narrative arc?**
   _(Problem/solution? Before/after? Lessons learned? Product pitch? Walk through options if needed)_

6. **How long is the talk?**
   _(Sets the expected slide count and depth of each section)_

7. **What are the 3–5 key ideas or moments in the talk?**
   _(These become the content slides; everything else is context or transition)_

8. **Are there any visuals, diagrams, screenshots, or cultural references you already have in mind?**
   _(Gather these before generating slides)_

### For external presentations, also ask:

9. **What does the audience need to know about your company/product before the problem makes sense?**
   _(2–3 sentences max; this becomes the context-setting section)_

10. **What is your current role and relevant background for the About Me slide?**

11. **Any personal detail you'd like on the About Me slide?**
    _(Optional — but humanizing touches land well with external audiences)_

---

## Anti-Patterns to Avoid

- **Bullet point prose** — if it's a sentence, it's not a slide element
- **Reading the slide** — if the speaker is reading text off the slide, the slide has failed
- **Dense text blocks** — the audience will read them and stop listening
- **Decoration without argument** — images that don't reinforce the spoken point
- **Too many ideas per slide** — split ruthlessly
- **Self-contained slides** — a slide that makes complete sense without the speaker undermines the talk
- **Accent lines under titles** — a hallmark of generic AI-generated slides; use whitespace instead

---

## Reference Deck

The canonical example of these principles in practice:
**"Scaling Up ML Experimentation at Tubi 5x and Beyond"**
ScyllaDB Summit 2019 — Alexandros Bantis
https://www.scylladb.com/tech-talk/scaling-up-machine-learning-experimentation-at-tubi-5x-and-beyond/

Key observations from that deck:
- Slides carry labels; the talk carries the argument
- Every content slide pairs a title with a single image
- "People Problem" slide has two images and zero body text — the story lived entirely in the spoken word
- Chapter-break slides ("The Mission", "The Problem", "The Solution") are title-only signposts
- Cultural reference images (Usual Suspects, Erlang/WhatsApp) make abstract concepts sticky
