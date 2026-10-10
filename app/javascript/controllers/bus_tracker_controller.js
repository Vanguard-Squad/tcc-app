import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as L from "leaflet"
import { createConsumer } from "@rails/actioncable"
import { drivingRoute, walkingRoute, haversine } from "lib/osrm"
import {
  createMap, addViewControls, addStatusControl, placeMarker, BusMarker, RouteProgress, UserLocation,
  renderProgress, renderSummary, formatDistance, formatDuration, FIT_OPTIONS
} from "lib/route_map"

const COLLEGE_ETA_REFRESH_MS = 15000
const ARRIVED_METERS = 60
const FALLBACK_SPEED_MS = 8 // ~30 km/h, usado só antes da primeira resposta do OSRM

// Mapa do aluno: a rota do ônibus de parada em parada, casa, faculdade, o
// ônibus em tempo real (Action Cable) e, se o aluno quiser, onde ele mesmo
// está. Mostra quanto falta para o ônibus chegar ao ponto do aluno (ou à
// faculdade) e quantas paradas faltam antes dele.
export default class extends Controller {
  static targets = [ "map", "eta", "status", "mine" ]
  static values = {
    vehicleId: Number,
    tripActive: Boolean,
    home: Object,
    stop: Object,
    college: Object,
    target: Object,
    bus: Object,
    walk: Boolean,
    stops: Array,
    myStopId: Number
  }

