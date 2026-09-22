import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipCode", "street", "neighborhood", "city"]

  async lookup() {
    const digits = this.zipCodeTarget.value.replace(/\D/g, "")
    this.zipCodeTarget.setCustomValidity("")

    if (digits.length !== 8) return

    try {
      const response = await fetch(`https://viacep.com.br/ws/${digits}/json/`)
      const data = await response.json()

      if (data.erro) {
        this.zipCodeTarget.setCustomValidity("CEP não encontrado")
        this.zipCodeTarget.reportValidity()
        return
      }

      if (this.hasStreetTarget) this.streetTarget.value = data.logradouro
      if (this.hasNeighborhoodTarget) this.neighborhoodTarget.value = data.bairro
      if (this.hasCityTarget) this.cityTarget.value = data.localidade
    } catch {
      return
    }
  }
}
