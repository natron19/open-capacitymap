# Phase 4 — Chip Tags Stimulus Controller

**Goal:** Chip-style tag inputs work on the inventory form. JSON encoding updates correctly on every change. Min/max validation fires on form submit and prevents submission with a helpful error message.

**Prerequisite:** Phase 3 complete — the inventory form exists and renders.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §6 (Stimulus controller: `chip_tags_controller.js`)
- `docs/turbo-stimulus-patterns.md` — Stimulus target, value, and action descriptor conventions; how to register a new controller
- `app/javascript/controllers/index.js` — where to register the new controller
- `app/views/gift_inventories/_form.html.erb` — the Phase 3 form to update

---

## Tasks

### 4.1 — Create `app/javascript/controllers/chip_tags_controller.js`

**Targets:** `input` (visible text field), `hidden` (hidden JSON field), `chips` (chip container div).

**Values:** `minValue` (Number, default 1), `maxValue` (Number, default 20).

**Lifecycle:**
- `connect()` — parse `hiddenTarget.value` as JSON; render existing chips from that array; attach a `submit` listener to the closest `form` element.
- `disconnect()` — remove the submit listener.

**Key behaviors:**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "chips"]
  static values  = { min: { type: Number, default: 1 }, max: { type: Number, default: 20 } }

  connect() {
    this._submitListener = (e) => this.validateOnSubmit(e)
    this.element.closest("form").addEventListener("submit", this._submitListener)
    const existing = JSON.parse(this.hiddenTarget.value || "[]")
    existing.forEach(tag => this.addChip(tag))
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this._submitListener)
  }

  // Called via data-action="keydown->chip-tags#onKeydown"
  onKeydown(event) {
    if (event.key !== "Enter" && event.key !== ",") return
    event.preventDefault()
    const value = this.inputTarget.value.trim()
    if (!value) return
    const current = JSON.parse(this.hiddenTarget.value || "[]")
    if (current.includes(value)) { this.inputTarget.value = ""; return }
    if (current.length >= this.maxValue) return
    this.addChip(value)
    this.updateHidden()
    this.inputTarget.value = ""
    this.dispatch("change")
  }

  addChip(text) {
    const chip = document.createElement("span")
    chip.className = `chip-tag chip-tag--${this.element.dataset.chipTagsCategoryValue || "skill"} me-1 mb-1`
    chip.dataset.chipText = text
    chip.innerHTML = `${text} <span class="chip-remove" data-action="click->chip-tags#removeChip">×</span>`
    this.chipsTarget.appendChild(chip)
  }

  removeChip(event) {
    event.currentTarget.closest("[data-chip-text]").remove()
    this.updateHidden()
    this.dispatch("change")
  }

  updateHidden() {
    const tags = [...this.chipsTarget.querySelectorAll("[data-chip-text]")].map(el => el.dataset.chipText)
    this.hiddenTarget.value = JSON.stringify(tags)
  }

  validateOnSubmit(event) {
    const count = this.chipsTarget.querySelectorAll("[data-chip-text]").length
    const feedback = this.element.querySelector(".invalid-feedback")
    if (count < this.minValue || count > this.maxValue) {
      event.preventDefault()
      this.inputTarget.classList.add("is-invalid")
      if (feedback) feedback.style.display = "block"
    } else {
      this.inputTarget.classList.remove("is-invalid")
      if (feedback) feedback.style.display = "none"
    }
  }
}
```

### 4.2 — Register the Controller

In `app/javascript/controllers/index.js`, import and register:

```javascript
import ChipTagsController from "./chip_tags_controller"
application.register("chip-tags", ChipTagsController)
```

### 4.3 — Update `app/views/gift_inventories/_form.html.erb`

Replace each textarea-based array field with the chip-tag pattern. The pattern for each field:

```erb
<%# Skills — 5 to 8 chips %>
<div class="mb-3"
     data-controller="chip-tags"
     data-chip-tags-min-value="5"
     data-chip-tags-max-value="8"
     data-chip-tags-category-value="skill">
  <label class="form-label">Skills you enjoy using</label>
  <div data-chip-tags-target="chips" class="d-flex flex-wrap mb-1"></div>
  <input type="text"
         data-chip-tags-target="input"
         data-action="keydown->chip-tags#onKeydown"
         class="form-control"
         placeholder="Type a skill and press Enter">
  <%= f.hidden_field :skills, data: { "chip-tags-target": "hidden" },
        value: gift_inventory.skills.presence || "[]" %>
  <div class="invalid-feedback">Skills must have between 5 and 8 entries.</div>
</div>
```

Repeat for `interests` (min 3, max 5, category `interest`), `connections` (min 3, max 5, category `connection`), and `experience_areas` (min 1, max 20, category `experience`).

**Weekly hours** — replace `number_field` with a range slider. Reuse the same pattern as the boilerplate's temperature slider if one exists; otherwise:

```erb
<div class="mb-3">
  <label class="form-label">
    Hours per week: <strong id="weekly-hours-display"><%= gift_inventory.weekly_hours || 6 %></strong>
  </label>
  <%= f.range_field :weekly_hours, min: 1, max: 40, step: 1,
        class: "form-range",
        data: { action: "input->chip-tags#noop",
                oninput: "document.getElementById('weekly-hours-display').textContent=this.value" } %>
</div>
```

Note: the range slider's `oninput` attribute is intentional inline data binding — an acceptable exception to the no-inline-JS rule because it is a single property binding with no logic, equivalent to a Stimulus value target. Document this with a comment in the view.

---

## Manual Tests

- [ ] Visit the new inventory form — type a skill and press Enter, confirm chip renders with lime-green styling.
- [ ] Add 8 skills — confirm the 9th is silently rejected (Enter does nothing).
- [ ] Click the × on a chip — confirm it disappears.
- [ ] Submit the form with fewer than 5 skills — confirm `invalid-feedback` appears inline, form does not submit.
- [ ] Submit a valid form — confirm all chip values arrive in the controller as a JSON array (check rails console or flash notice).
- [ ] Drag the weekly hours slider from 1 to 40 — confirm the number readout updates live.
- [ ] Edit an existing inventory — confirm existing chips pre-render from the saved JSON values.
- [ ] Confirm interest chips are purple, skill chips are lime-green, connection chips are darker purple, experience chips are neutral.

---

## Acceptance Criteria

- [ ] `chip_tags_controller.js` exists and is registered in `index.js`.
- [ ] Form renders chip inputs for skills, interests, connections, and experience areas.
- [ ] Enter/comma adds a chip; × removes it; hidden field stays in sync.
- [ ] Min/max validation fires on submit and prevents submission with an inline error message.
- [ ] No plain `addEventListener` calls outside of `connect()`/`disconnect()` lifecycle.
- [ ] No `<script>` tags in views — range slider oninput is documented as an accepted exception.
- [ ] Edit page pre-populates chips from saved JSON.
