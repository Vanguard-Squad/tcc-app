import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { createConsumer } from "@rails/actioncable"
import {
  createMap, addViewControls, addStatusControl, BusMarker, RouteProgress, UserLocation,
  renderProgress, renderSummary, FIT_OPTIONS
} from "lib/route_map"

// Mapa da rota do motorista: paradas numeradas em ordem, trajeto pelas ruas
// e, com viagem em andamento, o ônibus em tempo real (Action Cable) com o
// trecho até a próxima parada calculado a partir da posição real dele.
export default class extends Controller {
  static targets = [ "map" ]
  static values = { stops: Array, vehicleId: Number, tripActive: Boolean, bus: Object }

  async connect() {
    const stops = this.stopsValue.filter((stop) => stop.lat != null && stop.lng != null)
    if (stops.length === 0) {
      this.mapTarget.innerHTML = '<p class="map-empty">Nenhuma parada com localização disponível ainda.</p>'
      return
    }

    this.map = createMap(this.mapTarget)
    this.status = addStatusControl(this.map)
    this.route = new RouteProgress(this.map, stops, { onChange: (info) => this.render(info) })
    this.map.fitBounds(this.route.stopBounds(), FIT_OPTIONS)

    this.following = false
    this.me = new UserLocation(this.map, { onStatus: (text) => this.status(text) })
    this.controls = addViewControls(this.map, {
      onFollow: () => this.setFollowing(!this.following),
      onOverview: () => { this.setFollowing(false); this.map.fitBounds(this.route.bounds(), FIT_OPTIONS) },
      onLocate: () => this.toggleLocation()
    })
    this.controls.setBusAvailable(false)
    this.map.on("dragstart", () => this.setFollowing(false))

    await this.route.draw()
    if (!this.map) return

    this.map.fitBounds(this.route.bounds(), FIT_OPTIONS)
    renderSummary(this.element, this.route.summary())

    if (!this.tripActiveValue) return

    this.bus = new BusMarker(this.map)
    if (this.busValue.lat != null) this.onPosition(this.busValue)
    this.subscribe()
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
    this.me?.stop()
    this.route?.remove?.()
    this.bus?.remove()
    this.map?.remove()
    this.map = null
  }

  subscribe() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TripChannel", vehicle_id: this.vehicleIdValue },
      { received: (data) => this.received(data) }
    )
  }

  received(data) {
    if (data.event === "position" && data.lat != null) {
      this.onPosition(data)
    } else if (data.event === "started" || data.event === "finished") {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }

  onPosition({ lat, lng, accuracy }) {
    if (!this.map) return

    this.bus.moveTo({ lat, lng, accuracy })
    this.controls.setBusAvailable(true)
    this.render(this.route.update({ lat, lng }))

    if (this.following) this.map.panTo([ lat, lng ], { animate: true })
  }

  render(info) {
    if (info) renderProgress(this.element, info)
  }

  toggleLocation() {
    if (this.me.active) {
      this.me.stop()
      this.status("")
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
}
