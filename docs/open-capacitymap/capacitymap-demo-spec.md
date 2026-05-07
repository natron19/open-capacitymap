# CapacityMap Demo - Specification

**Document Version:** 1.0
**Last Updated:** May 4, 2026
**Built On:** Open Demo Starter v2.0
**License:** MIT
**Source Prompt:** open_capacitymap_prompt.md (v3.0)
**Source Brief:** 22_AppBrief_CapacityMap_v4.md (production app context)

---

## 1. App Overview

CapacityMap Demo is an open source, single-user, locally runnable Rails 8 app that demonstrates the matching engine at the heart of CapacityMap, a community capacity platform. The user fills out a short inventory of the gifts they bring to a community: skills they enjoy using, interests and causes they care about, weekly availability, connections they could activate, and specific experience areas. They also describe their organization or community context in a short paragraph. Gemini returns 5 to 7 specific project ideas where these gifts could be applied, naming explicitly which gifts each project draws on.

Most volunteer-matching tools list pre-existing tasks and ask people to pick from them. CapacityMap inverts the model: it starts with the gifts a person already has and surfaces the projects only they could meaningfully run. The G.I.F.T. framework (Gather, Invite, Fit, Thank) treats members as gift-bearers rather than resources to deploy.

This demo is one tool from a larger multi-tenant SaaS suite the author is building. The production version is multi-tenant with team collaboration, recognition workflows, contribution tracking, and a four-stage G.I.F.T. dashboard. This demo is open source under MIT license, scoped to a single signed-in user, and runs on localhost. Visitors can clone the repo, sign in as the seeded admin, and see one feature: the inverted matching engine, end to end.

### Indie Hacker Angle

The bet is that capacity-first matching is more honest than task-first matching. Volunteer-management tools optimize for the coordinator's filing cabinet. CapacityMap optimizes for the contributor's sense of being seen. The demo is the smallest possible artifact that lets a stranger feel that difference in under five minutes.

---

## 2. Customizations Applied to the Boilerplate

This section lists every place this demo diverges from the default Open Demo Starter v2.0.

- **`.env.example` values:**
  - `APP_NAME="CapacityMap Demo"`
  - `APP_TAGLINE="Inventory your gifts. Get a list of meaningful projects where they are needed."`
  - `APP_DESCRIPTION="Open source demo of CapacityMap's gift-to-project matching engine. Built on Rails 8 plus Gemini."`
- **Accent color** in `app/assets/stylesheets/_accent.scss`:
  - `--accent: #a3e635;` (vibrant lime green)
  - `--accent-hover: #84cc16;` (slightly deeper green for hover)
  - `--accent-secondary: #a855f7;` (rich purple, used for gift category chips and project name accents)
  - `--accent-secondary-hover: #9333ea;`
