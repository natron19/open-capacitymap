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

## Responsible AI

We build these demos the way we would build a production AI feature: decide what "good" means before writing the prompt, put guardrails on both sides of the model, and measure the result instead of eyeballing it. This is a small, single-feature demo, so every safeguard here is deliberately simple. Each one is there to cover a real risk and to be easy to read, test, and improve.

### Guardrails

**Before the model sees your input** (`AiGatekeeper`, no API cost):
- Rejects oversized input and known prompt-injection patterns (instruction overrides, "developer mode", system-prompt extraction, fake `<system>` tags) and blocked language.

**Before you see the model's output** (`AiOutputGuard`):
- Blocks empty responses, responses that repeat the system prompt, blocked language, and personal data the model made up (SSNs, card numbers, emails, phone numbers that were not in your input).
- `capacitymap_projects_v1` must return valid JSON with `projects`, or the response is not shown.

**Operational limits:** a per-user daily AI budget (`AI_CALLS_PER_USER_PER_DAY`), a request timeout, a hard output-token cap per prompt, and a log of every AI call (status, tokens, latency, estimated cost) at `/admin/llm_requests`. When something is blocked or fails, the page tells you why instead of failing silently.

### How we evaluate it

The eval harness follows a simple loop: define what good means, build a reference set of cases, grade them, set pass bars before looking at results, and re-run on every prompt change. Details are in [`docs/ai-evals.md`](docs/ai-evals.md).

| What we check | How | Run it |
|---|---|---|
| Guardrails catch attacks and leave normal input alone | Offline attack and look-alike suite, no API cost | `bin/rails evals:guardrails` |
| Output has the right shape | Code checks: required fields, counts, lengths | `bin/rails evals:run` |
| Output is actually good | An LLM judge scores each case 1–5 against a written rubric, after first proving it agrees with human-labeled examples | `bin/rails evals:run` |
| Latency, cost, and error rate | Read from the request log for each eval case | `bin/rails evals:run` |
| The real feature works in a browser | Headless Chrome walks the main AI feature, plus a blocked-input journey | Maintainer's fleet test harness, run before releases |

This app has 7 eval cases (typical, edge-case, adversarial, and benign look-alike inputs). The judge scores it on:

- **Accurate:** Every gift named in gifts_used appears in the contributor's inventory, and each project plainly uses the gifts it claims.
- **Useful:** Projects are specific and realistic for this organization, with names a coordinator could put on a sign-up sheet and a first step that fits in 30 minutes.
- **Steerable:** Every time_commitment stays within the contributor's stated weekly hours and no project contradicts the organization's mission.

**Current status (October 2026):** the guardrail suite passes: 11/11 input attacks and 7/7 output attacks blocked, with no false positives (12/12 and 6/6 benign cases allowed). Live-model eval baselines are being run next and will be published here. Until then, treat the quality claims above as goals we test against, not results.

### What this demo does and doesn't do

**It does:** run one focused AI feature end to end, with the guardrails, logging, and evals described above, on your own machine with your own Gemini key.

**It doesn't (yet):**
- Guarantee correct output. Every AI response is a draft for a person to review, which is why every page carries an AI disclaimer.
- Catch every attack. The input and output guards are pattern-based. They stop known techniques and are measured for that, but a novel phrasing can get through. That is why the output guard and the evals exist as a second layer.
- Scrub personal data from what you type. Don't paste anything sensitive into a local demo.
- Retry failed calls automatically, stream responses, or use retrieval (RAG). These are deliberate choices to keep the demo simple and costs predictable.

## Contributing and feedback

This project is open source and we want it to be useful to real people. Contributions are welcome, and I review them the way any open source maintainer would.

- **Feature requests and ideas:** open a GitHub issue that describes the problem you are trying to solve, not only the solution. Examples of the outputs you wish you got are especially helpful.
- **Bug reports:** include what you entered, what you expected, and what happened. For AI quality problems, the output itself is the most useful evidence.
- **Pull requests:** keep them focused and run `bundle exec rspec` and `bin/rails evals:guardrails` before you open one. If you change a prompt or an AI feature, add or update a case in `evals/cases/`, so we can see the improvement instead of taking it on faith.
- **Reviews:** I read every issue and review every pull request personally. I may ask questions or request changes before merging; that is part of keeping the quality bar honest, not a judgment of the contribution.
- **Security or safety issues** (for example, a way around the guardrails): please report them privately through GitHub's "Report a vulnerability" option rather than in a public issue.

---

## Cost

All templates use `gemini-2.5-flash`, which has a generous free tier. A user running the demo locally will not incur charges under typical use.

---

## License

MIT — see [LICENSE](LICENSE)
