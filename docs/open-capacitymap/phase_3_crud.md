# Phase 3 — Routes, Controllers & Views (CRUD, no AI)

**Goal:** A user can create, view, and edit their gift inventory. Project ideas are listable and showable. No AI generation yet.

**Prerequisite:** Phase 2 complete — models and migrations are in place.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §4 (Routes), §5 (Controllers), §6 (Views — inventory form, show page, project list/show, dashboard)
- `docs/turbo-stimulus-patterns.md` — Turbo Frame conventions, form patterns
- `docs/testing.md` — request spec conventions, auth helper, access control patterns
- `app/controllers/application_controller.rb` — `require_authentication`, `current_user`
- `config/routes.rb` — add the new routes here

---

## Tasks

### 3.1 — Routes (`config/routes.rb`)

Add inside `Rails.application.routes.draw`:

```ruby
resources :gift_inventories, only: [:new, :create, :show, :edit, :update] do
  get  :current,  on: :collection
  post :generate, on: :member
end
resources :project_ideas, only: [:index, :show]
```

### 3.2 — `app/controllers/gift_inventories_controller.rb`

Implement actions: `current`, `new`, `create`, `show`, `edit`, `update`. Stub `generate` to raise `NotImplementedError` (implemented in Phase 5).

Key rules:
- All actions scope through `current_user`. The user can only access their own inventory.
- `current` — if `current_user.gift_inventory` exists, redirect to `gift_inventory_path(current_user.gift_inventory)`; otherwise redirect to `new_gift_inventory_path`.
- `show` — load `@inventory = current_user.gift_inventory`; 404 if nil or if `params[:id]` doesn't match. Load `@project_ideas = @inventory.project_ideas.ordered`.
- `create` — on success redirect to `gift_inventory_path(@inventory)`; on failure re-render `new` with status 422.
- `update` — on success redirect to `gift_inventory_path(@inventory)`; on failure re-render `edit` with status 422.
- Strong params accept: `skills`, `interests`, `weekly_hours`, `connections`, `experience_areas`, `organization_context`. The array fields arrive as JSON strings from the hidden field; the model's setter handles parsing.

```ruby
private

def inventory_params
  params.require(:gift_inventory).permit(
    :skills, :interests, :weekly_hours, :connections,
    :experience_areas, :organization_context
  )
end

def set_inventory
  @inventory = current_user.gift_inventory
  render file: Rails.public_path.join("404.html"), status: :not_found unless @inventory&.id.to_s == params[:id]
end
```

### 3.3 — `app/controllers/project_ideas_controller.rb`

```ruby
class ProjectIdeasController < ApplicationController
  before_action :set_project_idea, only: [:show]

  def index
    inventory = current_user.gift_inventory
    @project_ideas = inventory ? inventory.project_ideas.ordered : ProjectIdea.none
  end

  def show; end

  private

  def set_project_idea
    inventory = current_user.gift_inventory
    @project_idea = inventory&.project_ideas&.find_by(id: params[:id])
    render file: Rails.public_path.join("404.html"), status: :not_found unless @project_idea
  end
end
```

### 3.4 — `app/views/gift_inventories/_form.html.erb`

Render all six fields using plain Bootstrap inputs. Chip-tag interactivity is added in Phase 4. For now:
- Use a `<textarea>` for each array field (one item per line) with a `name` that maps to the JSON param. Include a hidden field set to the JSON-encoded current value so the controller always receives JSON.
- Use `number_field` for `weekly_hours`.
- Mark each field's wrapping div with an `id` for easy Phase 4 targeting.
- Include a Bootstrap `form-text` note below each array field: "One item per line. Chip input coming in next phase."

```erb
<%= form_with model: gift_inventory, local: false do |f| %>
  <%# skills field — Phase 4 replaces this with chip-tags controller %>
  <div class="mb-3" id="skills-field-wrapper">
    <%= f.label :skills, "Skills you enjoy using" %>
    <textarea class="form-control" rows="4" placeholder="One skill per line...">
      <%= gift_inventory.skills_list.join("\n") %>
    </textarea>
    <%= f.hidden_field :skills %>
    <div class="form-text">5 to 8 skills. One per line.</div>
  </div>
  ... (repeat for interests, connections, experience_areas)

  <div class="mb-3">
    <%= f.label :weekly_hours, "Hours per week" %>
    <%= f.number_field :weekly_hours, class: "form-control", min: 1, max: 80 %>
  </div>

  <div class="mb-3">
    <%= f.label :organization_context, "Your organization or community" %>
    <%= f.text_area :organization_context, class: "form-control", rows: 5,
          placeholder: "What is your organization or community? Mission, current focus, member type." %>
  </div>

  <%= f.submit "Save Inventory", class: "btn",
        style: "background:var(--accent);color:#000;font-weight:600;" %>
<% end %>
```