- **Navbar links added** to the boilerplate's authenticated navbar:
  - "My Inventory" linking to `/gift_inventories/current` (a friendly redirect to the user's single inventory)
  - "Generated Projects" linking to `/project_ideas` (cross-inventory list of all generated projects)
- **Home page** (`home/index.html.erb`) replaced with the demo's landing pitch: an asymmetric two-column hero, lime-green accents, a short explanation of inverted matching, and a single sign-up call to action.
- **Dashboard page** (`dashboard/show.html.erb`) replaced with the inventory overview: shows the current GiftInventory summary (or an empty-state prompt to create one) and the latest generated project cards.
- **UX pattern chosen:** form-then-result with chip-style tag inputs on the form side and a card grid on the result side. The form uses Bootstrap input groups; each gift category has chip-style tag entry powered by a Stimulus controller that adds and removes tags on Enter. After generation, projects render as a card grid where each card highlights the named gifts that connect to that project, color-coded by category.
- **AI templates seeded** in `db/seeds.rb`:
  - `capacitymap_projects_v1` (full content in Section 7)

No other boilerplate behavior is changed. Authentication, the layout shell, the GeminiService, the AiTemplate model, the LlmRequest log, the AiGatekeeper, the AiBudgetChecker, the admin panel, and the RSpec setup all remain as inherited.

---

## 3. Data Model

Two new domain models are added on top of `User`, `AiTemplate`, and `LlmRequest`.

### GiftInventory

The user's gift inventory. One per user (enforced at the model level), but written as `has_many` to keep regeneration cheap if the author later wants to support history.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key, indexed |
| `skills` | text | JSON-encoded array of 5 to 8 skill strings **(template variable: `{{skills}}`)** |
| `interests` | text | JSON-encoded array of 3 to 5 interest strings **(template variable: `{{interests}}`)** |
| `weekly_hours` | integer | Hours per week the user can contribute **(template variable: `{{weekly_hours}}`)** |
| `connections` | text | JSON-encoded array of 3 to 5 connection strings **(template variable: `{{connections}}`)** |
| `experience_areas` | text | JSON-encoded array of experience-area strings **(template variable: `{{experience_areas}}`)** |
| `organization_context` | text | One-paragraph description of mission, current focus, and member type **(template variable: `{{organization_context}}`)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations**
- `belongs_to :user`
- `has_many :project_ideas, dependent: :destroy`

**Validations**
- `validates :user_id, uniqueness: true` (one inventory per user in this demo)
- `validates :weekly_hours, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 80 }`
- `validates :organization_context, length: { minimum: 50, maximum: 1000 }`
- Custom validation: `skills` must contain 5 to 8 entries when parsed; `interests` 3 to 5; `connections` 3 to 5; `experience_areas` 1 or more.

**Helper methods**
- `skills_list`, `interests_list`, `connections_list`, `experience_areas_list` parse the JSON-encoded text into Ruby arrays. Setters accept either a JSON string or an array.

### ProjectIdea

A single AI-suggested project. Created in batches of 5 to 7 each time the user generates from an inventory.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `gift_inventory_id` | uuid | Foreign key, indexed |
| `name` | string | Short project name |
| `description` | text | One-paragraph description of the project |
| `gifts_used` | text | JSON-encoded array of objects: `{ "category": "skill", "name": "facilitation" }`. Used to render the color-coded gift chips on the project card. |
| `time_commitment` | string | Free text, e.g. "2 to 4 hours per week for 6 weeks" |
| `impact_type` | string | Free text, e.g. "Direct service", "Capacity building", "Storytelling" |
| `first_step` | text | One-sentence first step the user could take this week |
| `gemini_raw` | text | Raw Gemini response for this generation batch (denormalized onto each project for the Show raw response toggle) **(Gemini output, used for Show raw response toggle)** |
| `position` | integer | Display order within a batch (1 through 7) |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations**
- `belongs_to :gift_inventory`
- `has_one :user, through: :gift_inventory`

**Validations**
- `validates :name, :description, :first_step, presence: true`
- `validates :name, length: { maximum: 120 }`

**Scopes**
- `scope :latest_batch, -> { where(created_at: maximum(:created_at).beginning_of_minute..) }` to fetch the most recent batch.
- `scope :ordered, -> { order(:position) }`

### What's Intentionally Missing

- No `Match`, `Commitment`, `Contribution`, or `Recognition` models. Those are the post-matching steps in the production app; the demo stops at suggestion.
- No `Organization`, `Member`, or `Project` models in the production-system sense. The demo is single-user; the user describes their organization in a free-text field.
- No history of regenerations. When the user clicks Generate again, the previous batch is discarded. The author can revisit this if portfolio visitors ask for it.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/gift_inventories/current` | `gift_inventories#current` | Redirects to the user's existing inventory or to `new` |
| GET | `/gift_inventories/new` | `gift_inventories#new` | New inventory form |
| POST | `/gift_inventories` | `gift_inventories#create` | Create the inventory |
| GET | `/gift_inventories/:id` | `gift_inventories#show` | Show inventory plus generated project ideas |
| GET | `/gift_inventories/:id/edit` | `gift_inventories#edit` | Edit inventory form |
| PATCH | `/gift_inventories/:id` | `gift_inventories#update` | Update the inventory |
| POST | `/gift_inventories/:id/generate` | `gift_inventories#generate` | Trigger Gemini call, replace existing ProjectIdea batch |
| GET | `/project_ideas` | `project_ideas#index` | Cross-inventory list of all generated projects (single inventory in this demo, so this is essentially the same content as the show page; included for direct linkability from the navbar) |
| GET | `/project_ideas/:id` | `project_ideas#show` | Single project detail page with the Show raw response toggle |

Auth and admin routes are inherited from the boilerplate and not redescribed here.

---

## 5. Controllers and Actions

All controllers inherit from `ApplicationController` (which requires authentication) and scope queries to `current_user`. All Gemini-touching actions catch `GeminiService::GeminiError` and its subclasses and render the boilerplate's friendly retry partial.

### GiftInventoriesController

- **`current`** redirects to the user's existing inventory if one exists, or to `new` if not. Keeps the navbar link stable across states.
- **`new`** renders the inventory form with empty chip-tag inputs.
- **`create`** persists the inventory using strong params, then redirects to the inventory show page.
- **`show`** loads `current_user.gift_inventory` and its `project_ideas.ordered`. Renders the form-then-result split: inventory summary on top, project card grid below (or an empty-state Generate button if no projects yet).
- **`edit`** renders the inventory form pre-filled.
- **`update`** persists changes and redirects to show.
- **`generate`** is the action that triggers the Gemini call. Steps:
  1. Loads the inventory and serializes its fields into the variables hash.
  2. Calls `GeminiService.generate(template: "capacitymap_projects_v1", variables: { skills: ..., interests: ..., weekly_hours: ..., connections: ..., experience_areas: ..., organization_context: ... })`.
  3. Parses the JSON response, validates schema (5 to 7 projects, each with the expected keys).
  4. Wraps the destroy-and-create in a transaction: destroys the existing `project_ideas` for this inventory and creates the new batch with the raw response stored on each `ProjectIdea.gemini_raw`.
  5. Redirects to the inventory show page with a flash notice.
  6. On parse error, surfaces the boilerplate's retry partial with a "The AI returned an unexpected format. Try again." message.

### ProjectIdeasController

- **`index`** lists all of `current_user.gift_inventory.project_ideas.ordered`. In this demo, this is a redundant view of the show page's results section; it exists so the navbar can link directly to "Generated Projects" without going through the inventory.
- **`show`** loads a single project by ID, scoped through `current_user.gift_inventory.project_ideas`. Renders the full project card with the Show raw response toggle expanded by default for inspection.

The boilerplate-provided `ApplicationController`, `Admin::BaseController`, `SessionsController`, `RegistrationsController`, and `PasswordsController` are not redescribed.

---

## 6. Views

### `gift_inventories/_form.html.erb`

Shared partial used by `new` and `edit`. Renders six fields:

- **Skills** (input group with chip-style tag entry, 5 to 8 chips, placeholder "Type a skill and press Enter")
- **Interests** (input group with chip-style tag entry, 3 to 5 chips, placeholder "What causes pull at you?")
- **Weekly hours** (Bootstrap range slider 1 to 40 with a number readout)
- **Connections** (input group with chip-style tag entry, 3 to 5 chips, placeholder "People or networks you could activate")
- **Experience areas** (input group with chip-style tag entry, 1 or more chips, placeholder "Industries, domains, communities")
- **Organization context** (textarea, 50 to 1000 chars, placeholder "What is your organization or community? Mission, current focus, member type.")

Each chip-tag input is wrapped in a `data-controller="chip-tags"` element with `data-chip-tags-min-value` and `data-chip-tags-max-value` set per field. Pressing Enter promotes the typed text into a chip. The X button on each chip removes it. The hidden input value is JSON-encoded on every change. Validation messages render below each input via Bootstrap's invalid-feedback.

### `gift_inventories/show.html.erb`

Two-section layout:

1. **Inventory summary card** at the top with the user's six fields rendered as read-only chip lists (color-coded per category) plus an Edit link and a Generate Projects button. The Generate button shows a Bootstrap spinner during the AI call (Turbo Frame submission).
2. **Project card grid** below. If no projects exist, an empty state with a topographic-map illustration and a primary-accent Generate button. If projects exist, a Bootstrap row of three cards per row on desktop, one per row on mobile.

Each project card includes:
- Project name (large, accent-colored)
- Time commitment badge (top right)
- Impact type badge (next to time commitment)
- One-paragraph description
- "Gifts this draws on" section: chip list of `gifts_used`, color-coded by category (lime green for skills, purple for interests, deeper purple for connections, neutral for experience areas)
- "First step this week" callout (left-bordered alert with the secondary accent color)
- A "Show raw response" Bootstrap collapse toggle that reveals `gemini_raw` in a `<pre>` block for that project

### `gift_inventories/new.html.erb` and `edit.html.erb`

Both render a heading plus the form partial. New shows a one-line orientation note. Edit shows a "Last updated" timestamp.

### `project_ideas/index.html.erb`

Same card grid as the show page's results section, plus a header with a "Regenerate" button (POSTs to the inventory's generate action).

