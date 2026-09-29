import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { createConsumer } from "@rails/actioncable"

// Recarrega a página quando algo relevante da viagem muda (início, fim ou
// check-in de um aluno), sem reagir às atualizações de posição.
export default class extends Controller {
  static values = { vehicleId: Number }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TripChannel", vehicle_id: this.vehicleIdValue },
      { received: (data) => this.received(data) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  received(data) {
    if ([ "started", "finished", "checkin" ].includes(data.event)) {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
