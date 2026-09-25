import { Controller } from "@hotwired/stimulus"

// Permite ao motorista reordenar as paradas por arrastar-e-soltar.
// A cada mudança, reescreve os inputs ocultos com a ordem atual dos ids.
export default class extends Controller {
  static targets = ["list", "item", "hiddenFields"]

  connect() {
    this.dragging = null
    this.syncHiddenFields()
  }

  dragStart(event) {
    this.dragging = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.dragging || target === this.dragging) return

    const rect = target.getBoundingClientRect()
    const after = (event.clientY - rect.top) / rect.height > 0.5
    target.parentNode.insertBefore(this.dragging, after ? target.nextSibling : target)
  }

  drop(event) {
    event.preventDefault()
    this.dragging = null
    this.syncHiddenFields()
  }

  syncHiddenFields() {
    this.hiddenFieldsTarget.innerHTML = ""
    this.itemTargets.forEach((item) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "stop_ids[]"
      input.value = item.dataset.id
      this.hiddenFieldsTarget.appendChild(input)
    })
  }
}