### `project_ideas/show.html.erb`

Single-project detail view. Same card layout as in the grid, but full-width and with the Show raw response toggle expanded by default.

### `home/index.html.erb`

Two-column hero on desktop, stacked on mobile.
- Left column: H1 "Inventory your gifts. Get a list of meaningful projects where they are needed.", a 3-line explanation of inverted matching, and a primary-accent "Get Started" button linking to sign up.
- Right column: a topographic-map SVG illustration with green dots scattered across muted contour lines.

### `dashboard/show.html.erb`

If no inventory exists, an empty state with a "Create Your Gift Inventory" primary-accent button.
If an inventory exists with no projects, the inventory summary plus a "Generate Projects" button.
If both exist, the inventory summary plus the latest project cards (cap at 3 with a "See all" link to `/project_ideas`).

### Stimulus controller: `chip_tags_controller.js`

Custom controller that handles the chip-style tag input on the form. Targets:
- `input` (the visible text field)
- `hidden` (the hidden field that holds the JSON-encoded array)
- `chips` (the container where chip elements are rendered)

Behaviors:
- On Enter or comma in the input, promote the value to a chip if not blank and not duplicate. Update the hidden field. Fire a custom `chip-tags:change` event.
- On chip X click, remove the chip and update the hidden field.
- On form submit, validate min and max counts and prevent submission with a Bootstrap invalid-feedback message if outside range.