### 3.5 — `app/views/gift_inventories/new.html.erb`

```erb
<div class="container py-4">
  <h1>Create Your Gift Inventory</h1>
  <p class="text-muted">Fill in what you bring, and we'll suggest projects worth your time.</p>
  <%= render "form", gift_inventory: @inventory %>
</div>
```

### 3.6 — `app/views/gift_inventories/edit.html.erb`

```erb
<div class="container py-4">
  <h1>Edit Your Gift Inventory</h1>
  <p class="text-muted">Last updated <%= @inventory.updated_at.strftime("%B %d, %Y") %></p>
  <%= render "form", gift_inventory: @inventory %>
</div>
```

### 3.7 — `app/views/gift_inventories/show.html.erb`

Two-section layout:

**Section 1 — Inventory summary card** (read-only):
- Render each field as a Bootstrap list group or pill list.
- Edit link → `edit_gift_inventory_path(@inventory)`.
- "Generate Projects" button wrapped in a `<turbo-frame id="generate-btn-frame">`:

```erb
<turbo-frame id="generate-btn-frame">
  <%= button_to "Generate Projects", generate_gift_inventory_path(@inventory),
        method: :post,
        class: "btn",
        style: "background:var(--accent);color:#000;font-weight:600;" %>
</turbo-frame>
```

**Section 2 — Project grid**:
- If `@project_ideas.empty?`, show empty state with a "Generate Projects" CTA.
- Otherwise show `TODO: project cards rendered in Phase 5`.

```erb
<% if @project_ideas.empty? %>
  <div class="text-center py-5">
    <p class="text-muted">No projects yet. Click "Generate Projects" above.</p>
  </div>
<% else %>
  <p class="text-muted fst-italic"><!-- Phase 5: project cards go here --></p>
  <% @project_ideas.each do |idea| %>
    <div class="card mb-2"><div class="card-body"><%= idea.name %></div></div>
  <% end %>
<% end %>
```

### 3.8 — `app/views/project_ideas/index.html.erb`

```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Generated Projects</h1>
    <% if current_user.gift_inventory %>
      <%= button_to "Regenerate", generate_gift_inventory_path(current_user.gift_inventory),
            method: :post, class: "btn btn-outline-secondary btn-sm" %>
    <% end %>
  </div>
  <% if @project_ideas.empty? %>
    <p class="text-muted">No projects generated yet. <%= link_to "Go to your inventory", current_gift_inventories_path %> to generate.</p>
  <% else %>
    <%# Phase 5: replace with card grid %>
    <% @project_ideas.each do |idea| %>
      <div class="card mb-2">
        <div class="card-body">
          <%= link_to idea.name, project_idea_path(idea) %>
        </div>
      </div>
    <% end %>
  <% end %>
</div>
```

### 3.9 — `app/views/project_ideas/show.html.erb`

```erb
<div class="container py-4">
  <%= link_to "← Back to projects", project_ideas_path, class: "text-muted small mb-3 d-block" %>
  <h1><%= @project_idea.name %></h1>
  <p><%= @project_idea.description %></p>
  <p><strong>First step this week:</strong> <%= @project_idea.first_step %></p>

  <%# Show raw response toggle %>
  <a class="btn btn-sm btn-outline-secondary mb-2" data-bs-toggle="collapse" href="#raw-response">
    Show raw response
  </a>
  <div class="collapse" id="raw-response">
    <pre class="bg-dark p-3 rounded small text-muted"><%= @project_idea.gemini_raw %></pre>
  </div>
</div>
```

### 3.10 — Navbar: Uncomment Links

In `app/views/layouts/application.html.erb`, remove the `TODO Phase 3` comment markers and uncomment the two nav links added in Phase 1.5:

