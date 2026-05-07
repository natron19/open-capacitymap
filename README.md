# CapacityMap Demo

> Inventory your gifts. Get a list of meaningful projects where they are needed.

CapacityMap Demo is an open source Rails 8 plus Gemini app that demonstrates the matching engine at the heart of CapacityMap, a community capacity platform. You list 5 to 8 skills you enjoy using, 3 to 5 interests, your weekly availability, 3 to 5 connections you could activate, your experience areas, and a paragraph about your organization. Gemini returns 5 to 7 specific projects where those gifts could be put to use, naming explicitly which gifts each project draws on.

**Screenshot:** _Add screenshot of the inventory form and the generated project card grid here._

---

## Why I Built This

Most volunteer-matching software starts from the coordinator's task list and asks contributors to pick from it. That model treats people as resources to deploy. I wanted to see what it felt like to invert it: start from what someone brings, then surface the projects only they could meaningfully run.

CapacityMap Demo is one feature from a larger multi-tenant SaaS suite I am building. The production version is multi-tenant with team collaboration, recognition workflows, contribution tracking, and a four-stage G.I.F.T. dashboard. Find the production app at [capacitymap.app](https://capacitymap.app).

This demo is open source under the MIT license. Clone it, run it, edit the prompt, see how it changes the suggestions. The whole codebase is small enough to read in an afternoon.

---

## Setup

1. Clone this repo
2. Run `bin/setup`
3. Copy `.env.example` to `.env` and add your Gemini API key
4. `bin/rails server`
5. Visit http://localhost:3000

The only required environment variable is `GEMINI_API_KEY` — get one free at [aistudio.google.com](https://aistudio.google.com).

### Demo Credentials

Two accounts are seeded:

- **Admin / demo user:** `demo@example.com` / `password123` — has a sample gift inventory and 6 generated project cards.
- **Viewer:** `viewer@example.com` / `password123` — no inventory; shows the empty state.

---

## Editable Prompt

The Gemini prompt for this demo lives in `/admin/ai_templates`, not in the code. Sign in as the seeded admin user (`demo@example.com` / `password123`), open the `capacitymap_projects_v1` template, and edit the system prompt or the user prompt template. The admin UI has a live test panel: type sample variable values, click Test, and see Gemini's response inline before saving. This is the best way to feel how a prompt change shifts the suggestions.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"CapacityMap Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

---

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini 2.5 Flash via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

---

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page

**Deliberately omitted (with rationale):**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

See `app/services/ai_gatekeeper.rb` and `app/services/ai_budget_checker.rb` to extend.

---

## Cost

All templates use `gemini-2.5-flash`, which has a generous free tier. A user running the demo locally will not incur charges under typical use.

---

## License

MIT — see [LICENSE](LICENSE)
