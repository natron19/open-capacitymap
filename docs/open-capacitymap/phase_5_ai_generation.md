# Phase 5 — AI Generation

**Goal:** The "Generate Projects" button calls Gemini via `GeminiService`, parses the JSON response, saves a batch of `ProjectIdea` records, and renders the full project card grid.

**Prerequisite:** Phases 2–4 complete. Models, routes, controllers, and the chip-tag form all exist.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §5 (generate action), §6 (show page, project cards), §7 (AI template), §8 (AI safety)
- `docs/ai-templates.md` — `GeminiService.generate` call signature, error types, how to pass variables
- `docs/ai-guardrails.md` — what AiGatekeeper and AiBudgetChecker do; when errors are raised
- `docs/testing.md` — how to stub GeminiService in specs; `gemini_returns` / `gemini_raises` helpers
- `app/services/gemini_service.rb` — confirm error class names before writing rescue clauses
- `app/views/shared/_ai_error.html.erb` — the error partial; confirm `error_type` locals it accepts

---

## Tasks

### 5.1 — Implement `GiftInventoriesController#generate`

Replace the `NotImplementedError` stub. Key rules:
- Rate limit: `rate_limit to: 5, within: 1.minute, only: [:generate]`
- Scope the inventory to `current_user`; 404 if not found or if the ID doesn't match.
- Build the variables hash from the inventory's `*_list` helpers joined with `", "`.
- Call `GeminiService.generate(template: "capacitymap_projects_v1", variables: { ... })`.
- Parse and validate the JSON response.
- Wrap destroy + create in a transaction.
- Rescue all four GeminiService error classes.

```ruby
def generate
  @inventory = current_user.gift_inventory
  return render file: Rails.public_path.join("404.html"), status: :not_found unless @inventory&.id.to_s == params[:id]

  variables = {
    skills:               @inventory.skills_list.join(", "),
    interests:            @inventory.interests_list.join(", "),
    weekly_hours:         @inventory.weekly_hours.to_s,
    connections:          @inventory.connections_list.join(", "),
    experience_areas:     @inventory.experience_areas_list.join(", "),
    organization_context: @inventory.organization_context
  }

  raw = GeminiService.generate(template: "capacitymap_projects_v1", variables:)
  data = JSON.parse(raw)
  projects = data["projects"]

  unless projects.is_a?(Array) && projects.length.between?(5, 7)
    return redirect_to @inventory, alert: "The AI returned an unexpected format. Please try again."
  end

  ActiveRecord::Base.transaction do
    @inventory.project_ideas.destroy_all
    projects.each.with_index(1) do |proj, i|
      @inventory.project_ideas.create!(
        name:            proj["name"],
        description:     proj["description"],
        gifts_used:      proj["gifts_used"].to_json,
        time_commitment: proj["time_commitment"],
        impact_type:     proj["impact_type"],
        first_step:      proj["first_step"],
        gemini_raw:      raw,
        position:        i
      )
    end
  end

  redirect_to @inventory, notice: "Projects generated successfully."

rescue JSON::ParserError
  redirect_to @inventory, alert: "The AI returned an unexpected format. Please try again."
rescue GeminiService::BudgetExceededError
  redirect_to @inventory, alert: "Daily generation limit reached. Try again tomorrow."
rescue GeminiService::GatekeeperError
  redirect_to @inventory, alert: "Your inventory content was flagged. Please review and try again."
rescue GeminiService::TimeoutError
  redirect_to @inventory, alert: "The AI took too long to respond. Please try again."
rescue GeminiService::GeminiError
  redirect_to @inventory, alert: "An error occurred. Please try again."
end
```

### 5.2 — Update `app/views/gift_inventories/show.html.erb` — Project Card Grid

Replace the Phase 3 stub with the full card grid. Above the grid:

```erb
<p class="text-muted fst-italic small mb-3">
  These are AI-suggested starting points, not commitments.
  Validate fit with your community before acting.
</p>
```

Each project card (`@project_ideas.each`):

```erb
<div class="col-lg-4 col-md-6 col-12 mb-4">
  <div class="card h-100 project-card">
    <div class="card-body">
      <div class="d-flex justify-content-between align-items-start mb-2">
        <h5 class="card-title" style="color:var(--accent);">
          <%= link_to idea.name, project_idea_path(idea), style: "color:inherit;text-decoration:none;" %>
        </h5>
        <div>
          <span class="badge bg-secondary me-1"><%= idea.time_commitment %></span>
          <span class="badge bg-secondary"><%= idea.impact_type %></span>
        </div>
      </div>
      <p class="card-text small"><%= idea.description %></p>

      <p class="small fw-semibold mb-1">Gifts this draws on:</p>
      <div class="d-flex flex-wrap gap-1 mb-3">
        <% idea.gifts_used_list.each do |gift| %>
          <span class="chip-tag chip-tag--<%= gift["category"] %>">
            <%= gift["name"] %>
          </span>
        <% end %>
      </div>

      <div class="first-step-alert p-2 rounded small">
        <strong>First step this week:</strong> <%= idea.first_step %>
      </div>

      <div class="mt-3">
        <a class="btn btn-sm btn-outline-secondary" data-bs-toggle="collapse"
           href="#raw-<%= idea.id %>">Show raw response</a>
        <div class="collapse mt-2" id="raw-<%= idea.id %>">
          <pre class="bg-dark p-2 rounded small text-muted" style="white-space:pre-wrap;"><%= idea.gemini_raw %></pre>
        </div>
      </div>
    </div>
  </div>
</div>
```