  async connect() {
    this.map = createMap(this.mapTarget)
    this.mapStatus = addStatusControl(this.map)

    const places = []
    if (this.isPlace(this.homeValue)) places.push(placeMarker(this.map, this.homeValue, "home", "Sua casa").getLatLng())
    if (this.isPlace(this.collegeValue)) places.push(placeMarker(this.map, this.collegeValue, "college", "Faculdade").getLatLng())

    this.route = new RouteProgress(this.map, this.stopsValue, {
      highlightStopId: this.myStopIdValue || null,
      onChange: (info) => this.render(info)
    })
    const bounds = L.latLngBounds(places)
    if (!this.route.empty) bounds.extend(this.route.stopBounds())
    if (this.isPlace(this.busValue)) bounds.extend([ this.busValue.lat, this.busValue.lng ])
    if (bounds.isValid()) this.map.fitBounds(bounds, FIT_OPTIONS)
    else this.map.setView([ -23.55, -46.65 ], 11)

    this.following = false
    this.me = new UserLocation(this.map, { onStatus: (text) => this.mapStatus(text) })
    this.controls = addViewControls(this.map, {
      onFollow: () => this.setFollowing(!this.following),
      onOverview: () => { this.setFollowing(false); this.fitAll() },
      onLocate: () => this.toggleLocation()
    })
    this.controls.setBusAvailable(false)
    this.map.on("dragstart", () => this.setFollowing(false))

    if (this.walkValue && this.isPlace(this.homeValue) && this.isPlace(this.stopValue)) this.drawWalkingRoute()

    if (!this.route.empty) {
      await this.route.draw()
      if (!this.map) return
      renderSummary(this.element, this.route.summary())
    }

    this.bus = new BusMarker(this.map)
    if (this.tripActiveValue && this.isPlace(this.busValue)) this.moveBus(this.busValue)

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TripChannel", vehicle_id: this.vehicleIdValue },
      { received: (data) => this.received(data) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
    this.me?.stop()
    this.route?.remove()
    this.bus?.remove()
    this.map?.remove()
    this.map = null
  }

  received(data) {
    if (data.event === "started" || data.event === "finished") {
      Turbo.visit(window.location.href, { action: "replace" })
    } else if (data.event === "position" && this.tripActiveValue && this.isPlace(data)) {
      this.moveBus(data)
    }
  }

  isPlace(place) {
    return place && place.lat != null && place.lng != null
  }

  async drawWalkingRoute() {
    const route = await walkingRoute([ this.homeValue, this.stopValue ])
    if (!route || !this.map) return

    L.polyline(route.path, { color: "#1e8e5a", weight: 4, dashArray: "2 8", lineCap: "round" }).addTo(this.map)
    this.setStatus(`Caminhada até o ponto: ~${formatDuration(route.duration)} (${formatDistance(route.distance)})`)
  }

  moveBus({ lat, lng, accuracy }) {
    if (!this.map) return

    this.bus.moveTo({ lat, lng, accuracy })
    this.controls.setBusAvailable(true)
    this.lastBus = { lat, lng }

    if (this.route.empty) this.updateCollegeEta(this.lastBus)
    else this.render(this.route.update(this.lastBus))

    if (this.following) this.map.panTo([ lat, lng ], { animate: true })
  }

  render(info) {
    if (!info) return

    renderProgress(this.element, info)
    this.showStopsUntilMine(info)

    const mine = this.targetValue.kind === "stop" && this.myStopIdValue ? this.route.remainingTo(this.myStopIdValue) : null
    if (mine) this.showEta(mine.distance < ARRIVED_METERS ? "Chegando agora" : `~${formatDuration(mine.duration)}`)
    else if (this.lastBus) this.updateCollegeEta(this.lastBus)
  }

  // "Faltam N paradas até o seu ponto", contando a partir da próxima parada.
  showStopsUntilMine(info) {
    if (!this.hasMineTarget || !this.myStopIdValue) return

    const mine = this.route.stops.findIndex((stop) => stop.id === this.myStopIdValue)
    if (mine < 0) return

    const remaining = mine - info.nextIndex
    this.mineTarget.textContent =
      mine < info.nextIndex ? "O ônibus já passou pelo seu ponto."
      : remaining === 0 ? (info.atStop ? "O ônibus está no seu ponto!" : "Seu ponto é a próxima parada.")
      : remaining === 1 ? "Falta 1 parada antes do seu ponto."
      : `Faltam ${remaining} paradas antes do seu ponto.`
  }

  toggleLocation() {
    if (this.me.active) {
      this.me.stop()
      this.mapStatus("")
    } else {
      this.setFollowing(false)
      this.me.start()
    }
    this.controls.setLocating(this.me.active)
  }

  setFollowing(following) {
    this.following = following && Boolean(this.bus?.latLng)
    this.controls.setFollowing(this.following)
    if (this.following) this.map.setView(this.bus.latLng, Math.max(this.map.getZoom(), 16))
  }

  fitAll() {
    const bounds = this.route.empty ? L.latLngBounds([]) : this.route.bounds()
    for (const place of [ this.homeValue, this.collegeValue, this.targetValue ]) {
      if (this.isPlace(place)) bounds.extend([ place.lat, place.lng ])
    }
    if (this.bus?.latLng) bounds.extend(this.bus.latLng)
    if (bounds.isValid()) this.map.fitBounds(bounds, FIT_OPTIONS)
  }

  // A faculdade não é parada da rota: o caminho até ela é calculado à parte,
  // a partir da posição do ônibus.
  async updateCollegeEta(bus) {
    if (this.targetValue.kind !== "college" || !this.isPlace(this.targetValue)) return

    const target = this.targetValue
    const distance = haversine(bus, target)
    if (distance < ARRIVED_METERS) {
      this.showEta("Chegando agora")
      return
    }

    const now = Date.now()
    if (!this.lastEtaAt || now - this.lastEtaAt > COLLEGE_ETA_REFRESH_MS) {
      this.lastEtaAt = now
      const route = await drivingRoute([ bus, target ])
      if (!this.map) return

      if (route) {
        this.baseline = { duration: route.duration, at: Date.now() }
        this.drawCollegeLeg([ [ bus.lat, bus.lng ], ...route.path ])
      }
    }

    // Entre consultas ao OSRM, o tempo restante desce com o relógio.
    const seconds = this.baseline
      ? this.baseline.duration - (Date.now() - this.baseline.at) / 1000
      : distance / FALLBACK_SPEED_MS
    this.showEta(seconds <= 30 ? "Chegando" : `~${formatDuration(seconds)}`)
  }

  drawCollegeLeg(path) {
    this.collegeLeg?.remove()
    this.collegeLeg = L.polyline(path, { color: "#7b4bc4", weight: 5, opacity: 0.85, dashArray: "8 10", lineCap: "round" }).addTo(this.map)
  }

  showEta(text) {
    if (this.hasEtaTarget) this.etaTarget.textContent = text
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
