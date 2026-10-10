import * as L from "leaflet"
import { drivingRoute, haversine, densify } from "lib/osrm"

const TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
const ATTRIBUTION = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'

export const FIT_OPTIONS = { padding: [ 48, 48 ], maxZoom: 16 }

const AT_STOP_METERS = 60
const LEAVE_STOP_METERS = 120
const OFF_ROUTE_METERS = 150
const PATH_STEP_METERS = 25
const LEG_STEP_METERS = 15
const LEG_REFRESH_MS = 20000
const LEG_DEVIATION_METERS = 60
const TRAIL_LIMIT = 2000
const TRAIL_JUMP_METERS = 1000
const SHOW_ACCURACY_METERS = 15
const SEARCH_BACK = 20
const SEARCH_AHEAD = 400
const FALLBACK_PACE = 1 / 8 // s/m (~30 km/h), quando o OSRM não responde
const BUS_ANIMATION_MS = 1000

const ICONS = {
  bus: '<path d="M4 16c0 .88.39 1.67 1 2.22V20a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-1h8v1a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4S4 2.5 4 6v10zm3.5 1a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm9 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zM18 11H6V6h12v5z"/>',
  home: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
  college: '<path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3 1 9l11 6 9-4.91V17h2V9L12 3z"/>',
  locate: '<path d="M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm8.94 3A8.994 8.994 0 0 0 13 3.06V1h-2v2.06A8.994 8.994 0 0 0 3.06 11H1v2h2.06A8.994 8.994 0 0 0 11 20.94V23h2v-2.06A8.994 8.994 0 0 0 20.94 13H23v-2h-2.06zM12 19c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7z"/>'
}

const svg = (name) => `<svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[name]}</svg>`

// Mapa base (OpenStreetMap, com as cores atenuadas via CSS para a rota se
// destacar), zoom no canto e escala.
export function createMap(element) {
  const map = L.map(element, { zoomControl: false })
  L.control.zoom({ position: "bottomright" }).addTo(map)
  L.control.scale({ imperial: false, position: "bottomleft" }).addTo(map)
  L.tileLayer(TILE_URL, { attribution: ATTRIBUTION, maxZoom: 19, className: "map-tiles" }).addTo(map)
  return map
}

export function placeMarker(map, place, kind, label) {
  return L.marker([ place.lat, place.lng ], {
    icon: L.divIcon({ className: "", html: `<div class="map-place map-place-${kind}">${svg(kind)}</div>`, iconSize: [ 32, 32 ], iconAnchor: [ 16, 16 ] }),
    keyboard: false
  }).addTo(map).bindTooltip(label, { direction: "top", offset: [ 0, -16 ] })
}

// Botões "seguir ônibus" e "ver rota inteira" no canto do mapa.
export function addViewControls(map, { onFollow, onOverview, onLocate }) {
  const control = L.control({ position: "topright" })
  control.onAdd = () => {
    const container = L.DomUtil.create("div", "map-view-controls")
    container.innerHTML = `
      <button type="button" data-view="follow" title="Seguir o ônibus">${svg("bus")}<span>Seguir ônibus</span></button>
      <button type="button" data-view="overview" title="Ver a rota inteira"><span>Rota inteira</span></button>
      <button type="button" data-view="locate" title="Mostrar onde você está">${svg("locate")}<span>Minha localização</span></button>`
    L.DomEvent.disableClickPropagation(container)
    container.querySelector("[data-view=follow]").addEventListener("click", onFollow)
    container.querySelector("[data-view=overview]").addEventListener("click", onOverview)
    const locate = container.querySelector("[data-view=locate]")
    if (onLocate) locate.addEventListener("click", onLocate)
    else locate.remove()
    return container
  }
  control.addTo(map)
  return {
    setFollowing(active) {
      control.getContainer()?.querySelector("[data-view=follow]")?.classList.toggle("is-active", active)
    },
    setBusAvailable(available) {
      control.getContainer()?.querySelector("[data-view=follow]")?.toggleAttribute("hidden", !available)
    },
    setLocating(active) {
      control.getContainer()?.querySelector("[data-view=locate]")?.classList.toggle("is-active", active)
    }
  }
}

