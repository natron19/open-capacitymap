# Phase 7 — Polish & Edge Cases

**Goal:** Mobile layout is correct, all edge cases are handled gracefully, no visual regressions, no hardcoded strings remain.

**Prerequisite:** Phases 1–6 complete — full app is functional end to end.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §6 (Bootstrap component choices), §12 (Bootstrap & UI patterns, accent application)
- `docs/security.md` — CSP and header review if anything was added
- `app/views/layouts/application.html.erb` — navbar, flash container, footer
- All views in `app/views/gift_inventories/` and `app/views/project_ideas/`
- `app/views/home/index.html.erb` and `app/views/dashboard/show.html.erb`

---

## Tasks

### 7.1 — Mobile Layout

Verify and fix the responsive card grid. The card wrapper must use `col-lg-4 col-md-6 col-12` so:
- Desktop (lg): 3 cards per row
- Tablet (md): 2 cards per row
- Mobile (sm/xs): 1 card per row

Also check:
- The inventory form chip inputs wrap correctly on small screens (use `d-flex flex-wrap`).
- The show page inventory summary card reads well at mobile width.
- The navbar collapses correctly (Bootstrap `navbar-toggler`).

### 7.2 — Topographic SVG Illustration

In `app/views/home/index.html.erb`, replace the Phase 1 placeholder with either:
- A real inline SVG with muted contour lines and `var(--accent)` colored dots scattered across the surface, OR
- A styled `<div>` with a CSS radial-gradient background if the SVG is impractical to write inline.

The illustration should be subtle — it anchors the right column without distracting from the left column's CTA.

### 7.3 — Dashboard "See all" Link Conditional

In `app/views/dashboard/show.html.erb`, confirm the "See all" link to `project_ideas_path` only renders when `inventory.project_ideas.any?`. Never render it in the empty-state or no-projects state.

### 7.4 — Scoping Audit: Project Show Page 404

Verify that `ProjectIdeasController#show` scopes through `current_user.gift_inventory.project_ideas`. Specifically:

```ruby
@project_idea = current_user.gift_inventory&.project_ideas&.find_by(id: params[:id])
render file: Rails.public_path.join("404.html"), status: :not_found unless @project_idea
```

Test manually: sign in as User B and visit `/project_ideas/{User-A-project-id}` — must return 404.

### 7.5 — Hardcoded String Audit

Search for hardcoded "CapacityMap" or "CapacityMap Demo" in:

```bash
grep -r "CapacityMap" app/views/ app/controllers/ app/mailers/ --include="*.erb" --include="*.rb"
```

Any instance that is app branding (name, tagline, description) must use `ENV.fetch("APP_NAME", "CapacityMap Demo")`. Exceptions allowed:
- Comments (`<%# ... %>`) that explain the pattern.
- The seed file's organization_context sample text (it is sample data, not branding).
- The README (static document, not a rendered view).

### 7.6 — Weekly Hours Range at Boundary Values

Test `weekly_hours` at min (1) and max (40) in the form:
- Confirm the number readout displays the correct value.
- Submit and confirm the stored value is 1 or 40 (not nil or the default).
- Confirm the Gemini prompt variable `{{weekly_hours}}` uses the correct value by checking the `LlmRequest.body` or adding a temporary `Rails.logger.info` call (remove after testing).

### 7.7 — Dark Mode Visual Review

Open the app in the browser and check each new component against dark mode:

- **Project cards** (`project-card` class): `#1a1f0e` background is subtly green-tinted, not pure black.
- **Chip tags** each category has correct background opacity and foreground color in dark mode.
- **First-step alert** (`first-step-alert`): purple left border is visible against card background.
- **Range slider thumb**: accent green.
- **Inline SVG or topographic illustration**: muted on dark background.
- **Flash messages**: Bootstrap alert variants readable in dark mode.
- **`<pre>` raw response block**: `bg-dark` background, `text-muted` text.

### 7.8 — Turbo Stream Check

Confirm no views use `turbo_stream.replace`. Run:

```bash
grep -r "turbo_stream\.replace\|replace(" app/views/ --include="*.erb"
```

All Turbo Stream updates must use `turbo_stream.update`. (This app uses redirect-based flow, so Turbo Streams should only appear in flash message updates if any; confirm nothing was accidentally introduced.)

---

## Manual Tests

- [ ] Resize browser to 375px width (iPhone SE) — confirm all pages are usable without horizontal scroll.
- [ ] Verify the home page renders correctly for a signed-out visitor.
- [ ] Sign in as `viewer@example.com`, try `GET /gift_inventories/{demo-user-uuid}` — confirm 404 (not a redirect or 403).
- [ ] Sign in as `viewer@example.com`, try `GET /project_ideas/{demo-user-project-id}` — confirm 404.
- [ ] Confirm no hardcoded "CapacityMap" branding strings appear in the browser (try setting `APP_NAME=TestApp` in `.env` and restarting — all nav/title references should update).
- [ ] Set `weekly_hours` slider to 1, submit, generate — confirm the prompt variable shows `1 hour per week`.
- [ ] Dark mode visual review — walk through all pages and confirm color-coded chips, cards, and alerts look correct.

---

## Acceptance Criteria

- [ ] Card grid is 3/2/1 columns on lg/md/sm breakpoints.
- [ ] Home page right column has an SVG illustration or styled placeholder (not just a blank column).
- [ ] "See all" link on dashboard only renders when projects exist.
- [ ] `project_ideas#show` and `gift_inventories#show` scope correctly — wrong-user access returns 404.
- [ ] Zero hardcoded app-name or tagline strings in rendered views (all use `ENV.fetch`).
- [ ] Range slider at boundary values produces correct stored values.
- [ ] No `turbo_stream.replace` calls in any view.
- [ ] Dark mode visual review passes — no broken colors or invisible elements.
