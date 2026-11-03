import { Controller } from "@hotwired/stimulus"

// No app nativo os avisos viram toasts: somem sozinhos depois de alguns
// segundos ou com um toque. No navegador continuam fixos na página.
export default class extends Controller {
  static targets = ["message"]
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    if (!document.body.classList.contains("is-native")) return

    this.timer = setTimeout(() => this.messageTargets.forEach((message) => this.hide(message)), this.timeoutValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss(event) {
    if (!document.body.classList.contains("is-native")) return

    this.hide(event.currentTarget)
  }

  hide(message) {
    message.classList.add("is-leaving")
    message.addEventListener("animationend", () => message.remove(), { once: true })
  }
}