// Aviso curto sobre o mapa (localização, GPS); some sozinho depois de um tempo.
export function addStatusControl(map) {
  const control = L.control({ position: "bottomleft" })
  control.onAdd = () => L.DomUtil.create("div", "map-status")
  control.addTo(map)
  let timer

  return (text, { sticky = false } = {}) => {
    const element = control.getContainer()
    if (!element) return

    clearTimeout(timer)
    element.textContent = text || ""
    element.hidden = !text
    if (text && !sticky) timer = setTimeout(() => { element.hidden = true }, 6000)
  }
}

function bearing(from, to) {
  const rad = (degrees) => (degrees * Math.PI) / 180
  const y = Math.sin(rad(to.lng - from.lng)) * Math.cos(rad(to.lat))
  const x = Math.cos(rad(from.lat)) * Math.sin(rad(to.lat)) -
    Math.sin(rad(from.lat)) * Math.cos(rad(to.lat)) * Math.cos(rad(to.lng - from.lng))
  return (Math.atan2(y, x) * 180) / Math.PI
}

// Marcador do ônibus: desliza suavemente entre as posições recebidas e
// mostra uma seta para onde ele está indo.
export class BusMarker {
  constructor(map, { label = "Ônibus", permanent = false } = {}) {
    this.map = map
    this.label = label
    this.permanent = permanent
  }

  get latLng() {
    return this.marker?.getLatLng()
  }

  moveTo({ lat, lng, accuracy }) {
    const target = L.latLng(lat, lng)
    this.showAccuracy(target, accuracy)

    if (!this.marker) {
      const html = `<div class="map-bus"><div class="map-bus-heading" hidden></div><div class="map-bus-body">${svg("bus")}</div></div>`
      this.marker = L.marker(target, {
        icon: L.divIcon({ className: "", html, iconSize: [ 44, 44 ], iconAnchor: [ 22, 22 ] }),
        zIndexOffset: 1000,
        keyboard: false
      }).addTo(this.map).bindTooltip(this.label, { direction: "top", offset: [ 0, -22 ], permanent: this.permanent, className: this.permanent ? "map-bus-label" : "" })
      return
    }

    const from = this.marker.getLatLng()
    if (from.distanceTo(target) > 3) this.pointTo(bearing(from, target))
    this.slide(from, target)
  }

  // Círculo com o raio de incerteza do GPS, quando ele não é desprezível.
  showAccuracy(latLng, accuracy) {
    if (!(accuracy > SHOW_ACCURACY_METERS)) {
      this.accuracyCircle?.remove()
      this.accuracyCircle = null
      return
    }

    if (this.accuracyCircle) {
      this.accuracyCircle.setLatLng(latLng).setRadius(accuracy)
    } else {
      this.accuracyCircle = L.circle(latLng, {
        radius: accuracy, color: "#22313b", weight: 1, opacity: 0.4, fillColor: "#22313b", fillOpacity: 0.08, interactive: false
      }).addTo(this.map)
    }
  }

  pointTo(degrees) {
    const arrow = this.marker.getElement()?.querySelector(".map-bus-heading")
    if (!arrow) return

    arrow.hidden = false
    arrow.style.transform = `rotate(${degrees}deg)`
  }

  slide(from, to) {
    cancelAnimationFrame(this.frame)
    const start = performance.now()

    const step = (now) => {
      const t = Math.min(1, (now - start) / BUS_ANIMATION_MS)
      const eased = t * (2 - t)
      this.marker.setLatLng([ from.lat + (to.lat - from.lat) * eased, from.lng + (to.lng - from.lng) * eased ])
      if (t < 1) this.frame = requestAnimationFrame(step)
    }
    this.frame = requestAnimationFrame(step)
  }

  remove() {
    cancelAnimationFrame(this.frame)
    this.marker?.remove()
    this.accuracyCircle?.remove()
  }
}

export function geolocationError(error) {
  if (!window.isSecureContext) return "O navegador só libera a localização em conexão segura (https) ou em localhost."

  return {
    1: "A permissão de localização foi negada. Libere nas configurações do navegador.",
    2: "Não foi possível obter a localização. Ative o GPS do aparelho.",
    3: "O GPS demorou para responder. Tente de novo em um lugar mais aberto."
  }[error?.code] || "Não foi possível obter a localização."
}

// "Você está aqui": ponto azul com o raio de precisão, a partir do GPS do
// próprio aparelho de quem está olhando o mapa.
export class UserLocation {
  constructor(map, { onStatus = () => {} } = {}) {
    this.map = map
    this.onStatus = onStatus
  }

  get active() {
    return this.watchId != null
  }

