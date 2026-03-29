---
name: article
version: 0.3.0
description: |
  Article writing workflow with cover image generation. Specs the article,
  writes a draft, formats for the target platform (LinkedIn, blog, etc.),
  generates a DALL-E cover image, and presents everything together.
  Use when asked to "/article", "write an article", or "draft a post".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

# /article — Article Writer with Cover Image

## Subcommand Detection

Parse the user's input:
- `/article` with no arguments → Ask what they want to write about
- `/article <topic>` → Start the workflow with the given topic
- `/article image` → Generate a cover image for an existing article in the current project

---

## Step 0: Check Existing State

Articles live inside the current project under `articles/`. This keeps articles co-located with the code they describe.

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ls "$PROJECT_ROOT/articles/"*/spec.md 2>/dev/null   # existing articles
```

If the user is continuing an existing article, skip to the relevant step.

## Step 1: Scaffold the Article Folder

Derive a `<slug>` from the topic (lowercase, hyphens, no special chars).

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$PROJECT_ROOT/articles/<slug>/cover" "$PROJECT_ROOT/articles/<slug>/assets" "$PROJECT_ROOT/articles/<slug>/platform"
touch "$PROJECT_ROOT/articles/<slug>/cover/.gitkeep" "$PROJECT_ROOT/articles/<slug>/assets/.gitkeep"
```

This creates:
```
articles/<slug>/
├── spec.md             # article spec (created in Step 2)
├── article.txt         # plain text draft (created in Step 3)
├── cover/              # generated cover images
│   └── .gitkeep
├── assets/             # screenshots, diagrams, embeds
│   └── .gitkeep
└── platform/           # formatted outputs per platform
    └── linkedin.md     # markdown version (created in Step 5)
```

Announce:
```
[ARTICLE] Scaffolded: <slug>/
```

## Step 2: Spec the Article

Ask the user (or infer from their prompt) these essentials:
- **Topic**: What is this about?
- **Platform**: LinkedIn post, blog article, newsletter, etc.
- **Audience**: Who reads this?
- **Key message**: What's the one takeaway?

Create the spec and save it to `<slug>/spec.md`:

```markdown
# Article Spec

- **Topic**: <topic>
- **Platform**: <platform>
- **Audience**: <audience>
- **Key message**: <one sentence>
- **Tone**: <inferred from user's style>
- **Length**: <appropriate for platform>

## Outline
1. <section 1>
2. <section 2>
3. ...

## Image Direction
- Core visual metaphor: <what image should convey>
- Style: flat, minimal, professional
- Palette: <muted colors with one accent>
```

Show the spec to the user. Wait for approval before writing.

## Step 3: Write the Draft

Write the article following the spec. Save to `<slug>/article.txt`.

The draft is always **plain text** — no markdown formatting. This is the paste-ready source for LinkedIn and similar platforms.

### Plain Text Rules (all platforms)
- No `#`, `**`, `---`, numbered lists, or code blocks
- Use `⸻` for section dividers
- Use `→` for bullet-like emphasis
- Keep paragraphs short (2-3 sentences max)

### LinkedIn-specific
- Hook in the first 2 lines (LinkedIn truncates after ~210 characters)
- 800-1500 words for articles, 200-400 for posts
- End with a clear takeaway, not a CTA that feels salesy

### Blog-specific
- Same plain text draft, but the platform export (Step 5) adds markdown formatting
- 1000-2500 words

### Newsletter
- Conversational tone
- 500-1200 words

## Step 4: Generate Cover Image

After the draft is approved, generate a cover image.

### 4a: Build the DALL-E Prompt

Use the **Image Direction** from the spec as a starting point. Extract 3-5 key themes from the article. Build a prompt that:
- Captures the article's core metaphor or concept visually
- Uses a clean, professional style suitable for the platform
- Specifies: flat/minimal illustration, muted professional colors, no text in image
- Requests 16:9 aspect ratio for LinkedIn headers
- Avoids: photorealism (looks stock-y), busy compositions, text overlays

