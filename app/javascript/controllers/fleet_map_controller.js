import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as L from "leaflet"
import { createConsumer } from "@rails/actioncable"
import { createMap, BusMarker, FIT_OPTIONS } from "lib/route_map"

// Mapa da frota no painel da gestão: todos os ônibus em viagem, com a placa
// ao lado, andando em tempo real.
export default class extends Controller {
  static values = { buses: Array }

  connect() {
    this.map = createMap(this.element)
    this.markers = new Map()
    this.consumer = createConsumer()

    const bounds = L.latLngBounds([])
    this.busesValue.forEach((bus) => {
      const marker = new BusMarker(this.map, { label: bus.plate, permanent: true })
      this.markers.set(bus.vehicleId, marker)
      if (bus.lat != null) {
        marker.moveTo(bus)
        bounds.extend([ bus.lat, bus.lng ])
      }

      this.consumer.subscriptions.create(
        { channel: "TripChannel", vehicle_id: bus.vehicleId },
        { received: (data) => this.received(bus.vehicleId, data) }
      )
    })

    if (bounds.isValid()) this.map.fitBounds(bounds, { ...FIT_OPTIONS, maxZoom: 14 })
    else this.map.setView([ -23.55, -46.65 ], 11)
  }

  disconnect() {
    this.consumer?.disconnect()
    this.markers?.forEach((marker) => marker.remove())
    this.map?.remove()
    this.map = null
  }

  received(vehicleId, data) {
    if (data.event === "position" && data.lat != null && this.map) {
      this.markers.get(vehicleId)?.moveTo({ lat: data.lat, lng: data.lng })
    } else if (data.event === "started" || data.event === "finished") {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
