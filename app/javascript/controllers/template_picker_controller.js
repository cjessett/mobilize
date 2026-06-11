import { Controller } from "@hotwired/stimulus"

// Copies the selected template's body (stored on the option's data-body)
// into the associated textarea, then resets the select.
export default class extends Controller {
  static targets = ["body"]

  apply(event) {
    const option = event.target.selectedOptions[0]
    if (!option || !option.dataset.body) return

    this.bodyTarget.value = option.dataset.body
    this.bodyTarget.dispatchEvent(new Event("input", { bubbles: true }))
    event.target.value = ""
  }
}
