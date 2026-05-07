# Phase 6 — Seed Data

**Goal:** Running `rails db:seed` populates the database with a meaningful demo state that renders immediately without making a Gemini call. The demo user can sign in and see a filled inventory plus 6 sample project cards.

**Prerequisite:** Phases 2–5 complete — all models, routes, and views exist.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §7 (AI template full content), §10 (Seed data)
- `db/seeds.rb` — the existing boilerplate seed (creates `demo@example.com` admin); append to it, do not replace the boilerplate block
- `docs/ai-templates.md` — `AiTemplate` field names and how the template is looked up

---

## Tasks

### 6.1 — AiTemplate Seed (`capacitymap_projects_v1`)

Append to `db/seeds.rb` after the boilerplate user seed block. Use `find_or_create_by!` so re-seeding is idempotent.

Key fields:
- `name: "capacitymap_projects_v1"`
- `model: "gemini-2.5-flash"` (not `gemini-2.0-flash` — see implementation notes in tasks.md)
- `max_output_tokens: 2000`
- `temperature: 0.6`
- `system_prompt:` the full text from spec §7
- `user_prompt_template:` the full text from spec §7
- `description: "Generates 5 to 7 project ideas tailored to a user's gift inventory and organization context."`
- `notes:` the notes block from spec §7

```ruby
AiTemplate.find_or_create_by!(name: "capacitymap_projects_v1") do |t|
  t.description        = "Generates 5 to 7 project ideas tailored to a user's gift inventory."
  t.model              = "gemini-2.5-flash"
  t.max_output_tokens  = 2000
  t.temperature        = 0.6
  t.system_prompt      = <<~PROMPT.strip
    You are a community-capacity matching assistant...
    [full system_prompt text from spec §7]
  PROMPT
  t.user_prompt_template = <<~PROMPT.strip
    Contributor's gift inventory:
    [full user_prompt_template text from spec §7]
  PROMPT
  t.notes = "Temperature 0.6 favors structured output. Watch for: model occasionally returns 4 projects despite the rule..."
end
```

### 6.2 — Viewer Seed User

```ruby
User.find_or_create_by!(email: "viewer@example.com") do |u|
  u.password = "password123"
  u.admin    = false
end
```

No inventory or project ideas for this user — they experience the empty state.

### 6.3 — Sample GiftInventory for Demo Admin

Find the `demo@example.com` user (created by the boilerplate seed), then:

```ruby
demo = User.find_by!(email: "demo@example.com")

inventory = GiftInventory.find_or_create_by!(user: demo) do |inv|
  inv.skills               = ["facilitation", "copywriting", "event planning",
                               "public speaking", "project management",
                               "basic graphic design"].to_json
  inv.interests            = ["local food systems", "intergenerational community",
                               "climate adaptation", "civic engagement"].to_json
  inv.weekly_hours         = 6
  inv.connections          = ["local food co-op board", "neighborhood email list",
                               "two former colleagues at regional nonprofits"].to_json
  inv.experience_areas     = ["small-nonprofit operations", "community organizing", "education"].to_json
  inv.organization_context = "I am part of a 120-person neighborhood mutual aid network in a small city. Our current focus is winter readiness: we run a tool library, a meal-share rotation, and an annual community garden harvest. Members are mostly working-age, with a small but active retiree cohort. We meet monthly and coordinate via email plus a chat thread."
end
```

### 6.4 — Sample ProjectIdea Records (6 total)

Only create if the inventory has no project ideas (guard with `if inventory.project_ideas.empty?`). This prevents duplicate seeds on re-run without needing `find_or_create_by` on every project field.

Each record must have:
- `name`, `description`, `gifts_used`, `time_commitment`, `impact_type`, `first_step`
- `gemini_raw: '{"projects":[]}'` (placeholder — Show raw response reveals this is seed data)
- `position` 1 through 6
- `description` text must include "Seed data — not AI generated." per spec §10

