import { Controller } from "@hotwired/stimulus"

// Manages dynamic workflow step rows: shows only inputs relevant to the
// selected action.
export default class extends Controller {
  static targets = ["rows", "template"]

  add() {
    this.rowsTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.refreshAll()
  }

  remove(event) {
    event.target.closest("[data-step-row]").remove()
  }

  actionChanged(event) {
    this.refresh(event.target.closest("[data-step-row]"))
  }

  connect() {
    this.refreshAll()
  }

  refreshAll() {
    this.rowsTarget.querySelectorAll("[data-step-row]").forEach((row) => this.refresh(row))
  }

  refresh(row) {
    const action = row.querySelector("[data-role=action]").value
    const show = {
      send_sms: ["body"],
      send_email: ["subject", "body"],
      add_tag: ["tag_name"],
      remove_tag: ["tag_name"],
      wait: ["duration_minutes"],
      notify_member: ["email"]
    }[action] || []

    row.querySelectorAll("[data-role]").forEach((el) => {
      const role = el.dataset.role
      if (role === "action") return
      const visible = show.includes(role)
      el.classList.toggle("hidden", !visible)
      el.disabled = !visible
    })
  }
}
