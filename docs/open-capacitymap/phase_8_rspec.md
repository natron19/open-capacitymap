# Phase 8 — RSpec Test Suite

**Goal:** The full RSpec suite is green with zero real Gemini API calls. All new code is covered by model specs and request specs. No `GEMINI_API_KEY` env var is needed to run the suite.

**Prerequisite:** Phases 2–7 complete. The factories, models, controllers, and request specs from earlier phases exist. This phase reviews coverage, fills gaps, and confirms the full suite runs clean.

---

## Context / Files to Read First

- `docs/testing.md` — RSpec conventions, `sign_in_as` helper, `gemini_returns`/`gemini_raises` helpers, factory usage
- `docs/open-capacitymap/capacitymap-demo-spec.md` §9 (RSpec outline)
- `spec/support/gemini_test_double.rb` — stub helpers; confirm the file exists and is loaded
- `spec/support/authentication_helpers.rb` — `sign_in_as` helper; confirm the file exists
- `spec/factories/gift_inventories.rb` and `spec/factories/project_ideas.rb` — review factories for completeness

---

## Tasks

### 8.1 — Confirm Support Files Are in Place

Verify the following exist and are required in `spec/rails_helper.rb`:

- `spec/support/gemini_test_double.rb` — provides `gemini_returns(text)` and `gemini_raises(error_class)`.
- `spec/support/authentication_helpers.rb` — provides `sign_in_as(user)`.
- `spec/support/factory_bot.rb` — includes `FactoryBot::Syntax::Methods`.

If any are missing, create them following the patterns in `docs/testing.md`.

### 8.2 — Verify Model Specs (from Phase 2)

Run:

```bash
bundle exec rspec spec/models/gift_inventory_spec.rb spec/models/project_idea_spec.rb --format documentation
```

All examples from Phase 2 must pass. If any are pending or failing, fix the underlying model or spec now.

### 8.3 — Complete `spec/requests/gift_inventories_spec.rb`

The Phase 3 and Phase 5 additions should cover these examples. Audit for completeness — add any missing:

- [ ] `GET /gift_inventories/new` unauthenticated → redirect to sign in
- [ ] `POST /gift_inventories` unauthenticated → redirect to sign in
- [ ] `GET /gift_inventories/current` with no inventory → redirect to `new_gift_inventory_path`
- [ ] `GET /gift_inventories/current` with existing inventory → redirect to inventory show page
- [ ] `POST /gift_inventories` valid params → creates inventory, redirects to show
- [ ] `POST /gift_inventories` too-few skills (< 5) → 422 with form errors
- [ ] `GET /gift_inventories/:id` another user's inventory → 404
- [ ] `GET /gift_inventories/:id/edit` another user's inventory → 404
- [ ] `POST /gift_inventories/:id/generate` valid stubbed response → creates 5–7 `ProjectIdea` records
- [ ] `POST /gift_inventories/:id/generate` valid response → creates 1 `LlmRequest` with `status: "success"` and `template_name: "capacitymap_projects_v1"`
- [ ] `POST /gift_inventories/:id/generate` valid response → replaces existing batch (old records gone)
- [ ] `POST /gift_inventories/:id/generate` malformed JSON → redirect with alert, zero new `ProjectIdea` records
- [ ] `POST /gift_inventories/:id/generate` `GeminiService::TimeoutError` → redirect with timeout alert
- [ ] `POST /gift_inventories/:id/generate` another user's inventory → 404

### 8.4 — Complete `spec/requests/project_ideas_spec.rb`

- [ ] `GET /project_ideas` unauthenticated → redirect to sign in
- [ ] `GET /project_ideas` signed in with no projects → 200, empty state
- [ ] `GET /project_ideas` signed in → shows only current user's projects (create a second user's projects and confirm they don't appear)
- [ ] `GET /project_ideas/:id` another user's project → 404
- [ ] `GET /project_ideas/:id` own project → 200, renders `gemini_raw` content

### 8.5 — Run the Full Suite

```bash
bundle exec rspec --format documentation
```

Expected outcome:
- All examples pass (green).
- No pending examples (remove `pending` or `skip` markers).
- No warnings about missing factories or associations.
- No real Gemini API calls (confirm by running without `GEMINI_API_KEY` set — remove it from `.env` temporarily or run `GEMINI_API_KEY= bundle exec rspec`).

---

## Manual Tests

- [ ] `bundle exec rspec --format documentation` — review output line by line for any warnings, deprecations, or pending examples.
- [ ] `GEMINI_API_KEY= bundle exec rspec` — confirm the suite passes without an API key (all Gemini calls are stubbed).
- [ ] Confirm no test makes a real HTTP call to Google's API (check test output for any `Net::HTTP` or timeout messages).

---

## Acceptance Criteria

- [ ] All model specs pass: `bundle exec rspec spec/models/`.
- [ ] All request specs pass: `bundle exec rspec spec/requests/`.
- [ ] The full suite passes: `bundle exec rspec` — all green, zero pending.
- [ ] Suite runs successfully with `GEMINI_API_KEY` unset.
- [ ] No `turbo_stream.replace` in any view (run `grep -r "turbo_stream\.replace" app/views/`).
- [ ] No `console.log`, `binding.pry`, or `debugger` in any file (run `grep -r "console\.log\|binding\.pry\|debugger" app/`).