  start() {
    if (!window.isSecureContext || !navigator.geolocation) {
      this.onStatus(geolocationError())
      return false
    }

    this.centered = false
    this.onStatus("Procurando sua localização…")
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.show(position.coords),
      (error) => this.onStatus(geolocationError(error)),
      { enableHighAccuracy: true, maximumAge: 0, timeout: 20000 }
    )
    return true
  }

  stop() {
    if (this.watchId != null) navigator.geolocation.clearWatch(this.watchId)
    this.watchId = null
    this.dot?.remove()
    this.circle?.remove()
    this.dot = this.circle = null
  }

  show({ latitude, longitude, accuracy }) {
    if (!this.map) return

    const latLng = L.latLng(latitude, longitude)
    if (this.dot) {
      this.dot.setLatLng(latLng)
      this.circle.setLatLng(latLng).setRadius(accuracy)
    } else {
      this.circle = L.circle(latLng, {
        radius: accuracy, color: "#1a73e8", weight: 1, opacity: 0.5, fillColor: "#1a73e8", fillOpacity: 0.12, interactive: false
      }).addTo(this.map)
      this.dot = L.circleMarker(latLng, {
        radius: 8, color: "#ffffff", weight: 3, fillColor: "#1a73e8", fillOpacity: 1
      }).addTo(this.map).bindTooltip("Você está aqui", { direction: "top", offset: [ 0, -8 ] })
    }

    if (!this.centered) {
      this.centered = true
      this.map.setView(latLng, Math.max(this.map.getZoom(), 17))
    }
    this.onStatus(`Você está aqui (precisão de ±${Math.round(accuracy)} m).`)
  }
}

// Rota de parada em parada, seguindo as ruas (OSRM). Conforme o ônibus anda:
//  - o caminho que ele de fato fez fica cinza;
//  - o trecho até a próxima parada é calculado pelas ruas a partir da posição
//    real do ônibus (amarelo), e recalculado se ele desviar;
//  - o resto da rota planejada, da próxima parada em diante, fica azul;
//  - cada parada é marcada como concluída, atual ou futura.
// `onChange` recebe o novo estado quando algo muda sem uma posição nova
// (por exemplo, quando o trecho recalculado chega do OSRM).
export class RouteProgress {
  constructor(map, stops, { highlightStopId = null, onChange = null } = {}) {
    this.map = map
    this.stops = stops.filter((stop) => stop.lat != null && stop.lng != null)
    this.highlightStopId = highlightStopId
    this.onChange = onChange
    this.states = []
    this.doneAt = {}
    this.reached = -1
    this.arrivedAt = null
    this.lastIndex = 0
    this.trail = []
  }

  get empty() {
    return this.stops.length === 0
  }

  stopBounds() {
    return L.latLngBounds(this.stops.map((stop) => [ stop.lat, stop.lng ]))
  }

  bounds() {
    return this.path ? L.latLngBounds(this.path) : this.stopBounds()
  }

  async draw() {
    this.markers = this.stops.map((stop) =>
      L.marker([ stop.lat, stop.lng ], { icon: this.stopIcon(stop, "upcoming"), keyboard: false })
        .addTo(this.map)
        .bindTooltip(`<strong>Parada ${stop.step}</strong><br>${stop.label}`, { direction: "top", offset: [ 0, -14 ] })
        .on("click", () => this.map.setView([ stop.lat, stop.lng ], Math.max(this.map.getZoom(), 16)))
    )
    this.markers.forEach((_marker, index) => { this.states[index] = "upcoming" })

    const road = this.stops.length > 1 ? await drivingRoute(this.stops) : null
    this.road = road
    this.path = densify(road ? road.path : this.stops.map((stop) => [ stop.lat, stop.lng ]), PATH_STEP_METERS)
    this.measure()

    const line = { lineCap: "round", lineJoin: "round", interactive: false }
    this.layers = [
      this.casingLine = L.polyline(this.path, { ...line, color: "#ffffff", weight: 10, opacity: 0.95 }),
      this.traveledLine = L.polyline([], { ...line, color: "#8a98a3", weight: 6 }),
      this.remainingLine = L.polyline(this.path, { ...line, color: "#1f5fbf", weight: 6 }),
      this.activeLine = L.polyline([], { ...line, color: "#f2b705", weight: 4, lineCap: "butt", className: "map-route-active" })
    ]
    this.layers.forEach((layer) => layer.addTo(this.map))
  }

