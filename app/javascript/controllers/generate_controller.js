import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { cancelPath: String }

  start() {
    const btn = this.element.querySelector("button[type=submit]")
    if (!btn) return

    btn.disabled = true
    btn.innerHTML =
      '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Generating…'

    const cancel = document.createElement("a")
    cancel.href = this.cancelPathValue
    cancel.className = "btn btn-sm btn-outline-secondary ms-3"
    cancel.setAttribute("data-turbo-frame", "_top")
    cancel.textContent = "Cancel"
    this.element.appendChild(cancel)
  }
}