### Show raw response toggle

Every view that displays Gemini-generated output includes the inherited Bootstrap collapse toggle. This is the boilerplate's pattern; not redescribed except to confirm it appears on the project card and the project detail page.

---

## 7. AI Templates and Gemini Integration

This demo seeds one AiTemplate. The full record values follow.

### Template: `capacitymap_projects_v1`

- **`name`:** `capacitymap_projects_v1`
- **`description`:** Generates 5 to 7 project ideas tailored to a user's gift inventory and organization context, naming explicitly which gifts each project draws on.
- **`model`:** `gemini-2.0-flash`
- **`max_output_tokens`:** 2000
- **`temperature`:** 0.6 (slightly below the 0.7 default; favors structured, named-gift output over creative tangents)
- **Where it's called:** `GiftInventoriesController#generate`

#### `system_prompt`

```
You are a community-capacity matching assistant. Your job is to read a person's
gift inventory and the context of the organization or community they are part
of, then propose 5 to 7 specific projects where their gifts could be put to
meaningful use.

You are operating inside the G.I.F.T. framework: Gather, Invite, Fit, Thank.
This call corresponds to the Fit step. The contributor has already gathered
their gifts; you are surfacing projects that fit those gifts well enough that
the contributor would say yes if invited.

Treat the user as a gift-bearer, not a resource to deploy. Projects should
honor what the contributor enjoys doing and the time they have, not maximize
extraction.

For each project, you must:
1. Name the project specifically. Avoid generic titles like "Volunteer
   project" or "Help out at the community center". Use a name a coordinator
   could put on a sign-up sheet.
2. Write a one-paragraph description that explains what the project is, who
   it serves, and why this contributor in particular is well suited to it.
3. List which gifts from the inventory the project draws on. Use the exact
   wording the contributor used. Categorize each gift used as one of:
   "skill", "interest", "connection", or "experience_area".
4. Estimate a realistic time commitment (e.g., "2 to 4 hours per week for 6
   weeks"). Stay within the contributor's stated weekly availability.
5. Name the type of impact the project creates. Examples: "Direct service",
   "Capacity building", "Storytelling", "Coalition building", "Infrastructure".
6. Suggest a concrete first step the contributor could take THIS WEEK to
   begin. The first step must be small enough to fit in 30 minutes.

Constraints:
- Suggest projects that fit the organization context provided. Do not
  propose projects that contradict the organization's mission or member
  type.
- Do not propose projects that require more weekly hours than the
  contributor has stated.
- Do not invent gifts the contributor did not list. Every gift named in
  "gifts_used" must appear in the inventory.
- Do not promise specific outcomes or impact magnitudes. The contributor
  validates fit by reading and choosing.
- Output valid JSON only, with no markdown code fences and no commentary.

Return JSON in exactly this shape:
{
  "projects": [
    {
      "name": "string",
      "description": "string",
      "gifts_used": [
        {"category": "skill|interest|connection|experience_area", "name": "string"}
      ],
      "time_commitment": "string",
      "impact_type": "string",
      "first_step": "string"
    }
  ]
}

The projects array must contain 5 to 7 entries.
```

