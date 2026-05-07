# Phase 9 — README & Pre-Publish

**Goal:** The README explains the demo clearly to a stranger. The pre-publish security check passes with no findings. The repo is ready to make public on GitHub.

**Prerequisite:** Phases 1–8 complete. Full suite is green. All manual test checklists pass.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §11 (README additions)
- `docs/prompts/pre-publish-security-check.md` — the full security check prompt to run
- `README.md` — the current boilerplate README to update
- `.gitignore` — must cover `.env`, `master.key`, `*.key`, `log/`, `tmp/`
- `.env.example` — must have only placeholder values

---

## Tasks

### 9.1 — Update `README.md`

The boilerplate README has sections for Stack, Setup, License, AI Safety Posture, and About the Author. Add or replace the following sections:

**App Name and Tagline** (at the top, below the H1):

> **CapacityMap Demo**
>
> Inventory your gifts. Get a list of meaningful projects where they are needed.

**One-paragraph description:**

> CapacityMap Demo is an open source Rails 8 plus Gemini app that demonstrates the matching engine at the heart of CapacityMap, a community capacity platform. You list 5 to 8 skills you enjoy using, 3 to 5 interests, your weekly availability, 3 to 5 connections you could activate, your experience areas, and a paragraph about your organization. Gemini returns 5 to 7 specific projects where those gifts could be put to use, naming explicitly which gifts each project draws on.

**Screenshot placeholder** (add early in the README):

```
**Screenshot:** _Add screenshot of the inventory form and the generated project card grid here._
```

**Why I built this:**

> Most volunteer-matching software starts from the coordinator's task list and asks contributors to pick from it. That model treats people as resources to deploy. I wanted to see what it felt like to invert it: start from what someone brings, then surface the projects only they could meaningfully run.
>
> CapacityMap Demo is one feature from a larger multi-tenant SaaS suite I am building. The production version is multi-tenant with team collaboration, recognition workflows, contribution tracking, and a four-stage G.I.F.T. dashboard. Find the production app at [capacitymap.app](https://capacitymap.app).
>
> This demo is open source under the MIT license. Clone it, run it, edit the prompt, see how it changes the suggestions. The whole codebase is small enough to read in an afternoon.

**Editable prompt** section:

> The Gemini prompt for this demo lives in `/admin/ai_templates`, not in the code. Sign in as the seeded admin user (`demo@example.com` / `password123`), open the `capacitymap_projects_v1` template, and edit the system prompt or the user prompt template. The admin UI has a live test panel: type sample variable values, click Test, and see Gemini's response inline before saving. This is the best way to feel how a prompt change shifts the suggestions.

**Demo credentials** (in the Setup section):

> Two accounts are seeded:
> - **Admin / demo user:** `demo@example.com` / `password123` — has a sample gift inventory and 6 generated project cards.
> - **Viewer:** `viewer@example.com` / `password123` — no inventory; shows the empty state.

**App-specific setup** (no extra steps beyond boilerplate):

> No setup beyond `bin/setup`. The only required environment variable is `GEMINI_API_KEY` (get one free at [aistudio.google.com](https://aistudio.google.com)). Copy `.env.example` to `.env` and fill it in.

### 9.2 — README Self-Review

Read the README as if you are a stranger who just cloned the repo. Verify:

- The value proposition is clear in the first paragraph.
- Setup steps are complete and in the right order.
- Demo credentials are visible.
- The "Editable prompt" section explains the admin panel.
- No internal infrastructure details, internal URLs, or real email addresses are mentioned.

---

## Pre-Publish Security Check

**Run this check before making the repository public.** Copy the prompt below into a Claude Code conversation with this repo as the working directory. Review every finding and fix all issues before publishing.

---

```
Perform a security review of this Rails app before it's published publicly on GitHub. Check every item below and report findings — safe or risky — with file path and line number for anything flagged.

**1. Hardcoded secrets**
Scan all files for hardcoded API keys, passwords, tokens, or secrets. Check: `.env`, `config/credentials.yml.enc`, `config/master.key`, `config/database.yml`, `config/secrets.yml`, `config/initializers/`, any `.key` files, and any file in `.kamal/`.

**2. Gitignore coverage**
Read `.gitignore` and confirm it excludes:
- `.env` and `.env.*`
- `config/master.key` and all `*.key` files
- `config/credentials.yml.enc`
- `log/` and `tmp/`
Report any of the above that are NOT covered.

**3. `.env.example`**
Read it and confirm every value is a placeholder (e.g. `your_key_here`), not a real value.

**4. `config/database.yml`**
Check for hardcoded username, password, or host. Production values should use `ENV.fetch(...)`.

**5. `db/seeds.rb`**
Check for hardcoded credentials beyond any intentional demo passwords that are documented in the README.

**6. `config/environments/production.rb`**
Check for hardcoded secrets. All sensitive values should use `ENV.fetch(...)`.

**7. Gemfile**
Confirm the only gem source is `https://rubygems.org`. Flag any private gem servers or `git:` sources pointing to private repos.

**8. README**
Check that it doesn't expose internal infrastructure details (internal URLs, server names, real email addresses, internal team names).

**9. Log and tmp files**
Confirm `log/` and `tmp/` contain no tracked files with sensitive content.

**10. Git history**
Run `git log --oneline` and check if any commit message suggests a secret was ever committed (e.g. "add API key", "fix credentials"). If so, flag it — the history would need to be scrubbed before publishing.

For each finding, state: file path, line number (if applicable), what the risk is, and what action to take. Fix any issues you can directly; flag anything that requires a manual step (like rotating a key).
```

---

## After the Security Check

1. Fix every finding the check surfaces.
2. Re-run the check to confirm all findings are resolved.
3. Run `bundle exec rspec` one final time — confirm the suite is still green after any security fixes.
4. Review the final completion checklist in `docs/open-capacitymap/tasks.md`.

---

## Manual Tests

- [ ] Read the README cold (pretend you have never seen this project) — value prop is clear in under 30 seconds.
- [ ] Follow the README setup steps from scratch (on a clean branch or fresh clone) — confirm they work.
- [ ] The security check prompt above produces zero unresolved findings.
- [ ] `bundle exec rspec` is green after all security fixes.

---

## Acceptance Criteria

- [ ] README has all sections from spec §11: app name/tagline, description, "Why I built this", screenshot placeholder, "Editable prompt" section, demo credentials, setup steps.
- [ ] No internal infrastructure details or real email addresses in the README.
- [ ] Pre-publish security check has been run and all findings are resolved.
- [ ] `.gitignore` covers `.env`, `master.key`, `*.key`, `log/`, and `tmp/`.
- [ ] `.env.example` contains only placeholder values.
- [ ] `bundle exec rspec` is green.
- [ ] Full completion checklist in `tasks.md` is verified.
