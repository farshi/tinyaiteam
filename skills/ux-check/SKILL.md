# /ux-check — UX Design Alignment Checker

Compares a live web application against its design spec (DESIGN.md). Instead of manually describing how the UI looks, this skill navigates the app, extracts actual CSS values and page structure, and reports misalignments against the spec.

**Requires:** gstack browse binary (`~/.claude/skills/gstack/browse/dist/browse`)

## When to Use

- After implementing UI changes — verify they match the design spec
- During REVIEW checkpoint — automated UX verification before shipping
- After `/design-consultation` creates a DESIGN.md — verify implementation matches
- When onboarding to an existing project — audit current state against spec

## Subcommand Detection

Parse the user's input:
- `/ux-check <url>` → Full check against DESIGN.md at the given URL
- `/ux-check <url> --page <path>` → Check a single page (e.g., `/dashboard`)
- `/ux-check --init` → Create a DESIGN.md template for the project
- `/ux-check --diff` → Only check pages affected by current branch changes

---

## Step 0: Setup

### Find browse binary
```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.claude/skills/gstack/browse/dist/browse"
[ -z "$B" ] && B=~/.claude/skills/gstack/browse/dist/browse
if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

If `NEEDS_SETUP`:
```
[UX] Browse binary not found. Install gstack first, or run setup:
  cd ~/.claude/skills/gstack/browse && ./setup
```
Stop here until browse is available.

### Find design spec
```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DESIGN_FILE=""
for f in "$PROJECT_ROOT/DESIGN.md" "$PROJECT_ROOT/docs/DESIGN.md" "$PROJECT_ROOT/.tat/design.md"; do
  [ -f "$f" ] && DESIGN_FILE="$f" && break
done
echo "${DESIGN_FILE:-NO_DESIGN}"
```

If `NO_DESIGN` and not `--init`:
```
[UX] No DESIGN.md found. Options:
  1. Run /ux-check --init to create a template
  2. Run /design-consultation to create a full design system
  3. Create DESIGN.md manually
```
Stop here.

---

## Init Flow (`--init`)

Create a DESIGN.md template at the project root:

```markdown
# Design Spec — <Project Name>

## Design Tokens

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| primary | #0f766e | Main actions, links, active states |
| primary-light | #14b8a6 | Hover states, secondary accents |
| background | #f8fafb | Page background |
| surface | #ffffff | Cards, modals, panels |
| text | #1e293b | Body text |
| text-muted | #94a3b8 | Secondary text, placeholders |
| border | #e2e8f0 | Borders, dividers |
| success | #16a34a | Success states, available |
| danger | #dc2626 | Errors, destructive actions |
| warning | #d97706 | Warnings, pending states |

### Typography
| Element | Font | Size | Weight | Line Height |
|---------|------|------|--------|-------------|
| body | system-ui, -apple-system, sans-serif | 16px | 400 | 1.5 |
| h1 | system-ui | 28px | 700 | 1.2 |
| h2 | system-ui | 22px | 600 | 1.3 |
| button | system-ui | 14px | 500 | 1 |
| input | system-ui | 14px | 400 | 1.5 |

### Spacing
| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight gaps |
| sm | 8px | Input padding, small gaps |
| md | 16px | Card padding, section gaps |
| lg | 24px | Page margins, large gaps |
| xl | 32px | Section separators |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| sm | 4px | Badges, tags |
| md | 8px | Inputs, cards |
| lg | 12px | Modals, panels |
| pill | 9999px | Buttons, pills |

## Pages

### / (Home / Landing)
- **Layout:** Centered container, max-width 640px
- **Header:** Logo + app name, primary color
- **Key elements:**
  - Welcome message (h1, centered)
  - Primary CTA button (primary bg, white text, pill radius)

### /dashboard
- **Layout:** Centered container, max-width 960px
- **Header:** Sticky, app name + logout button
- **Key elements:**
  - Tab navigation (active tab uses primary color)
  - Content cards (surface bg, md radius, border)
  - Status badges (color-coded: success/danger/warning)

<!-- Add more pages as needed -->
```

After creating the template:
```
[UX] DESIGN.md created at <path>. Fill in your design tokens and pages, then run:
  /ux-check <url>
```

---

## Step 1: Parse Design Spec

Read DESIGN.md and extract into structured sections:

1. **Design Tokens** — Parse all tables under `## Design Tokens`:
   - Colors: token → hex value mapping
   - Typography: element → font/size/weight mapping
   - Spacing: token → pixel value mapping
   - Border radius: token → value mapping

2. **Pages** — Parse each `### <path>` under `## Pages`:
   - Layout constraints (max-width, centering)
   - Key elements with expected styles
   - Component descriptions

Print summary:
```
[UX] Design spec loaded:
  Colors: 10 tokens
  Typography: 5 rules
  Spacing: 5 tokens
  Pages: 3 defined (/, /dashboard, /chat)
```

---

## Step 2: Navigate and Extract

For each page defined in the spec (or the single `--page` if specified):

### 2a. Navigate
```bash
$B goto <base-url><page-path>
```

Wait for page to load. Check for errors:
```bash
$B console
```
Flag any console errors as warnings.

### 2b. Take baseline screenshot
```bash
$B screenshot /tmp/ux-check-<page-name>.png
```

