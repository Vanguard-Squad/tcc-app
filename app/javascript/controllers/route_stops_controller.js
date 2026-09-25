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
    const row = event.target.closest('[data-route-stops-target="stop"]')
    const destroyField = row.querySelector('[data-destroy-field]')

    // Paradas já salvas precisam ser enviadas com _destroy=1 para serem excluídas.
    if (destroyField) {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
  }
}
