import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as L from "leaflet"
import { createConsumer } from "@rails/actioncable"
import { drivingRoute, walkingRoute, haversine } from "lib/osrm"

const ETA_REFRESH_MS = 15000
const ARRIVED_METERS = 60
const FALLBACK_SPEED_MS = 8 // ~30 km/h, usado só antes da primeira resposta do OSRM
const PADDING = { padding: [ 30, 30 ] }

const tileUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"

// Mapa do aluno: casa, ponto de embarque, faculdade e o ônibus em tempo real
// (Action Cable), com tempo estimado de chegada ao destino atual.
export default class extends Controller {
  static targets = [ "map", "eta", "status" ]
  static values = {
    vehicleId: Number,
    tripActive: Boolean,
    home: Object,
    stop: Object,
    college: Object,
    target: Object,
    bus: Object,
    walk: Boolean
  }

  connect() {
    this.map = L.map(this.mapTarget)
    L.tileLayer(tileUrl, { attribution: "&copy; OpenStreetMap contributors" }).addTo(this.map)

    const bounds = []
    this.addPlace(this.homeValue, "#16a34a", "Sua casa", bounds)
    this.addPlace(this.stopValue, "#2563eb", "Seu ponto de embarque", bounds)
    this.addPlace(this.collegeValue, "#9333ea", "Faculdade", bounds)

    if (this.hasBus(this.busValue)) this.moveBus(this.busValue, bounds)
    if (bounds.length) this.map.fitBounds(bounds, PADDING)
    else this.map.setView([ -23.55, -46.65 ], 11)

    if (this.walkValue && this.homeValue.lat && this.stopValue.lat) this.drawWalkingRoute()

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TripChannel", vehicle_id: this.vehicleIdValue },
      { received: (data) => this.received(data) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
    this.map?.remove()
    this.map = null
  }

  received(data) {
    if (data.event === "started" || data.event === "finished") {
      Turbo.visit(window.location.href, { action: "replace" })
    } else if (data.event === "position" && this.tripActiveValue) {
      this.moveBus(data)
    }
  }

  hasBus(position) {
    return position && position.lat != null && position.lng != null
  }

  addPlace(place, color, label, bounds) {
    if (!this.hasBus(place)) return

    L.circleMarker([ place.lat, place.lng ], { radius: 9, color, fillColor: color, fillOpacity: 0.85 })
      .addTo(this.map).bindTooltip(label, { permanent: false })
    bounds.push([ place.lat, place.lng ])
  }

  async drawWalkingRoute() {
    const route = await walkingRoute([ this.homeValue, this.stopValue ])
    if (!route || !this.map) return

    L.polyline(route.path, { color: "#16a34a", weight: 4, dashArray: "6 8" }).addTo(this.map)
    this.setStatus(`Caminhada até o ponto: ~${Math.max(1, Math.round(route.duration / 60))} min (${Math.round(route.distance)} m)`)
  }

  moveBus(position, bounds = null) {
    if (!this.map) return

    const latlng = [ position.lat, position.lng ]

    if (this.busMarker) {
      this.busMarker.setLatLng(latlng)
    } else {
      this.busMarker = L.circleMarker(latlng, { radius: 11, color: "#dc2626", fillColor: "#dc2626", fillOpacity: 1, weight: 3 })
        .addTo(this.map).bindTooltip("Ônibus", { permanent: true, direction: "top" })
    }

    if (bounds) bounds.push(latlng)
    else if (!this.map.getBounds().contains(latlng)) this.fitAll(latlng)
    this.updateEta({ lat: position.lat, lng: position.lng })
  }

  fitAll(busLatLng) {
    const points = [ busLatLng ]
    for (const place of [ this.homeValue, this.stopValue, this.targetValue ]) {
      if (this.hasBus(place)) points.push([ place.lat, place.lng ])
    }
    this.map.fitBounds(points, PADDING)
  }

  async updateEta(bus) {
    if (!this.hasBus(this.targetValue)) return

    const target = this.targetValue
    const distance = haversine(bus, target)

    if (distance < ARRIVED_METERS) {
      this.showEta("Chegando agora")
      return
    }

    const now = Date.now()
    if (!this.lastEtaAt || now - this.lastEtaAt > ETA_REFRESH_MS) {
      this.lastEtaAt = now
      const route = await drivingRoute([ bus, target ])
      if (!this.map) return

      if (route) {
        this.baseline = { duration: route.duration, at: Date.now() }
        this.drawBusRoute(route.path)
      }
    }

    // Entre consultas ao OSRM, o tempo restante desce com o relógio.
    const seconds = this.baseline
      ? this.baseline.duration - (Date.now() - this.baseline.at) / 1000
      : distance / FALLBACK_SPEED_MS
    this.showEta(seconds <= 30 ? "Chegando" : `~${this.format(seconds)}`)
  }

  drawBusRoute(path) {
    this.busRoute?.remove()
    this.busRoute = L.polyline(path, { color: "#dc2626", weight: 4, opacity: 0.7 }).addTo(this.map)
  }

  format(seconds) {
    const minutes = Math.max(1, Math.round(seconds / 60))
    if (minutes < 60) return `${minutes} min`
    return `${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, "0")} min`
  }

  showEta(text) {
    if (this.hasEtaTarget) this.etaTarget.textContent = text
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
