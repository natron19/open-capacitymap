# CapacityMap Demo — Build Task Index

Phased build plan for the CapacityMap Demo app on top of Open Demo Starter v2.0.

**Spec:** `docs/open-capacitymap/capacitymap-demo-spec.md`
**Boilerplate guides:** `docs/turbo-stimulus-patterns.md`, `docs/ai-templates.md`, `docs/ai-guardrails.md`, `docs/testing.md`, `docs/security.md`

---

## Implementation Notes (override the spec where noted)

- Accent variables go in `app/assets/stylesheets/application.css` — not a `.scss` file (Propshaft, no SCSS pipeline).
- Use `gemini-2.5-flash` everywhere the spec says `gemini-2.0-flash`.
- The `generate` action uses a standard redirect, not a Turbo Stream. The Generate button spinner uses a Turbo Frame wrapping the button only.

---

## Phase Summary

| Status | Phase | File | Goal |
|---|---|---|---|
| ✅ | 1 | [phase_1_branding.md](phase_1_branding.md) | App looks and feels like CapacityMap Demo before domain models exist |
| ✅ | 2 | [phase_2_data_models.md](phase_2_data_models.md) | `GiftInventory` and `ProjectIdea` tables, models, validations, factories, model specs |
| ✅ | 3 | [phase_3_crud.md](phase_3_crud.md) | Gift inventory CRUD, project idea list/show, navbar links wired — no AI yet |
| ✅ | 4 | [phase_4_chip_tags.md](phase_4_chip_tags.md) | Chip-style tag inputs on the inventory form via Stimulus |
| ✅ | 5 | [phase_5_ai_generation.md](phase_5_ai_generation.md) | Generate action calls Gemini, parses JSON, renders project card grid |
| ✅ | 6 | [phase_6_seed_data.md](phase_6_seed_data.md) | `db/seeds.rb` populated — demo runs end-to-end without a Gemini call |
| ✅ | 7 | [phase_7_polish.md](phase_7_polish.md) | Mobile layout, edge cases, hardcoded-string audit, dark mode check |
| ✅ | 8 | [phase_8_rspec.md](phase_8_rspec.md) | Full RSpec suite green, zero real API calls |
| ✅ | 9 | [phase_9_readme_and_publish.md](phase_9_readme_and_publish.md) | README updated, pre-publish security check passes |

---

## Completion Checklist

Before calling the demo done:

- [ ] `rails db:drop db:create db:migrate db:seed` succeeds with no errors.
- [ ] Full user journey works end to end: sign up → create inventory → generate projects → view project detail → edit inventory → regenerate.
- [ ] `bundle exec rspec` is green, no real Gemini API calls made.
- [ ] `/admin/ai_templates` shows the `capacitymap_projects_v1` template.
- [ ] No hardcoded strings — all app name/tagline references use `ENV.fetch`.
- [ ] No `console.log`, `binding.pry`, or `debugger` left in code.
- [ ] No plain JavaScript — every interaction uses Stimulus.
- [ ] All Turbo Stream updates use `update()` not `replace()`.
- [ ] `.env` is gitignored; `.env.example` has no real key values.
- [ ] Pre-publish security check from Phase 9 has passed with no findings.
