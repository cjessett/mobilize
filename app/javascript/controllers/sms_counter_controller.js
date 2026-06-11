import { Controller } from "@hotwired/stimulus"

// Live SMS length feedback: characters, segments (GSM-7 vs UCS-2 encoding),
// and estimated cost per recipient. Merge tags expand per person, so this is
// an estimate.
const GSM7 =
  "@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?" +
  "¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑܧ¿abcdefghijklmnopqrstuvwxyzäöñüà"
const GSM7_EXTENDED = "^{}\\[~]|€"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { price: { type: Number, default: 0.0079 } }

  connect() {
    this.update()
  }

  update() {
    const text = this.inputTarget.value
    if (text.length === 0) {
      this.outputTarget.textContent = ""
      return
    }

    let gsm = true
    let units = 0
    for (const char of text) {
      if (GSM7.includes(char)) units += 1
      else if (GSM7_EXTENDED.includes(char)) units += 2
      else { gsm = false; break }
    }

    let segments
    if (gsm) {
      segments = units <= 160 ? 1 : Math.ceil(units / 153)
    } else {
      units = [...text].length
      segments = units <= 70 ? 1 : Math.ceil(units / 67)
    }

    const cost = (segments * this.priceValue).toFixed(3)
    const encoding = gsm ? "" : " · emoji/unicode"
    const plural = segments === 1 ? "" : "s"
    this.outputTarget.textContent = `${units} characters · ${segments} segment${plural}${encoding} · ~$${cost} per recipient`
  }
}