Template:
```
A minimal, clean illustration of [core visual metaphor from article].
[Key visual elements that represent the themes].
Style: flat, modern, professional. Colors: [muted palette with one accent color].
No text. Clean background suitable for a [platform] header. 16:9 aspect ratio.
```

### 4b: Generate the Image

```bash
~/dev/tinyaiteam/scripts/tat-image.sh "<prompt>" "<slug>/cover/cover.png"
```

If the script is not found, try the installed location:
```bash
~/.tinyaiteam/scripts/tat-image.sh "<prompt>" "<slug>/cover/cover.png"
```

### 4c: Present the Result

Show the user:
1. The generated image (use Read tool on the image file)
2. The DALL-E prompt used
3. Offer to regenerate with a different prompt if they don't like it

## Step 5: Platform Export

After draft and image are approved, generate platform-formatted outputs in `<slug>/platform/`:

### LinkedIn → `<slug>/platform/linkedin.md`
- Convert the plain text draft into well-formatted markdown
- Add YAML frontmatter: title, date, description, tags, cover image path
- Use proper markdown headers for sections (replace `⸻` dividers)
- Use markdown lists for `→` bullet items
- Reference cover image: `![cover](../cover/cover.png)`
- This is the archival/readable version — the article.txt is what gets pasted into LinkedIn

### Blog → `<slug>/platform/blog.md`
- Full markdown with proper headers, code blocks, lists
- Add frontmatter (title, date, description, cover image path)
- Reference cover image: `![cover](../cover/cover.png)`

Generate only the formats relevant to the spec's platform. If multiple platforms, generate all.

## Step 6: Final Output

Present the complete package:
```
[ARTICLE] Project:  <slug>/
[ARTICLE] Spec:     <slug>/spec.md
[ARTICLE] Draft:    <slug>/article.txt
[ARTICLE] Cover:    <slug>/cover/cover.png
[ARTICLE] Platform: <slug>/platform/<format>
[ARTICLE] Words:    <N>
[ARTICLE] Ready to publish.
```

---

## Article Planning Tasks

When running inside a TAT session, add these tasks to `plan.md` for each new article:

```markdown
## Article: <title>
- [ ] Brainstorm & research (angles, references, hooks)
- [ ] Write spec (audience, key message, outline, image direction)
- [ ] Write draft (hook → body → takeaway)
- [ ] GPT review
- [ ] Revise based on review
- [ ] Generate cover image
- [ ] Platform export + final review
```

Mark each task `[x]` as it completes, `[~]` when in progress. This gives visibility into where each article stands without being bureaucratic.

---

## Integration with TAT

When running inside a TAT session (`/tat` is active):
- Follow the SSD loop — spec counts as the "Spec" phase
- The draft is the "Do" phase
- GPT review still applies if TAT is active
- Image generation happens after GPT review passes
- Tag guidance with `[ARTICLE]` source tag
- Add article tasks to plan.md (see Article Planning Tasks above)

When running standalone (no `/tat`):
- Skip SSD loop, GPT review, and branching
- Just scaffold → spec → write → image → export → done

---

## Important Rules

1. **Always scaffold first.** Every article gets its own folder with the full structure.
2. **Always spec first.** Never write without knowing platform, audience, and key message.
3. **Draft is always plain text.** `article.txt` is paste-ready. Markdown goes in `platform/`.
4. **Platform formatting matters.** LinkedIn plain text is NOT markdown. Get this right.
5. **Image prompt quality matters.** Spend time on the DALL-E prompt — a bad prompt wastes an API call.
6. **User approves at each step.** Spec → draft → image → export. Don't rush through.
7. **No stock photo vibes.** Illustrations over photorealism. Minimal over busy.
8. **Spec includes image direction.** Plan the visual alongside the writing, not as an afterthought.