  remove() {
    this.removed = true
    this.layers?.forEach((layer) => layer.remove())
    this.markers?.forEach((marker) => marker.remove())
  }

  // Distância e tempo total do percurso, de acordo com o OSRM.
  summary() {
    return { stops: this.stops.length, distance: this.total, duration: this.road?.duration ?? this.total * FALLBACK_PACE }
  }

  measure() {
    this.cumulative = cumulate(this.path)
    this.total = this.cumulative[this.cumulative.length - 1]

    // Índice do trajeto mais próximo de cada parada, sempre avançando para
    // não confundir paradas em ruas que se cruzam.
    let from = 0
    this.stopIndex = this.stops.map((stop) => {
      const index = this.nearest(stop, from, this.path.length).index
      from = index
      return index
    })

    this.legPace = this.stops.slice(0, -1).map((_stop, i) => {
      const distance = this.cumulative[this.stopIndex[i + 1]] - this.cumulative[this.stopIndex[i]]
      const duration = this.road?.legs?.[i]?.duration
      return duration && distance > 0 ? duration / distance : this.averagePace()
    })
  }

  averagePace() {
    return this.road?.distance ? this.road.duration / this.road.distance : FALLBACK_PACE
  }

  nearest(point, from, to) {
    let best = { index: from, distance: Infinity }
    for (let i = from; i < to; i++) {
      const distance = haversine(point, toPoint(this.path[i]))
      if (distance < best.distance) best = { index: i, distance }
    }
    return best
  }

  // Posição do ônibus no trajeto: procura perto da última posição conhecida
  // e só varre o trajeto inteiro se ele parecer ter saído da rota.
  project(bus) {
    let best = this.nearest(bus, Math.max(0, this.lastIndex - SEARCH_BACK), Math.min(this.path.length, this.lastIndex + SEARCH_AHEAD))
    if (best.distance > OFF_ROUTE_METERS) best = this.nearest(bus, 0, this.path.length)
    this.lastIndex = best.index
    return best
  }

  update(bus) {
    if (!this.path || this.removed) return null

    this.lastBus = bus
    const { index, distance: offset } = this.project(bus)
    const offRoute = offset > OFF_ROUTE_METERS
    this.advanceStops(bus, index, offRoute)
    this.extendTrail(bus)

    const nextIndex = this.reached + 1
    const finished = nextIndex >= this.stops.length
    const nextStop = this.stops[nextIndex]
    const atStop = !finished && haversine(bus, nextStop) < AT_STOP_METERS
    const states = this.stops.map((_stop, i) => {
      if (i <= this.reached) return "done"
      if (i === nextIndex) return atStop ? "current" : "next"
      return "upcoming"
    })
    this.applyStates(states)

    const leg = finished ? { path: [], distance: 0, duration: 0 } : this.legTo(bus, nextIndex, index, offRoute)
    this.traveledLine.setLatLngs(this.trail)
    const remaining = finished ? [] : this.path.slice(this.stopIndex[nextIndex])
    this.casingLine.setLatLngs(remaining)
    this.remainingLine.setLatLngs(remaining)
    this.activeLine.setLatLngs(leg.path)
    if (!finished) this.refreshLeg(bus, nextIndex)

    const plannedAhead = finished ? this.total : this.cumulative[this.stopIndex[nextIndex]] - leg.distance

    this.info = {
      finished,
      offRoute,
      nextStop,
      nextIndex,
      atStop,
      distanceToNext: leg.distance,
      etaToNext: leg.duration,
      fraction: this.total > 0 ? Math.min(1, Math.max(0, plannedAhead / this.total)) : 0,
      doneCount: this.reached + 1,
      total: this.stops.length,
      stateById: Object.fromEntries(this.stops.map((stop, i) => [ String(stop.id), states[i] ])),
      doneAt: this.doneAt
    }
    return this.info
  }

  // Quanto falta até uma parada específica (ex.: a do aluno): o trecho ao vivo
  // até a próxima parada mais os trechos planejados depois dela.
  remainingTo(stopId) {
    const target = this.stops.findIndex((stop) => String(stop.id) === String(stopId))
    if (!this.info || target < 0 || target < this.info.nextIndex) return null

    let { distanceToNext: distance, etaToNext: duration } = this.info
    for (let i = this.info.nextIndex; i < target; i++) {
      const legDistance = this.cumulative[this.stopIndex[i + 1]] - this.cumulative[this.stopIndex[i]]
      distance += legDistance
      duration += legDistance * this.legPace[i]
    }
    return { distance, duration, stops: target - this.info.nextIndex }
  }

