import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// Replaces a text input with a themed calendar + time picker. The submitted
// value stays "Y-m-d H:i" (parsed server-side in the org's time zone) while
// the visible input shows a friendlier format.
export default class extends Controller {
  connect() {
    this.picker = flatpickr(this.element, {
      enableTime: true,
      dateFormat: "Y-m-d H:i",
      altInput: true,
      altFormat: "M j, Y h:i K",
      time_24hr: false,
      minuteIncrement: 15,
      disableMobile: true
    })
  }

  disconnect() {
    this.picker?.destroy()
  }
}
