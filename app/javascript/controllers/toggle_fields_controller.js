import { Controller } from "@hotwired/stimulus"

// Alterna entre dois blocos de campos ("existente" vs "novo"), desabilitando
// os campos do bloco escondido para que não sejam enviados no submit.
export default class extends Controller {
  static targets = ["existing", "new"]
  static values = { mode: { type: String, default: "existing" } }

  connect() {
    if (this.modeValue === "new") {
      this.showNew()
    } else {
      this.showExisting()
    }
  }

  showExisting() {
    this.reveal(this.existingTarget)
    this.conceal(this.newTarget)
  }

  showNew() {
    this.reveal(this.newTarget)
    this.conceal(this.existingTarget)
  }

  reveal(container) {
    container.hidden = false
    this.fields(container).forEach((field) => { field.disabled = false })
  }

  conceal(container) {
    container.hidden = true
    this.fields(container).forEach((field) => { field.disabled = true })
  }

  fields(container) {
    return container.querySelectorAll("input, select")
  }
}
