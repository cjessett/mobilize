import { Controller } from "@hotwired/stimulus"

// Slide-over sidebar on mobile. The nav is always visible at md+ via CSS;
// below that it slides in from the left over a backdrop.
export default class extends Controller {
  static targets = ["menu", "backdrop"]

  toggle() {
    this.menuTarget.classList.toggle("-translate-x-full")
    this.backdropTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
  }
}