#### `user_prompt_template`

```
Contributor's gift inventory:

Skills they enjoy using: {{skills}}
Interests and causes they care about: {{interests}}
Weekly availability: {{weekly_hours}} hours per week
Connections they could activate: {{connections}}
Experience areas: {{experience_areas}}

Organization or community context:
{{organization_context}}

Suggest 5 to 7 specific projects where this contributor's gifts could be
applied. Follow the rules in the system instruction. Return JSON only.
```

#### Variables consumed

| Variable | Source field | Format |
|---|---|---|
| `{{skills}}` | `GiftInventory#skills_list` | Comma-separated string |
| `{{interests}}` | `GiftInventory#interests_list` | Comma-separated string |
| `{{weekly_hours}}` | `GiftInventory#weekly_hours` | Integer rendered as string |
| `{{connections}}` | `GiftInventory#connections_list` | Comma-separated string |
| `{{experience_areas}}` | `GiftInventory#experience_areas_list` | Comma-separated string |
| `{{organization_context}}` | `GiftInventory#organization_context` | Plain text paragraph |

#### Expected output format

JSON object with a single `projects` key containing an array of 5 to 7 project objects. The schema is enforced by the controller's parser: missing keys, fewer than 5 projects, or more than 7 projects raise a parse error and trigger the retry UI.

#### How the response is parsed and rendered

- The controller calls `JSON.parse(response)` on the raw text.
- For each entry, it creates a `ProjectIdea` record with the corresponding fields, plus `gemini_raw` set to the full raw response string and `position` set to the array index plus 1.
- The `gifts_used` array of objects is JSON-encoded back into the `ProjectIdea#gifts_used` text field.
- Cards in the view iterate `gifts_used` and render each as a chip with the appropriate category color.

#### Domain field that stores the raw response