Wrap all cards in `<div class="row">`.

### 5.3 — Update `app/views/project_ideas/index.html.erb`

Replace the Phase 3 stub with the same card grid partial or inline card loop used in the show page. The "Regenerate" button posts to `generate_gift_inventory_path(current_user.gift_inventory)`.

Add the same AI disclaimer line above the grid.

### 5.4 — Update `app/views/project_ideas/show.html.erb`

The Show raw response collapse should be **expanded by default** on this detail page. Add `show` class to the collapse div:

```erb
<div class="collapse show" id="raw-response">
```

### 5.5 — AI Disclaimer

Confirm the disclaimer is on both the show page grid and the project index page. It must NOT be in the seed-data cards (those have "Seed data — not AI generated" in their description instead).

---

## RSpec

Add to `spec/requests/gift_inventories_spec.rb` (the file written in Phase 3):

```ruby
describe "POST /gift_inventories/:id/generate" do
  let(:inventory) { create(:gift_inventory, user: user) }
  let(:valid_response) do
    { "projects" => Array.new(5) { |i|
      { "name" => "Project #{i+1}", "description" => "Desc", "gifts_used" => [],
        "time_commitment" => "2 hrs/wk", "impact_type" => "Direct service",
        "first_step" => "Step one." }
    }}.to_json
  end

  context "with valid stubbed Gemini response" do
    before { allow(GeminiService).to receive(:generate).and_return(valid_response) }

    it "creates 5 ProjectIdea records" do
      post generate_gift_inventory_path(inventory)
      expect(inventory.reload.project_ideas.count).to eq(5)
    end

    it "creates exactly one LlmRequest with status success and correct template_name" do
      expect { post generate_gift_inventory_path(inventory) }
        .to change(LlmRequest, :count).by(1)
      expect(LlmRequest.last.status).to eq("success")
      expect(LlmRequest.last.template_name).to eq("capacitymap_projects_v1")
    end

    it "replaces an existing batch" do
      create_list(:project_idea, 3, gift_inventory: inventory)
      post generate_gift_inventory_path(inventory)
      expect(inventory.reload.project_ideas.count).to eq(5)
    end
  end

  context "with malformed JSON" do
    before { allow(GeminiService).to receive(:generate).and_return("not json") }

    it "redirects with an alert and creates no ProjectIdea records" do
      post generate_gift_inventory_path(inventory)
      expect(response).to redirect_to(gift_inventory_path(inventory))
      expect(flash[:alert]).to be_present
      expect(inventory.project_ideas.count).to eq(0)
    end
  end

  context "with GeminiService::TimeoutError" do
    before { allow(GeminiService).to receive(:generate).and_raise(GeminiService::TimeoutError) }

    it "redirects with a timeout alert" do
      post generate_gift_inventory_path(inventory)
      expect(response).to redirect_to(gift_inventory_path(inventory))
      expect(flash[:alert]).to match(/too long|try again/i)
    end
  end

  it "returns 404 when trying to generate for another user's inventory" do
    other_inventory = create(:gift_inventory)
    post generate_gift_inventory_path(other_inventory)
    expect(response).to have_http_status(:not_found)
  end
end
```

---

## Manual Tests

- [ ] Create a valid gift inventory and click "Generate Projects" — confirm 5–7 project cards appear.
- [ ] Confirm each card shows: project name in accent color, time/impact badges, description, color-coded gift chips, first-step callout.
- [ ] Confirm "Show raw response" toggle on the card reveals the Gemini JSON.
- [ ] Click "Generate Projects" again — confirm old cards are replaced by a new batch.
- [ ] Visit `/project_ideas` — confirm same card grid with "Regenerate" button.
- [ ] Visit a project detail page (`/project_ideas/:id`) — confirm raw response is expanded by default.
- [ ] Visit `/admin/llm_requests` — confirm one `LlmRequest` row per generation, `status: success`, `template_name: capacitymap_projects_v1`.
- [ ] Test error path: temporarily pass a wrong template name, click Generate — confirm the alert flash renders and no new cards appear.

---

## Acceptance Criteria

- [ ] `generate` action is fully implemented (no `NotImplementedError`).
- [ ] Rate limit of 5 per minute is set on the `generate` action.
- [ ] Successful generate creates 5–7 `ProjectIdea` records with all fields populated.
- [ ] Generate destroys the previous batch before creating the new one (transaction).
- [ ] `gemini_raw` is stored on each `ProjectIdea` in the batch.
- [ ] Project card grid renders with correct chip colors, badges, first-step callout, and raw response toggle.
- [ ] AI disclaimer line appears above both the show page grid and the project index.
- [ ] All four GeminiService error types are rescued and produce a flash redirect.
- [ ] Generate request specs pass (`bundle exec rspec spec/requests/gift_inventories_spec.rb`).
