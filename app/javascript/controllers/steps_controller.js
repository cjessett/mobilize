import { Controller } from "@hotwired/stimulus"

// Manages the workflow step builder: dynamic rows (including router branches
// with one level of nested steps), showing only inputs relevant to each
// action, and rewriting input names into an indexed tree on submit so the
// server can rebuild nesting (workflow[steps][0][branches][1][steps][0][...]).
export default class extends Controller {
  static targets = ["rows", "template", "branchTemplate", "nestedTemplate"]

  add() {
    this.rowsTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.refreshAll()
  }

  remove(event) {
    event.target.closest("[data-step-row]").remove()
  }

  addBranch(event) {
    const row = event.target.closest("[data-step-row]")
    row.querySelector("[data-branches-rows]").appendChild(this.branchTemplateTarget.content.cloneNode(true))
    this.refreshAll()
  }

  removeBranch(event) {
    event.target.closest("[data-branch-row]").remove()
  }

  addNestedStep(event) {
    const branch = event.target.closest("[data-branch-row]")
    branch.querySelector("[data-branch-steps]").appendChild(this.nestedTemplateTarget.content.cloneNode(true))
    this.refreshAll()
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
      send_sms: ["sms_template", "body", "body_meta"],
      send_email: ["subject", "body"],
      add_tag: ["tag_name"],
      remove_tag: ["tag_name"],
      wait: ["duration_minutes"],
      notify_member: ["email", "channel"],
      update_custom_field: ["key", "value"],
      webhook: ["url"],
      rsvp_person_to_event: ["event_id"],
      router: ["mode", "branches"],
      send_instagram_dm: ["body", "body_meta", "button_text", "button_payload", "button_url"]
    }[action] || []

    row.querySelectorAll("[data-role]").forEach((el) => {
      const role = el.dataset.role
      if (role === "action") return
      if (el.closest("[data-step-row]") !== row) return // belongs to a nested row
      const visible = show.includes(role)
      el.classList.toggle("hidden", !visible)
      if ("disabled" in el) el.disabled = !visible
    })
  }

  // Assigns indexed names just before submit so Rails receives the tree.
  reindex() {
    const rows = [...this.rowsTarget.children].filter((el) => el.matches("[data-step-row]"))
    rows.forEach((row, i) => this.nameRow(row, `workflow[steps][${i}]`))
  }

  nameRow(row, prefix) {
    const fields = ["action", "subject", "body", "tag_name", "duration_minutes", "email", "channel", "key", "value", "url", "event_id", "mode", "button_text", "button_payload", "button_url"]
    row.querySelectorAll("[data-role]").forEach((el) => {
      if (el.closest("[data-step-row]") !== row) return
      if (!fields.includes(el.dataset.role) || !("name" in el)) return
      el.name = `${prefix}[${el.dataset.role}]`
    })

    const branchRows = [...row.querySelectorAll("[data-branch-row]")].filter((b) => b.closest("[data-step-row]") === row)
    branchRows.forEach((branch, bi) => {
      branch.querySelectorAll("[data-branch-field]").forEach((el) => {
        if (el.closest("[data-branch-row]") !== branch) return
        el.name = `${prefix}[branches][${bi}][${el.dataset.branchField}]`
      })
      const container = branch.querySelector("[data-branch-steps]")
      const nested = container ? [...container.children].filter((el) => el.matches("[data-step-row]")) : []
      nested.forEach((nrow, k) => this.nameRow(nrow, `${prefix}[branches][${bi}][steps][${k}]`))
    })
  }
}
