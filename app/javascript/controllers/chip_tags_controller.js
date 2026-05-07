import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "chips"]
  static values  = {
    min:      { type: Number, default: 1 },
    max:      { type: Number, default: 20 },
    category: { type: String, default: "skill" }
  }

  connect() {
    this._submitListener = (e) => this.validateOnSubmit(e)
    this.element.closest("form").addEventListener("submit", this._submitListener)

    const existing = JSON.parse(this.hiddenTarget.value || "[]")
    existing.forEach(tag => this.addChip(tag))
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this._submitListener)
  }

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

  removeChip(event) {
    event.currentTarget.closest("[data-chip-text]").remove()
    this.updateHidden()
    this.dispatch("change")
  }

  addChip(text) {
    const chip = document.createElement("span")
    chip.className = `chip-tag chip-tag--${this.categoryValue} me-1 mb-1`
    chip.dataset.chipText = text
    chip.innerHTML = `${this.escapeHtml(text)} <span class="chip-remove" data-action="click->chip-tags#removeChip">&times;</span>`
    this.chipsTarget.appendChild(chip)
  }

  updateHidden() {
    const tags = [...this.chipsTarget.querySelectorAll("[data-chip-text]")].map(el => el.dataset.chipText)
    this.hiddenTarget.value = JSON.stringify(tags)
  }

  validateOnSubmit(event) {
    const count    = this.chipsTarget.querySelectorAll("[data-chip-text]").length
    const feedback = this.element.querySelector(".invalid-feedback")
    const invalid  = count < this.minValue || count > this.maxValue

    this.inputTarget.classList.toggle("is-invalid", invalid)
    if (feedback) feedback.style.display = invalid ? "block" : "none"
    if (invalid) event.preventDefault()
  }

  escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