`ProjectIdea#gemini_raw` (each ProjectIdea in a batch stores the full raw response so that any single card's Show raw response toggle is fully self-contained). This is a small storage cost but simplifies the view.

#### `notes` (author's notes)

The temperature was lowered from 0.7 to 0.6 because the failure mode at higher temperatures was projects with names that ignored the organization_context. Watch for: the model occasionally returns 4 projects despite the rule (retry usually fixes it); the model sometimes invents a "skill" that is a near-paraphrase of one in the list (the parser should reject these or the prompt should be tightened in v2). When iterating, test against an organization_context that is intentionally narrow (a single-mission food pantry) to confirm the model does not drift into generic suggestions.

This demo does not use Gemini's function calling. It is a single-shot prompt with structured JSON output.

---

## 8. AI Safety Considerations (Specific to This App)

CapacityMap Demo is a low-to-medium-stakes AI app. The user receives suggestions; they choose what to act on. The boilerplate's gatekeeper, budget cap, request log, timeout, and raw-response toggle cover the operational floor. Beyond that:

### Content sensitivity

The user types their interests and causes (potentially including topics like racial justice, climate, faith, mental health) and a paragraph about their organization (potentially a recovery group, a religious community, a political organization). The AI does not need to interpret these as anything other than matching context. The system prompt explicitly forbids the model from contradicting the organization's mission. There is no political stance built into the matching itself; the matcher inherits the user's stated values.

### Consequential outputs

A user could read a suggested project and act on it. The worst realistic case is the user invests time in a project that turns out not to fit their actual community. This is a real cost (time and motivation) but not a safety harm; it is the same downside as following bad advice from any volunteer-matching tool. The first-step constraint (must fit in 30 minutes) caps the wasted effort if a suggestion is poor. The "Show raw response" toggle and the explicit naming of which gifts drive each suggestion give the user enough context to evaluate fit before committing.

### Domain accuracy requirements

The model can hallucinate organizational context, plausible-sounding but unrealistic time commitments, or impact types that do not exist. The mitigation is the prompt rule that gifts_used must be drawn from the inventory (parser-enforced) and the prompt rule that time_commitment must respect weekly_hours. There is no claim of expert authority; the UI consistently positions suggestions as starting points, not assignments.

### App-specific disclaimer copy

The project card grid header includes the line: "These are AI-suggested starting points, not commitments. Validate fit with your community before acting." This is in addition to the boilerplate's footer disclaimer.

### Tightened settings

Default settings inherited from the boilerplate are appropriate. The 50 calls per user per day cap is more than sufficient for a demo (each generation is one call). The 15-second timeout is comfortable for `gemini-2.0-flash` JSON output of this size. `max_output_tokens` of 2000 is the right ceiling: 7 projects with full descriptions fit comfortably under the limit.

### What this demo deliberately does NOT do (for safety reasons)

- It does not match contributors to specific people or named organizations beyond what the user types in their own context. It will not generate "contact the Red Cross" style suggestions; the system prompt scopes suggestions to the user's stated community.
- It does not estimate impact in numerical terms ("you will help 200 people"). Impact is named by category only.
- It does not retain a regeneration history for the demo. If a user is exploring sensitive contexts, only the current batch is visible.
- It does not store the user's gift inventory anywhere outside their own user-scoped record, and the demo runs locally only.

This is a low-stakes enough demo that one paragraph of disclaimer plus the boilerplate's defaults are sufficient. The portfolio talking point is that the prompt explicitly forbids the model from inventing gifts and from overpromising impact; both are AI safety design choices baked into the system_prompt itself rather than retrofitted onto the UI.

---

## 9. RSpec Outline

Each new spec file and 3 to 5 specific things it tests. The boilerplate's specs for User, AiTemplate, LlmRequest, GeminiService, AiGatekeeper, AiBudgetChecker, and the auth flows are inherited and not redescribed.

### `spec/models/gift_inventory_spec.rb`

- Validates `weekly_hours` numericality between 1 and 80
- Validates skills count is between 5 and 8 when parsed from JSON-encoded text
- Validates interests count is between 3 and 5
- Validates connections count is between 3 and 5
- `belongs_to :user` and `has_many :project_ideas` associations work and `dependent: :destroy` cascades

### `spec/models/project_idea_spec.rb`

- Validates `name`, `description`, and `first_step` presence
- `belongs_to :gift_inventory` association
- `ordered` scope returns records sorted by position
- `has_one :user, through: :gift_inventory` works

### `spec/requests/gift_inventories_spec.rb`

- POST `/gift_inventories` with valid params creates the inventory and redirects to show
- POST `/gift_inventories` with too-few skills returns 422 with form errors
- POST `/gift_inventories/:id/generate` with a stubbed Gemini response (via the boilerplate's test double) creates 5 to 7 ProjectIdea records associated with the inventory
- POST `/gift_inventories/:id/generate` creates exactly one `LlmRequest` record with `status: "success"` and the correct `template_name`
- POST `/gift_inventories/:id/generate` replaces an existing batch (destroys old projects, creates new ones)
- A different signed-in user receives 404 when trying to access another user's inventory show page
- POST `/gift_inventories/:id/generate` with a stubbed malformed JSON response renders the retry partial and does not create ProjectIdea records

### `spec/requests/project_ideas_spec.rb`

- GET `/project_ideas` lists only the current user's projects
- GET `/project_ideas/:id` for another user's project returns 404
- GET `/project_ideas/:id` renders the Show raw response toggle with the correct `gemini_raw` content

No system specs are included. The chip-tag Stimulus controller is testable manually; adding system specs for a single Stimulus interaction adds CI weight without portfolio benefit.

---

## 10. Seed Data

`db/seeds.rb` adds the following on top of the boilerplate's seeded admin demo user.

### 1. AiTemplate seed

The seed file creates the `capacitymap_projects_v1` template with the full `system_prompt` and `user_prompt_template` text from Section 7, model `gemini-2.0-flash`, `max_output_tokens` 2000, `temperature` 0.6, and `notes` matching Section 7's notes block. Confirmed: this is the same template defined in Section 7; the seed file is the canonical source so admin edits in `/admin/ai_templates` reflect against this baseline.

### 2. Domain seeds

For the seeded admin user `demo@example.com`, the seed file creates one `GiftInventory` with realistic sample data:

- **Skills:** facilitation, copywriting, event planning, public speaking, project management, basic graphic design
- **Interests:** local food systems, intergenerational community, climate adaptation, civic engagement
- **Weekly hours:** 6
- **Connections:** local food co-op board, neighborhood email list, two former colleagues at regional nonprofits
- **Experience areas:** small-nonprofit operations, community organizing, education
- **Organization context:** "I am part of a 120-person neighborhood mutual aid network in a small city. Our current focus is winter readiness: we run a tool library, a meal-share rotation, and an annual community garden harvest. Members are mostly working-age, with a small but active retiree cohort. We meet monthly and coordinate via email plus a chat thread."

The seed also creates 6 sample `ProjectIdea` records linked to that inventory so the show page renders meaningfully on first run without making a Gemini call. Each sample project has realistic name, description, gifts_used, time_commitment, impact_type, first_step, and a placeholder `gemini_raw` of `'{"projects":[...sample sample...]}'` so the Show raw response toggle has something to reveal. The sample projects are clearly tagged in their `description` text as seed data so a portfolio visitor knows they were not just generated.

A second non-admin seed user (`viewer@example.com` / `password123`) is also created with no inventory, so a portfolio visitor can experience the empty state without first deleting the seeded inventory.

---

## 11. README Additions

The app-specific sections that override or extend the boilerplate's README template.

### App name, tagline, and one-paragraph description

> **CapacityMap Demo**
>
> Inventory your gifts. Get a list of meaningful projects where they are needed.
>
> CapacityMap Demo is an open source Rails 8 plus Gemini app that demonstrates the matching engine at the heart of CapacityMap, a community capacity platform. You list 5 to 8 skills you enjoy using, 3 to 5 interests, your weekly availability, 3 to 5 connections you could activate, your experience areas, and a paragraph about your organization. Gemini returns 5 to 7 specific projects where those gifts could be put to use, naming explicitly which gifts each project draws on.

### Screenshot placeholder

A placeholder line in the README: "**Screenshot:** _Add screenshot of the inventory form and the generated project card grid here._"

### Why I built this

> Most volunteer-matching software starts from the coordinator's task list and asks contributors to pick from it. That model treats people as resources to deploy. I wanted to see what it felt like to invert it: start from what someone brings, then surface the projects only they could meaningfully run.
>
> CapacityMap Demo is one feature from a larger multi-tenant SaaS suite I am building. The production version is multi-tenant with team collaboration, recognition workflows, contribution tracking, and a four-stage G.I.F.T. dashboard. Find the production app at [capacitymap.app](https://capacitymap.app) (placeholder).
>
> This demo is open source under the MIT license. Clone it, run it, edit the prompt, see how it changes the suggestions. The whole codebase is small enough to read in an afternoon.

### Editable prompt

> The Gemini prompt for this demo lives in `/admin/ai_templates`, not in the code. Sign in as the seeded admin user (`demo@example.com` / `password123`), open the `capacitymap_projects_v1` template, and edit the system prompt or the user prompt template. The admin UI has a live test panel: type sample variable values, click Test, and see Gemini's response inline before saving. This is the best way to feel how a prompt change shifts the suggestions.

### App-specific setup steps

None beyond the boilerplate's `bin/setup`. The only required environment variable is `GEMINI_API_KEY`, which is documented in the boilerplate's README.

The standard "Stack", "Setup", "License", "AI Safety Posture", and "About the Author" sections come from the boilerplate's template and are not rewritten here.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### Component choices

The app is **form-heavy on the inventory side and card-grid on the result side**. Specific Bootstrap components used:

- **Input groups** for chip-style tag inputs (Skills, Interests, Connections, Experience areas)
- **Range slider** for Weekly hours
- **Textarea** for Organization context
- **Cards** for project ideas, in a Bootstrap row with `col-lg-4 col-md-6 col-12` (3 across on desktop, 2 on tablet, 1 on mobile)
- **Badges** for time_commitment and impact_type (top right of each card)
- **Alert with left-border accent** for the "First step this week" callout (uses the secondary accent color)
- **Collapse** for the Show raw response toggle (inherited from the boilerplate)

### Accent application

The lime-green primary accent (`var(--accent)`, `#a3e635`) is applied to:
- Primary buttons (Generate Projects, Save Inventory, Get Started)
- Active navbar link state
- Project name color on each card
- Skill chip background (subtle, with darker text)
- Range slider thumb and track-fill
- Hero illustration's scattered topographic dots

The rich purple secondary accent (`var(--accent-secondary)`, `#a855f7`) is applied to:
- Interest chip background
- Connection chip background (slightly deeper variant)
- "First step this week" alert left border
- Some card hover states (subtle purple glow)

Experience-area chips use a neutral Bootstrap secondary color, intentionally less vivid, so the eye lands on the green and purple categories first.

### Custom CSS additions

Kept minimal. Beyond the boilerplate's `_accent.scss`:

- A `.chip-tag` class for chip rendering: rounded pill, padding, X button on hover, color variants per category (`.chip-tag--skill`, `.chip-tag--interest`, `.chip-tag--connection`, `.chip-tag--experience`)
- A `.project-card` class adding 16px corner radius and a warm-tinted background (`#1a1f0e` in dark mode, slightly green-tinted to differentiate from the boilerplate's neutral card)
- A `.first-step-alert` class for the left-bordered alert with the secondary accent

No bento grid, no kanban columns, no dense tables. The result feels like an inventory plus a curated card spread, not a project-management tool.

---

*v1.0 - CapacityMap Demo demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
