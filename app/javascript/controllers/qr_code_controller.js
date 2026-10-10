import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { renderSVG } from "uqr"

// Desenha o QR code de check-in e recarrega a página periodicamente para
// gerar um código novo (cada código expira em poucos minutos, então uma foto
// antiga dele não serve para fazer check-in de longe).
export default class extends Controller {
  static targets = ["code", "countdown"]
  static values = { text: String, refreshSeconds: { type: Number, default: 60 } }

  connect() {
    this.codeTarget.innerHTML = renderSVG(this.textValue, { border: 2 })
    this.remaining = this.refreshSecondsValue
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    if (this.hasCountdownTarget) this.countdownTarget.textContent = this.remaining

    if (this.remaining-- <= 0) {
      clearInterval(this.timer)
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
