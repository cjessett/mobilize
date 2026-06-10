import { Controller } from "@hotwired/stimulus"

// Manages dynamic segment condition rows. Each row shows only the inputs
// relevant to its selected condition type.
export default class extends Controller {
  static targets = ["rows", "template"]

  add() {
    const node = this.templateTarget.content.cloneNode(true)
    this.rowsTarget.appendChild(node)
    this.refreshAll()
  }

  remove(event) {
    event.target.closest("[data-condition-row]").remove()
  }

  typeChanged(event) {
    this.refresh(event.target.closest("[data-condition-row]"))
  }

  refreshAll() {
    this.rowsTarget.querySelectorAll("[data-condition-row]").forEach((row) => this.refresh(row))
  }

  connect() {
    this.refreshAll()
  }

  refresh(row) {
    const type = row.querySelector("[data-role=type]").value
    const show = {
      field: ["field", "op", "value"],
      custom_field: ["key", "op", "value"],
      tag: ["tag-op", "tag"],
      chapter: ["chapter"]
    }[type] || []

    row.querySelectorAll("[data-role]").forEach((el) => {
      const role = el.dataset.role
      if (role === "type") return
      const visible = show.includes(role)
      el.classList.toggle("hidden", !visible)
      el.disabled = !visible
    })
  }
}
