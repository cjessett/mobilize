import { Controller } from "@hotwired/stimulus"

// Manages dynamic workflow trigger rows: shows only inputs relevant to the
// selected trigger.
export default class extends Controller {
  static targets = ["rows", "template"]

  add() {
    this.rowsTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.refreshAll()
  }

  remove(event) {
    event.target.closest("[data-trigger-row]").remove()
  }

  triggerChanged(event) {
    this.refresh(event.target.closest("[data-trigger-row]"))
  }

  connect() {
    this.refreshAll()
  }

  refreshAll() {
    this.rowsTarget.querySelectorAll("[data-trigger-row]").forEach((row) => this.refresh(row))
  }

  refresh(row) {
    const trigger = row.querySelector("[data-role=trigger]").value
    const show = {
      keyword_received: ["param"],
      tag_added: ["param"],
      form_submitted: ["param"],
      rsvp_created: ["param", "status"],
      event_attended: ["param"],
      donation_created: ["param"],
      link_clicked: ["param"],
      person_created: [],
      incoming_text: ["match_type", "value"],
      email_opened: ["param"]
    }[trigger] || []

    row.querySelectorAll("[data-role]").forEach((el) => {
      const role = el.dataset.role
      if (role === "trigger") return
      const visible = show.includes(role)
      el.classList.toggle("hidden", !visible)
      el.disabled = !visible
    })
  }
}