### 2c. Extract page structure
```bash
$B snapshot -i -c
```
This gives the interactive element tree — buttons, links, inputs, navigation.

### 2d. Extract CSS values for key elements

For each key element defined in the spec's page section, find the matching element and extract its styles:

```bash
# Example: check header background color
$B css "header" "background-color"
$B css "header" "max-width"

# Example: check button styles
$B css "button.primary" "background-color"
$B css "button.primary" "border-radius"
$B css "button.primary" "font-size"
$B css "button.primary" "font-weight"

# Example: check body typography
$B css "body" "font-family"
$B css "body" "font-size"
$B css "body" "color"
```

### 2e. Check responsive behavior
```bash
$B responsive /tmp/ux-check-<page-name>
```
This captures mobile (375px), tablet (768px), and desktop (1280px) screenshots.

---

## Step 3: Compare Against Spec

For each extracted value, compare against the spec:

### Color comparison
- Convert both to same format (hex or rgb) before comparing
- Allow tolerance for rgb rounding (e.g., `rgb(15, 118, 110)` matches `#0f766e`)
- Flag mismatches:
  ```
  [UX] MISMATCH: Header background
    Expected: #0f766e (primary)
    Actual:   #3b82f6
    Element:  header
    Page:     /dashboard
  ```

### Typography comparison
- Check font-family (first font in stack matches)
- Check font-size (exact match expected)
- Check font-weight (exact match expected)
- Flag mismatches with same format

### Layout comparison
- Check max-width values
- Check if centering is applied (margin: auto or flexbox centering)
- Note: layout checks are advisory, not pixel-perfect

### Missing elements
- If a spec-defined element isn't found on the page:
  ```
  [UX] MISSING: Primary CTA button
    Expected: button with primary bg, pill radius
    Page:     /
    Selector tried: button.primary, button[type="submit"], .cta
  ```

---

## Step 4: Generate Report

```
[UX] ============ UX Alignment Report ============
[UX] App: <url>
[UX] Spec: <DESIGN.md path>
[UX] Date: <today>
[UX] Pages checked: 3
================================================

Page: / (Home)
  Screenshot: /tmp/ux-check-home.png
  [PASS] Body font-family: system-ui
  [PASS] Body color: #1e293b
  [FAIL] Header bg: expected #0f766e, got #3b82f6
  [PASS] CTA button radius: pill (9999px)
  [WARN] Console error: "Failed to load resource: /favicon.ico"

Page: /dashboard
  Screenshot: /tmp/ux-check-dashboard.png
  [PASS] Max-width: 960px
  [PASS] Tab active color: #0f766e
  [FAIL] Card border-radius: expected 8px, got 4px
  [MISS] Status badges not found (tried: .badge, .status, [data-status])

Page: /chat
  Screenshot: /tmp/ux-check-chat.png
  [PASS] Max-width: 640px
  [PASS] Message bubble radius: 12px
  [PASS] Input area height: auto-resize

================================================
[UX] Summary: 8 PASS, 2 FAIL, 1 MISSING, 1 WARN
[UX] Alignment score: 73%
================================================
```

### Score calculation
- Each check is 1 point
- PASS = 1.0, WARN = 0.5, FAIL = 0.0, MISSING = 0.0
- Score = (total points / total checks) * 100

---

## Step 5: Offer Fixes

If mismatches are found:

```
[UX] Found 2 misalignments and 1 missing element.
[UX] Options:
  1. Fix in source code (I'll update CSS/HTML to match the spec)
  2. Update the spec (the current UI is intentional, update DESIGN.md)
  3. Skip (acknowledge and move on)
```

If user chooses "Fix in source code":
1. Identify the source file containing the mismatched styles
2. Update the CSS/HTML values to match DESIGN.md tokens
3. Commit each fix atomically: `fix(ux): align <element> <property> with design spec`
4. Re-run the check on the fixed page to verify
5. Show before/after screenshots

If user chooses "Update the spec":
1. Update DESIGN.md with the actual values
2. Commit: `docs(design): update <token> to match implementation`

---

## Integration with TAT

### During REVIEW checkpoint
Add optional UX check after self-review:
```
[TAT] ▶ REVIEW checkpoint:
  ...
  [ ] 4b. (optional) Run /ux-check if UI was modified
  ...
```

### During SHIP checkpoint
If the PR modifies UI files (HTML, CSS, .tsx, .vue, etc.), suggest:
```
[TAT] UI files changed. Run /ux-check before shipping? (recommended)
```

---

## Diff Mode (`--diff`)

When `--diff` is specified, only check pages affected by the current branch:

1. Get changed files:
   ```bash
   git diff main --name-only | grep -E '\.(html|css|tsx|jsx|vue|svelte|ts|js)$'
   ```

2. Map changed files to pages defined in DESIGN.md (by matching component names or route paths)

3. Only run checks on affected pages

This makes the check fast enough for every PR.

---

## Important Rules

1. **DESIGN.md is the source of truth.** If the spec says primary is `#0f766e`, that's what we check for.
2. **Token-level, not pixel-perfect.** We compare design tokens (colors, sizes, weights), not pixel screenshots.
3. **Advisory, not blocking.** Mismatches are reported, not gated. User decides what to fix.
4. **Accessibility tree for structure, CSS for values.** Use both sensing layers.
5. **Screenshots are evidence.** Always capture screenshots alongside programmatic checks for human review.
