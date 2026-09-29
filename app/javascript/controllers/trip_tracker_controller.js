import { Controller } from "@hotwired/stimulus"
import { drivingRoute, densify } from "lib/osrm"

const GPS_INTERVAL_MS = 4000
const SIM_INTERVAL_MS = 2000
const SIM_STEP_METERS = 10
const SIM_POINTS_PER_TICK = 3 // ~15 m/s (~54 km/h)

// Envia a posição do ônibus durante uma viagem. A fonte da posição é isolada
// aqui (GPS do navegador ou simulação ao longo da rota) para poder ser
// trocada depois por um componente nativo (Hotwire Native).
export default class extends Controller {
  static targets = [ "status", "stopButton" ]
  static values = { url: String, stops: Array }

  disconnect() {
    this.stop()
  }

  startGps() {
    if (!navigator.geolocation) {
      this.setStatus("Este dispositivo não suporta geolocalização.")
      return
    }

    this.stop()
    this.lastSentAt = 0
    this.watchId = navigator.geolocation.watchPosition(
      ({ coords }) => this.sendThrottled(coords.latitude, coords.longitude),
      (error) => this.setStatus(`Erro de GPS: ${error.message}`),
      { enableHighAccuracy: true, maximumAge: 2000 }
    )
    this.setStatus("Enviando localização pelo GPS…")
  }

  async startSimulation() {
    this.stop()
    this.setStatus("Calculando trajeto da simulação…")

    const road = await drivingRoute(this.stopsValue.filter((stop) => stop.lat && stop.lng))
    if (!road) {
      this.setStatus("Não foi possível calcular o trajeto da simulação.")
      return
    }

    const path = densify(road.path, SIM_STEP_METERS)
    let index = 0

    this.simTimer = setInterval(() => {
      const [ lat, lng ] = path[Math.min(index, path.length - 1)]
      this.send(lat, lng)
      index += SIM_POINTS_PER_TICK

      if (index >= path.length) {
        this.stop()
        this.setStatus("Simulação concluída. Finalize a viagem.")
      }
    }, SIM_INTERVAL_MS)
    this.setStatus("Simulando deslocamento ao longo da rota…")
  }

  stop() {
    if (this.watchId != null) navigator.geolocation.clearWatch(this.watchId)
    if (this.simTimer) clearInterval(this.simTimer)
    this.watchId = null
    this.simTimer = null
  }

  stopSending() {
    this.stop()
    this.setStatus("Envio de localização parado.")
  }

  sendThrottled(lat, lng) {
    const now = Date.now()
    if (now - this.lastSentAt < GPS_INTERVAL_MS) return

    this.lastSentAt = now
    this.send(lat, lng)
  }

  send(lat, lng) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ latitude: lat, longitude: lng })
    })
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