Sample projects to create (use the spec §10 context as inspiration):

| # | name | impact_type |
|---|---|---|
| 1 | Neighborhood Skill-Share Workshop | Capacity building |
| 2 | Winter Readiness Newsletter | Storytelling |
| 3 | Tool Library Intake Coordinator | Direct service |
| 4 | Mutual Aid Network Mapping Project | Infrastructure |
| 5 | New Member Welcome Interview Program | Capacity building |
| 6 | Annual Harvest Event Planner | Direct service |

For `gifts_used`, reference real skills/interests from the inventory above. Example for project 1:

```ruby
gifts_used: [
  { "category" => "skill",    "name" => "facilitation" },
  { "category" => "skill",    "name" => "event planning" },
  { "category" => "interest", "name" => "intergenerational community" }
].to_json
```

---

## RSpec

Write a minimal seed spec `spec/tasks/seeds_spec.rb` (or place it in `spec/models/seed_spec.rb`) that loads the seed file and verifies structure without making Gemini calls:

```ruby
require "rails_helper"

RSpec.describe "db/seeds.rb" do
  before(:all) do
    # Run seeds in a transaction that will be rolled back
    DatabaseCleaner.strategy = :transaction
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the capacitymap_projects_v1 AiTemplate" do
    expect(AiTemplate.find_by(name: "capacitymap_projects_v1")).to be_present
  end

  it "creates demo@example.com as an admin" do
    user = User.find_by(email: "demo@example.com")
    expect(user).to be_present
    expect(user.admin).to be true
  end

  it "creates viewer@example.com as a non-admin" do
    user = User.find_by(email: "viewer@example.com")
    expect(user).to be_present
    expect(user.admin).to be false
  end

  it "creates a GiftInventory for the demo user" do
    demo = User.find_by!(email: "demo@example.com")
    expect(demo.gift_inventory).to be_present
  end

  it "creates 6 seed ProjectIdea records for the demo inventory" do
    demo = User.find_by!(email: "demo@example.com")
    expect(demo.gift_inventory.project_ideas.count).to eq(6)
  end

  it "seed project descriptions include the required disclaimer" do
    demo = User.find_by!(email: "demo@example.com")
    demo.gift_inventory.project_ideas.each do |idea|
      expect(idea.description).to include("Seed data")
    end
  end
end
```

Note: if DatabaseCleaner setup is complex for seed specs, these assertions can instead be verified as part of the manual test checklist only. The seed spec is a nice-to-have, not a blocker.

---

## Manual Tests

- [ ] `rails db:drop db:create db:migrate db:seed` — completes with no errors or exceptions.
- [ ] Sign in as `demo@example.com` / `password123` — dashboard shows inventory summary and 3 project cards with a "See all" link.
- [ ] Follow "See all" to `/project_ideas` — confirm 6 seed project cards render with correct chip colors.
- [ ] Click any project card — confirm show page renders with the raw response toggle (reveals placeholder JSON).
- [ ] Sign in as `viewer@example.com` / `password123` — dashboard shows empty state "Create Your Gift Inventory" CTA.
- [ ] Visit `/admin/ai_templates` as the demo admin — confirm `capacitymap_projects_v1` is listed with correct model and temperature.
- [ ] Run seeds a second time (`rails db:seed`) — confirm no duplicate records are created.

---

## Acceptance Criteria

- [ ] `db/seeds.rb` creates the `capacitymap_projects_v1` `AiTemplate` idempotently.
- [ ] Seed creates `viewer@example.com` with no inventory.
- [ ] Seed creates one `GiftInventory` for `demo@example.com` with all six fields populated.
- [ ] Seed creates 6 `ProjectIdea` records, positions 1–6, each with "Seed data — not AI generated." in description.
- [ ] Running `rails db:seed` twice produces no duplicates.
- [ ] Full manual test checklist above passes without any Gemini API call.
