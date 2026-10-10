import { Controller } from "@hotwired/stimulus"
import { drivingRoute, densify, haversine } from "lib/osrm"
import { geolocationError } from "lib/route_map"

const MIN_INTERVAL_MS = 3000
const MOVED_METERS = 8
const GOOD_ACCURACY_METERS = 50
const ACCEPTABLE_ACCURACY_METERS = 150
const WEAK_SIGNAL_GRACE_MS = 30000
const SIM_INTERVAL_MS = 2000
const SIM_STEP_METERS = 10
const SIM_POINTS_PER_TICK = 3 // ~15 m/s (~54 km/h)

// Envia a posição do ônibus durante uma viagem. A fonte da posição é isolada
// aqui (GPS do aparelho ou simulação ao longo da rota) para poder ser
// trocada depois por um componente nativo (Hotwire Native).
//
// GPS: só envia leituras precisas (até GOOD_ACCURACY_METERS). Leituras de
// Wi-Fi/rede, que erram por centenas de metros, são descartadas; se o sinal
// ficar fraco por muito tempo, aceita até ACCEPTABLE_ACCURACY_METERS para o
// ônibus não "sumir" do mapa.
export default class extends Controller {
  static targets = [ "status" ]
  static values = { url: String, stops: Array }

  disconnect() {
    this.stop()
  }

  startGps() {
    if (!window.isSecureContext || !navigator.geolocation) {
      this.setStatus(`${geolocationError()} Abra o sistema pelo endereço https para usar o GPS do celular.`)
      return
    }

    this.stop()
    this.lastSent = null
    this.startedAt = Date.now()
    this.keepScreenOn()
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.onGps(position.coords),
      (error) => this.setStatus(geolocationError(error)),
      { enableHighAccuracy: true, maximumAge: 0, timeout: 20000 }
    )
    this.setStatus("Procurando sinal de GPS…")
  }

  onGps({ latitude, longitude, accuracy, heading, speed }) {
    const now = Date.now()
    const waitingSince = this.lastSent?.at ?? this.startedAt
    const weakForLong = now - waitingSince > WEAK_SIGNAL_GRACE_MS

    if (accuracy > GOOD_ACCURACY_METERS && !(weakForLong && accuracy <= ACCEPTABLE_ACCURACY_METERS)) {
      this.setStatus(`Sinal de GPS fraco (precisão de ±${Math.round(accuracy)} m). Aguardando um sinal melhor… Em locais fechados o GPS erra mais.`)
      return
    }

    const point = { lat: latitude, lng: longitude }
    const moved = !this.lastSent || haversine(this.lastSent.point, point) >= MOVED_METERS
    const due = !this.lastSent || now - this.lastSent.at >= MIN_INTERVAL_MS
    if (!due || (!moved && now - this.lastSent.at < MIN_INTERVAL_MS * 5)) return

    this.lastSent = { point, at: now }
    this.send(latitude, longitude, { accuracy, heading, speed })

    const time = new Date(now).toLocaleTimeString("pt-BR")
    const speedText = speed != null && speed > 0.5 ? `, ${Math.round(speed * 3.6)} km/h` : ""
    this.setStatus(`GPS ativo: precisão de ±${Math.round(accuracy)} m${speedText}. Última posição enviada às ${time}.`)
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
      this.send(lat, lng, { accuracy: 5 })
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
    this.wakeLock?.release().catch(() => {})
    this.wakeLock = null
  }

  stopSending() {
    this.stop()
    this.setStatus("Envio de localização pausado.")
  }

  // Com a tela apagada o navegador para de entregar o GPS: mantém acesa
  // enquanto a posição está sendo enviada (quando o aparelho permite).
  async keepScreenOn() {
    try {
      this.wakeLock = await navigator.wakeLock?.request("screen")
    } catch {
      this.wakeLock = null
    }
  }

  send(lat, lng, { accuracy, heading, speed } = {}) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ latitude: lat, longitude: lng, accuracy, heading, speed })
    }).then((response) => {
      if (!response.ok) this.setStatus("O servidor recusou a posição. A viagem ainda está ativa?")
    }).catch(() => this.setStatus("Sem conexão com o servidor. Tentando de novo na próxima leitura…"))
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