```erb
<%= link_to "My Inventory", current_gift_inventories_path, class: "nav-link" %>
<%= link_to "Generated Projects", project_ideas_path, class: "nav-link" %>
```

### 3.11 — Dashboard: Wire Up Real Logic

In `app/views/dashboard/show.html.erb`, replace the Phase 1 placeholder with real conditionals:

```erb
<div class="container py-4">
  <% inventory = current_user.gift_inventory %>
  <% if inventory.nil? %>
    <%# Empty state %>
    <div class="text-center py-5">
      <h2>Welcome to <%= ENV.fetch("APP_NAME", "CapacityMap Demo") %></h2>
      <p class="text-muted">Start by creating your gift inventory.</p>
      <%= link_to "Create Your Gift Inventory", new_gift_inventory_path,
            class: "btn btn-lg", style: "background:var(--accent);color:#000;" %>
    </div>
  <% elsif inventory.project_ideas.empty? %>
    <%# Inventory exists, no projects %>
    <p class="text-muted">Inventory saved. Generate your first project ideas.</p>
    <%= button_to "Generate Projects", generate_gift_inventory_path(inventory),
          method: :post, class: "btn",
          style: "background:var(--accent);color:#000;font-weight:600;" %>
  <% else %>
    <%# Inventory + projects — show latest 3 %>
    <h2>Your Latest Projects</h2>
    <% inventory.project_ideas.ordered.limit(3).each do |idea| %>
      <div class="card mb-2">
        <div class="card-body"><%= link_to idea.name, project_idea_path(idea) %></div>
      </div>
    <% end %>
    <%= link_to "See all", project_ideas_path, class: "text-muted small" %>
  <% end %>
</div>
```

---

## RSpec

Write `spec/requests/gift_inventories_spec.rb` covering CRUD and access control (generate action specs are added in Phase 5):

- Unauthenticated `GET /gift_inventories/new` redirects to sign in.
- Unauthenticated `POST /gift_inventories` redirects to sign in.
- `GET /gift_inventories/current` redirects to `new_gift_inventory_path` when no inventory exists.
- `GET /gift_inventories/current` redirects to the inventory show page when one exists.
- `POST /gift_inventories` with valid params creates the inventory and redirects to the show page.
- `POST /gift_inventories` with too-few skills (< 5) returns 422.
- `GET /gift_inventories/:id` for another user's inventory returns 404.
- `GET /gift_inventories/:id/edit` for another user's inventory returns 404.

Write `spec/requests/project_ideas_spec.rb` covering index and show (generate-produced records tested in Phase 5):

- Unauthenticated `GET /project_ideas` redirects to sign in.
- Signed-in user sees an empty list when no projects exist (status 200).
- `GET /project_ideas/:id` for another user's project returns 404.

Use `sign_in_as(user)` helper and stub `GeminiService` per `docs/testing.md`.

---

## Manual Tests

- [ ] Sign in, visit `/gift_inventories/current` — redirects to `/gift_inventories/new`.
- [ ] Fill in and submit the new inventory form — creates record and redirects to show page.
- [ ] Visit show page — inventory summary renders with all fields.
- [ ] Visit edit, update a field, confirm redirect to show with updated values.
- [ ] Visit `/project_ideas` — renders empty state without errors.
- [ ] Confirm navbar shows "My Inventory" and "Generated Projects" links when signed in.
- [ ] Confirm dashboard shows "Create Your Gift Inventory" CTA for a user with no inventory.
- [ ] Sign in as a second user and try `GET /gift_inventories/{first-user-uuid}` — returns 404.
- [ ] Visit any gift_inventories route without signing in — redirects to sign in.

---

## Acceptance Criteria

- [ ] Routes file has `gift_inventories` and `project_ideas` resources plus `current` and `generate` members.
- [ ] Both controller files exist, scoped to `current_user`.
- [ ] `generate` raises `NotImplementedError` at this phase (implemented in Phase 5).
- [ ] All six views render without errors.
- [ ] Navbar "My Inventory" and "Generated Projects" links are active.
- [ ] Dashboard shows correct state based on inventory presence.
- [ ] CRUD and access-control request specs pass (`bundle exec rspec spec/requests/`).