  // Uma parada é atendida quando o ônibus chega nela e depois se afasta, ou
  // quando passa por ela seguindo o trajeto. Chegar numa parada mais à frente
  // conta as anteriores como atendidas. Nunca volta atrás.
  advanceStops(bus, index, offRoute) {
    for (let i = this.reached + 1; i < this.stops.length; i++) {
      if (haversine(bus, this.stops[i]) < AT_STOP_METERS) {
        this.reached = Math.max(this.reached, i - 1)
        this.arrivedAt = i
        break
      }
    }

    if (this.arrivedAt != null && this.arrivedAt > this.reached &&
        haversine(bus, this.stops[this.arrivedAt]) > LEAVE_STOP_METERS) {
      this.reached = this.arrivedAt
      this.arrivedAt = null
    }

    if (!offRoute) {
      const traveled = this.cumulative[index]
      this.stopIndex.forEach((pathIndex, i) => {
        const away = haversine(bus, this.stops[i]) > AT_STOP_METERS
        if (away && traveled > this.cumulative[pathIndex] + AT_STOP_METERS) this.reached = Math.max(this.reached, i)
      })
    }
  }

  // Caminho que o ônibus de fato fez. Ao abrir a tela no meio da viagem,
  // começa pela rota planejada até a última parada atendida. Um salto grande
  // entre duas posições (GPS ruim, posição antiga) recomeça o rastro em vez
  // de ligar os dois pontos com uma reta.
  extendTrail(bus) {
    let last = this.trail[this.trail.length - 1]
    if (last && haversine(toPoint(last), bus) > TRAIL_JUMP_METERS) {
      this.trail = []
      last = null
    }

    if (this.trail.length === 0 && this.reached >= 0) {
      this.trail = this.path.slice(0, this.stopIndex[this.reached] + 1)
      last = this.trail[this.trail.length - 1]
    }

    if (!last || haversine(toPoint(last), bus) > 3) this.trail.push([ bus.lat, bus.lng ])
    if (this.trail.length > TRAIL_LIMIT) this.trail.splice(0, this.trail.length - TRAIL_LIMIT)
  }

  // Trecho do ônibus até a próxima parada. Usa a rota calculada a partir da
  // posição dele (cortada no ponto em que ele está); enquanto ela não chega,
  // usa a rota planejada se ele estiver nela, ou uma linha reta.
  legTo(bus, nextIndex, index, offRoute) {
    const live = this.liveLeg(bus, nextIndex)
    if (live) return live

    const stop = this.stops[nextIndex]
    const stopPathIndex = this.stopIndex[nextIndex]
    if (!offRoute && index <= stopPathIndex) {
      const distance = this.cumulative[stopPathIndex] - this.cumulative[index]
      const pace = (nextIndex > 0 && this.legPace[nextIndex - 1]) || this.averagePace()
      return { path: [ [ bus.lat, bus.lng ], ...this.path.slice(index + 1, stopPathIndex + 1) ], distance, duration: distance * pace }
    }

    const distance = haversine(bus, stop)
    return { path: [ [ bus.lat, bus.lng ], [ stop.lat, stop.lng ] ], distance, duration: distance * this.averagePace() }
  }

  liveLeg(bus, nextIndex) {
    const leg = this.leg
    if (!leg || leg.stopIndex !== nextIndex) return null

    const { index, distance } = nearestOnPath(leg.path, bus)
    if (distance > LEG_DEVIATION_METERS) return null

    const remaining = leg.cumulative[leg.cumulative.length - 1] - leg.cumulative[index]
    return {
      path: [ [ bus.lat, bus.lng ], ...leg.path.slice(index + 1) ],
      distance: remaining,
      duration: leg.duration * (remaining / Math.max(1, leg.distance))
    }
  }

