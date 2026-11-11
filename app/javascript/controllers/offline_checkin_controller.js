import { Controller } from "@hotwired/stimulus"
import { enqueue, flush } from "lib/checkin_queue"

// Formulário de check-in do aluno. Com conexão, o envio segue normal pelo
// Turbo. Sem conexão (ou se a requisição cair no meio), o pedido é guardado
// no aparelho, com o horário do clique, e reenviado automaticamente.
export default class extends Controller {
  submit(event) {
    this.stampTime()

    if (!navigator.onLine) {
      event.preventDefault()
      this.queue()
    }
  }

  // turbo:fetch-request-error: a requisição não chegou ao servidor.
  failed() {
    this.queue()
  }

  stampTime() {
    let input = this.element.querySelector("input[name=recorded_at]")
    if (!input) {
      input = document.createElement("input")
      input.type = "hidden"
      input.name = "recorded_at"
      this.element.appendChild(input)
    }
    input.value = new Date().toISOString()
  }

  queue() {
    enqueue({ url: this.element.action, fields: [ ...new FormData(this.element).entries() ] })

    const button = this.element.querySelector("button, input[type=submit]")
    if (button) {
      button.disabled = true
      const label = "Sem conexão: será enviado automaticamente"
      if (button.tagName === "BUTTON") button.textContent = label
      else button.value = label
    }

    flush()
  }
}
