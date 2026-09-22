import { Controller } from "@hotwired/stimulus"

// Adiciona/remove paradas dinamicamente no formulário de rota. A ordem das
// paradas (step) é definida pela posição na lista, não digitada pelo usuário.
export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()

    const index = Date.now()
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    event.target.closest('[data-route-stops-target="stop"]').remove()
  }
}