  // Recalcula o trecho até a próxima parada quando ela muda, quando o ônibus
  // sai do trecho calculado ou a cada LEG_REFRESH_MS (trânsito, desvios).
  refreshLeg(bus, nextIndex) {
    if (this.legLoading) return

    const stale = !this.leg || this.leg.stopIndex !== nextIndex ||
      Date.now() - this.leg.at > LEG_REFRESH_MS || !this.liveLeg(bus, nextIndex)
    if (!stale) return

    this.legLoading = true
    drivingRoute([ bus, this.stops[nextIndex] ]).then((route) => {
      this.legLoading = false
      if (!route || this.removed) return

      const path = densify([ [ bus.lat, bus.lng ], ...route.path ], LEG_STEP_METERS)
      this.leg = { stopIndex: nextIndex, path, cumulative: cumulate(path), distance: route.distance, duration: route.duration, at: Date.now() }
      if (this.lastBus && this.reached + 1 === nextIndex) this.onChange?.(this.update(this.lastBus))
    })
  }

  applyStates(states) {
    states.forEach((state, i) => {
      if (this.states[i] === state) return

      if (state === "done") this.doneAt[this.stops[i].id] = new Date()
      this.states[i] = state
      this.markers[i].setIcon(this.stopIcon(this.stops[i], state))
      this.markers[i].setZIndexOffset(state === "next" || state === "current" ? 500 : 0)
    })
  }

  stopIcon(stop, state) {
    const highlight = String(stop.id) === String(this.highlightStopId) ? " map-stop-highlight" : ""
    const label = state === "done" ? "✓" : stop.step
    return L.divIcon({
      className: "",
      html: `<div class="map-stop map-stop-${state}${highlight}">${label}</div>`,
      iconSize: [ 30, 30 ],
      iconAnchor: [ 15, 15 ]
    })
  }
}

const toPoint = ([ lat, lng ]) => ({ lat, lng })

function cumulate(path) {
  const cumulative = [ 0 ]
  for (let i = 1; i < path.length; i++) {
    cumulative[i] = cumulative[i - 1] + haversine(toPoint(path[i - 1]), toPoint(path[i]))
  }
  return cumulative
}

function nearestOnPath(path, point) {
  let best = { index: 0, distance: Infinity }
  path.forEach((vertex, index) => {
    const distance = haversine(point, toPoint(vertex))
    if (distance < best.distance) best = { index, distance }
  })
  return best
}

export function formatDistance(meters) {
  if (meters < 1000) return `${Math.max(10, Math.round(meters / 10) * 10)} m`
  return `${(meters / 1000).toLocaleString("pt-BR", { maximumFractionDigits: 1 })} km`
}

export function formatDuration(seconds) {
  const minutes = Math.max(1, Math.round(seconds / 60))
  if (minutes < 60) return `${minutes} min`
  return `${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, "0")} min`
}

const formatTime = (date) => date.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })

// Atualiza o painel lateral (próxima parada, barra de progresso e linha do
// tempo) a partir do resultado de RouteProgress#update.
export function renderProgress(root, info) {
  const set = (name, text) => root.querySelectorAll(`[data-progress="${name}"]`).forEach((el) => { el.textContent = text })

  if (info.finished) {
    set("next-label", "Percurso concluído")
    set("next-meta", "Todas as paradas foram atendidas.")
  } else {
    set("next-label", `${info.nextStop.step}. ${info.nextStop.label}`)
    set("next-meta", info.atStop ? "Ônibus na parada agora"
      : `${formatDistance(info.distanceToNext)} · ~${formatDuration(info.etaToNext)}${info.offRoute ? " · fora do trajeto" : ""}`)
  }
  set("summary", `${info.doneCount} de ${info.total} paradas concluídas`)
  root.querySelectorAll('[data-progress="bar"]').forEach((bar) => { bar.style.width = `${Math.round(info.fraction * 100)}%` })

  root.querySelectorAll("[data-stop-id]").forEach((item) => {
    const state = info.stateById[item.dataset.stopId]
    if (!state) return

    item.classList.remove("is-done", "is-current", "is-next", "is-upcoming")
    item.classList.add(`is-${state}`)

    const meta = item.querySelector("[data-timeline-meta]")
    if (!meta) return

    const doneAt = info.doneAt[item.dataset.stopId]
    meta.textContent = {
      done: doneAt ? `Concluída às ${formatTime(doneAt)}` : "Concluída",
      current: "Ônibus na parada",
      next: `Próxima · ${formatDistance(info.distanceToNext)} · ~${formatDuration(info.etaToNext)}`,
      upcoming: ""
    }[state]
  })
}

export function renderSummary(root, summary) {
  root.querySelectorAll('[data-progress="route-summary"]').forEach((el) => {
    el.textContent = `${summary.stops} paradas · ${formatDistance(summary.distance)} · ~${formatDuration(summary.duration)}`
  })
}
