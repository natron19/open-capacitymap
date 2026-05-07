# Phase 1 — Branding & Environment

**Goal:** The app looks and feels like CapacityMap Demo before any domain models exist.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §2 (Customizations) and §12 (Bootstrap & CSS)
- `app/views/layouts/application.html.erb` — understand the existing navbar and flash structure
- `app/assets/stylesheets/application.css` — where accent variables live
- `app/views/home/index.html.erb` — the boilerplate landing page to replace
- `app/views/dashboard/show.html.erb` — the boilerplate dashboard to replace

---

## Tasks

### 1.1 — Update `.env.example`

Set the CapacityMap-specific values:

```
APP_NAME="CapacityMap Demo"
APP_TAGLINE="Inventory your gifts. Get a list of meaningful projects where they are needed."
APP_DESCRIPTION="Open source demo of CapacityMap's gift-to-project matching engine. Built on Rails 8 plus Gemini."
```

Leave `GEMINI_API_KEY=your_key_here` and all other existing stubs unchanged.

### 1.2 — Accent Variables and CSS Classes

In `app/assets/stylesheets/application.css`, inside the existing `:root` block, replace the default accent values:

```css
:root {
  --accent: #a3e635;
  --accent-hover: #84cc16;
  --accent-secondary: #a855f7;
  --accent-secondary-hover: #9333ea;
}
```

After the `:root` block, add the CapacityMap-specific CSS classes:

**Chip tags** (color variants per gift category):

```css
.chip-tag {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.2rem 0.6rem;
  border-radius: 9999px;
  font-size: 0.85rem;
  font-weight: 500;
}
.chip-tag .chip-remove {
  cursor: pointer;
  opacity: 0.7;
  margin-left: 0.15rem;
}
.chip-tag .chip-remove:hover { opacity: 1; }
.chip-tag--skill       { background: rgba(163,230,53,0.2);  color: #a3e635; }
.chip-tag--interest    { background: rgba(168,85,247,0.2);  color: #a855f7; }
.chip-tag--connection  { background: rgba(147,51,234,0.2);  color: #9333ea; }
.chip-tag--experience  { background: rgba(108,117,125,0.2); color: #adb5bd; }
```

**Project card**:

```css
.project-card {
  border-radius: 1rem;
  background-color: #1a1f0e;
}
```

**First step alert**:

```css
.first-step-alert {
  border-left: 4px solid var(--accent-secondary);
  background: rgba(168,85,247,0.08);
}
```

### 1.3 — Replace `app/views/home/index.html.erb`

Two-column hero layout (desktop: side by side, mobile: stacked):

- **Left column:** H1 with the `APP_TAGLINE` env var, a 3-line explanation of inverted matching ("Most tools start from tasks. CapacityMap starts from gifts." style), and a primary-accent "Get Started" button linking to `sign_up_path`.
- **Right column:** A placeholder `<div>` with a CSS background or inline SVG stub — topographic style, muted dark background with lime-green dots. Use a `<!-- TODO: replace with topographic SVG -->` comment. This is filled in properly during Phase 7.

Use `ENV.fetch("APP_NAME", "CapacityMap Demo")` and `ENV.fetch("APP_TAGLINE", "")` for all dynamic text. Never hardcode the strings.

The home controller already `skip_before_action :require_authentication` — confirm this is set so the landing page is public.

### 1.4 — Replace `app/views/dashboard/show.html.erb`

Use placeholder conditionals (`if false`) until the domain models exist (wired up in Phase 3):

```erb
<div class="container py-4">
  <div class="row">
    <div class="col">
      <% if false # replaced Phase 3: current_user.gift_inventory.nil? %>
        <%# empty state: no inventory %>
        <div class="text-center py-5">
          <h2>Welcome to <%= ENV.fetch("APP_NAME", "CapacityMap Demo") %></h2>
          <p class="text-muted">Start by creating your gift inventory.</p>
          <%# link_to "Create Your Gift Inventory", new_gift_inventory_path, class: "btn btn-lg", style: "background:var(--accent);color:#000;" %>
        </div>
      <% else %>
        <p class="text-muted">Dashboard placeholder — wired up in Phase 3.</p>
      <% end %>
    </div>
  </div>
</div>
```

### 1.5 — Navbar Links (commented out)

In `app/views/layouts/application.html.erb`, in the authenticated nav section (visible when `current_user` is present), add the two new links as comments with a `TODO Phase 3` marker so they're easy to find and uncomment:

```erb
<%# TODO Phase 3: uncomment when routes exist %>
<%#= link_to "My Inventory", current_gift_inventories_path, class: "nav-link" %>
<%#= link_to "Generated Projects", project_ideas_path, class: "nav-link" %>
```

---

## Manual Tests

- [ ] Start `bin/dev` and visit `/` — confirm hero renders with lime-green accent button, tagline comes from env var, "Get Started" links to sign-up page.
- [ ] Sign in as `demo@example.com` / `password123` and visit `/dashboard` — confirm placeholder renders without errors.
- [ ] Visit `/admin` as demo admin — confirm admin panel still works unchanged.
- [ ] Confirm the page `<title>` and footer text use `ENV.fetch("APP_NAME")`, not hardcoded text.
- [ ] Inspect the page source — confirm `--accent: #a3e635` is in the stylesheet and `.chip-tag` classes are present.

---

## Acceptance Criteria

- [ ] `.env.example` has all three CapacityMap values with no real secrets.
- [ ] `:root` in `application.css` has the four accent variables and all chip/card/alert CSS classes.
- [ ] Home page renders the two-column hero with the correct tagline from env.
- [ ] Dashboard page renders without errors in the placeholder state.
- [ ] Navbar has the two commented-out links with `TODO Phase 3` markers.
- [ ] No hardcoded "CapacityMap Demo" strings in views (only `ENV.fetch` calls).
